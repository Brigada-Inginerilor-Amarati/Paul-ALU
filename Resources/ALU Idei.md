adunare, scadere -> 2 input 8 biti, output pe 8
impartire -> 1 pe 16 (2clk * 8), 1 pe 8, output pe 8
inmultire -> 2 pe 8, 1 pe 16 (2clk * 8)

RGST -> shift left / right -> load


Intrebari de pus

- numar registrii -> numar diferiti de biti pentru fiecare operatie


Inmultire -> right shift 8 + 8 -> 16 (A + Q) // A -> 0 / Q -> X / M -> Y
Impartire -> left shift 16(A, Q) + 8 -> 8 // A -> MSB X / Q -> LSB X / M -> Y

Booth Radix 4 -> A 9 / Q 9 (8 + bit(-1)) / M 8 (+dublare bit semn) -> 
SRT2 -> A 9 / Q 8 / M 8 (+ dublare)
Sumator pe 9 biti

```verilog

module rgstA/M(
input reg [7:0] data
)

real_data[8:0] = data[7], data[7:0]


module rgstQ(
	input reg [8:0] data,
	input reg...
	output reg [7:0]out
)

out = data[7:0]

module Q-1 DFF(
right shift cu rgstQ
)
```


ALU
- clk
- reset
- begin
- end
- 2 biti de operatii
- 3 control bits [1:0]
- add 1
- add 2
- sub 1
- sub 2
- Right shift
- Left Shift
- FSM counter

Booth Radix 4
Q[1]Q[0]Q[-1]
- skip
- add 1
- add 2
- sub 1
- sub 2
- SHIFT RIGHT (arithmetic)
- counter == 3 -> cnt[1] & cnt[0] == 1

SRT Radix 2
Q[8]Q[7]Q[6]
- skip
- add 1
- sub 1
- SHIFT LEFT
- counter1 == 7
- counter2 (initial shift left, last shift right for the result)