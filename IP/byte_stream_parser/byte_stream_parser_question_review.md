# 字节流帧解析器：题目还原与复盘

> 根据本次对话中保留的文字和截图还原，不是原题逐字转录。下文区分最终澄清的要求与为形成完整题面而补充的假设。本文以还原题目为主，不附完整参考答案。

## 1. 这道题究竟在考什么

设计一个可综合的 Verilog/SystemVerilog 字节流接收模块：从连续的 8-bit 输入中识别三个相邻的 SOP 字节，接收固定长度的 payload，再读取尾部校验字节，判断 payload 是否有效，并输出数据及完成/有效指示。

最关键的澄清是：**三个 SOP 是同一帧开头的三个连续字节，不是连续三帧各出现一个 SOP。**

最初回答把它理解成在第 0、16、32 字节位置寻找三个帧头，这是当时的解释，并非最终题意。最终题意不需要用 32-bit 匹配历史来确认三个相隔 16 字节的帧头。

## 2. 最终格式与证据边界

对话中先出现：

```text
SOP | SOP | SOP | PAYLOAD | CRC (8 bits)
```

后续截图中的注释改成：

```text
SOP | SOP | SOP | PAYLOAD | parity (16 bits -> 1 parity) (8 bits)
```

因此，最终复盘应优先按 **parity 校验版**整理，同时保留“最初称为 CRC”这一差异。CRC-8 和 8-bit parity 字段不是同一种算法。

| 要求 | 还原结果 | 确定程度 |
| --- | --- | --- |
| 输入宽度 | 8 bit，按字节接收 | 已明确 |
| SOP 值 | 示例为 `8'hEF`，通过 `input [7:0] pattern` 提供 | 已明确 |
| SOP 数量 | 帧头是三个相邻、值相同的 SOP 字节 | 后续明确 |
| 帧内容 | 三个 SOP、payload、尾部校验字段 | 已明确 |
| 尾部字段长度 | 8 bit，即一个字节 | 已明确 |
| 最后出现的校验规则 | 每 16 bit payload 生成一个 parity bit | 截图注明 |
| payload 长度 | 复盘版本取 16 字节 | 与 16 元素字节数组、8 个 parity bit 一致；原始措辞有歧义 |
| 输入时序 | 每个时钟接收一个有效字节 | 原接口没有输入 valid，因此作为实现假设 |
| parity 类型 | 偶校验 | 原题未明确；上一版参考实现采用的假设 |
| parity bit 对应顺序 | bit 0 对应前两个 payload 字节，依次类推 | 原题未明确；上一版参考实现采用的假设 |
| 输出指示 | 截图曾加入 `out_ready` | 出现过该端口，但完整时序定义未明确 |

### 关于“16 字节”的歧义

最初文字为 “frames of 16 Byte”，可能指整帧长度；但后面出现了 `logic [7:0] out [16]`，以及“每 16 bit 对应一个 parity bit、共 8 bit”的注释。若这 8 个 parity bit 全部用于 payload，则对应的 payload 是 128 bit，也就是 16 字节。

因此，本文的可练习题面采用 **16 字节 payload**：

| 字节偏移 | 内容 |
| --- | --- |
| 0–2 | 三个 SOP 字节 |
| 3–18 | 16 字节 payload |
| 19 | 1 字节 parity |

在此假设下，整帧为 **20 字节**。不能把“整帧 20 字节”写成已经确认的原题原话；若 16 字节原本指整帧，则扣除 3 字节 SOP 和 1 字节校验后，payload 只有 12 字节，必须进一步确认校验字段如何映射。

## 3. 可直接重新练习的题面

### 中文版

请使用可综合的 SystemVerilog 设计一个字节流帧解析模块。

输入 `in` 为 8-bit 字节流，假设每个时钟上升沿都有一个有效字节。输入 `pattern` 指定 SOP 字节，典型值为 `8'hEF`，在接收过程中保持不变。

每帧按以下顺序组成：

1. 三个连续的 SOP 字节，其值都等于 `pattern`。
2. 16 字节 payload。
3. 一个 8-bit parity 字节。

该练习版本采用偶校验：每两个连续 payload 字节组成一个 16-bit 数据组，计算这 16 个数据位的归约 XOR，作为该组的 parity bit。共八组，组成一个 parity 字节。bit 0 对应 payload 字节 0、1，bit 7 对应字节 14、15。

模块应完成以下行为：

- 搜索三个相邻的 SOP；搜索期间遇到不匹配字节，则清零连续匹配计数。
- 接收第三个 SOP 后，从下一个时钟开始保存 payload；三个 SOP 不属于 payload。
- 收集全部 16 字节，按接收顺序保存，并在接收过程中累计 parity。
- 将紧随 payload 的字节解释为收到的 parity，不将它保存为 payload。
- 比较计算结果与收到的 parity；本练习约定校验成功后输出一个时钟周期的 `out_ready` 脉冲。
- 校验失败时不产生 `out_ready`，并返回搜索帧头状态；错误输出可作为扩展接口。
- 完成当前帧处理后，支持紧接着接收下一帧，不要求帧间存在空闲周期。
- payload 中允许出现与 `pattern` 相同的值，接收 payload 时不重新触发帧头检测。
- 复位后清除接收状态、计数器和有效指示。本练习取高有效复位。

