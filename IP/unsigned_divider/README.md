# Unsigned Restoring Divider

这个目录包含一个用于学习除法器数据通路的无符号逐位恢复除法器。

## 硬件结构

除法器主要由以下部分组成：

- `quotient_work`：开始时保存被除数，迭代结束后变成商
- `remainder_work`：保存每轮计算产生的部分余数
- `divisor_reg`：在运算期间保存除数
- 比较/减法器：判断部分余数是否足够减去除数
- `iteration`：记录已经处理了多少位

数据每个周期大致按照下面的路径移动：

```text
 quotient_work 的最高位
           |
           v
 remainder_work 左移并拼入该位
           |
           v
 与 divisor_reg 比较，需要时执行减法
           |
           v
 比较结果写入 quotient_work 的最低位
```

一个 `DATA_WIDTH` 位除法需要处理 `DATA_WIDTH` 个商位，因此非零除法需要
`DATA_WIDTH` 个迭代周期。

## 例子：13 / 3

使用 4 位寄存器：

```text
初始      remainder=0000  quotient=1101
第1轮     remainder=0001  quotient=1010
第2轮     remainder=0000  quotient=0101
第3轮     remainder=0000  quotient=1010
第4轮     remainder=0001  quotient=0100
```

最终结果：

```text
quotient  = 0100 = 4
remainder = 0001 = 1
```

即 `13 = 4 * 3 + 1`。

## 接口时序

```text
start && ready  接受 dividend 和 divisor
busy            非零除法迭代期间保持为 1
done            结果完成时拉高一个时钟周期
ready           busy=0 时为 1
```

当 `divisor=0` 时不会进入迭代状态，模块直接返回：

```text
quotient    = 0
remainder   = dividend
div_by_zero = 1
```

## 仿真

在仓库根目录执行：

```bash
iverilog -g2012 -o /tmp/tb_unsigned_divider.vvp \
  IP/unsigned_divider/unsigned_restoring_divider.sv \
  IP/unsigned_divider/tb_unsigned_restoring_divider.sv
vvp /tmp/tb_unsigned_divider.vvp
```