若 payload 输出直接用作接收数组，则它可以在接收过程中更新，下游仅在 `out_ready` 有效时读取完整结果。若要求输出保持上一帧有效数据直到下一帧校验通过，应额外使用接收缓冲区；这属于输出时序的扩展约定。

### English reconstruction

Design a synthesizable SystemVerilog byte-stream frame parser. Assume one valid 8-bit input byte per clock. Each frame consists of three consecutive SOP bytes, a 16-byte payload, and one 8-bit parity byte. The SOP value is supplied through an 8-bit `pattern` input and remains stable during reception.

For this reconstructed exercise, use even parity: each consecutive pair of payload bytes contributes one parity bit, with bit 0 covering payload bytes 0 and 1. Detect the three-byte header, capture the payload, verify the received parity byte, and pulse `out_ready` for one clock only when the payload passes verification. Return to header search after either result and support back-to-back frames. SOP-valued bytes inside the payload must be treated as ordinary data.

The 16-byte payload length, parity convention, parity-bit ordering, and exact output timing are explicit assumptions used to make this exercise fully specified.

## 4. 建议接口

下面是复盘练习用的接口，不是截图接口的逐字抄录：

```systemverilog
module bfs (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] in,
    input  logic [7:0] pattern,

    output logic [7:0] out [0:15],
    output logic       out_ready
);
    // Implement header detection, payload capture, and parity checking.
endmodule
```

`out [0:15]` 是 16 个 8-bit 元素，总容量为 128 bit。`out_ready` 在这里表示“有效结果已就绪”的脉冲，不是下游反压信号。

## 5. 解题结构与易错点

建议分成三个状态：

| 状态 | 当前输入的含义 | 完成条件 |
| --- | --- | --- |
| `WAIT_SOP` | 搜索连续 SOP | 接收到第三个 SOP |
| `CAPTURE` | 保存 payload，并累计 parity | 接收到第 16 个 payload 字节 |
| `CHECK_PARITY` | 接收尾部校验字节并比较 | 比较后返回 `WAIT_SOP` |

重点复盘：

1. **第三个 SOP 到来时，旧计数值是 2。** 使用非阻塞赋值时，当前时钟里的条件判断读取更新前的值，因此 `sop_count == 2 && in == pattern` 可以表示收到了第三个相邻 SOP。
2. **这次第三个 SOP 不要写入 payload。** 下一拍才是 payload 第 0 字节。这与先前“单 SOP、间隔三帧确认”的错误理解不同。
3. **字节计数器用 4 bit，范围是 0–15。** 最后一个 payload 字节的判断条件是 15，不是 `16*8-1`。
4. **数组和 packed vector 的索引含义不同。** 对 `logic [7:0] out [0:15]`，`out[index]` 是一个字节；对 `logic [127:0] out`，`out[index]` 只有一位。
5. **最后一个 payload 字节必须参与 parity。** 如果它与 parity 字节在不同状态、相邻时钟处理，则下一拍比较时能看到已更新的完整累计结果。
6. **`wait` 是关键字。** 用 `WAIT_SOP` 等标识符命名状态，并正确声明枚举类型与状态寄存器。
7. **不能驱动输入端口。** 应递增 `byte_count`，不能写 `in <= in + 1`。
8. **输出必须是实际的数据接口。** 不要只声明标量 `output out`，却在内部另建同名字节数组。

## 6. 复盘时应该先澄清的问题

- 16 字节指整帧还是 payload？
- 尾部字段到底是 CRC-8，还是八组 16-bit 数据各对应一位的 parity？
- 若为 parity：采用奇校验还是偶校验？八个 bit 如何排序？
- 若为 CRC：多项式、初值、输入/输出反射、最终 XOR、覆盖范围分别是什么？
- 输入是否每拍有效？若允许间断，需要补充 `in_valid`。
- 下游是否支持每帧完成时立即接收？是否需要保持输出或增加反压？
- 校验失败后仅重新搜索，还是还需要错误标志、计数等输出？

这些问题里，只有前三个连续 SOP、字节流输入、可配置 SOP 和一个字节的尾部校验在后续描述中较明确。其余不应把参考代码里的默认选择当作原题硬性要求。

## 7. 建议自测场景

- 正常帧：三个 SOP、16 字节 payload、正确 parity，应产生一次有效脉冲。
- 不完整帧头：一个或两个 SOP 后出现其他值，应重新开始计数。
- payload 含 SOP：不应提前开始新帧。
- 校验错误：翻转 parity 的一位，应拒绝该 payload。
- 两个正确帧紧邻：应分别产生两次有效脉冲。
- 接收中复位：应丢弃未完成帧，并重新搜索 SOP。
- 计数边界：确认只收 16 字节，尾部校验不混入 payload。

注意：parity 不能发现所有多位错误。验证测试应按实际 parity 规则给出预期结果，而不是假定任意数据修改都一定被检测到。
