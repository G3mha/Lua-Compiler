  ; constantes
  SYS_EXIT equ 1
  SYS_READ equ 3
  SYS_WRITE equ 4
  STDIN equ 0
  STDOUT equ 1
  True equ 1
  False equ 0

  segment .data

  formatin: db "%d", 0
  formatout: db "%d", 10, 0 ; newline, nul terminator
  scanint: times 4 db 0 ; 32-bits integer = 4 bytes

  segment .bss  ; variaveis
  res RESB 1

  section .text
  global main ; linux
  ;global _main ; windows
  extern scanf ; linux
  extern printf ; linux
  ;extern _scanf ; windows
  ;extern _printf; windows
  extern fflush ; linux
  ;extern _fflush ; windows
  extern stdout ; linux
  ;extern _stdout ; windows

  ; subrotinas if/while
  binop_je:
  JE binop_true
  JMP binop_false

  binop_jg:
  JG binop_true
  JMP binop_false

  binop_jl:
  JL binop_true
  JMP binop_false

  binop_false:
  MOV EAX, False  
  JMP binop_exit
  binop_true:
  MOV EAX, True
  binop_exit:
  RET

  main:

  PUSH EBP ; guarda o base pointer
  MOV EBP, ESP ; estabelece um novo base pointer
  
PUSH DWORD 0
MOV [EBP-4], EAX
PUSH scanint
PUSH formatin
call scanf
ADD ESP, 8
MOV EAX, DWORD [scanint]
MOV EAX, [EBP-4]
PUSH EAX
PUSH formatout
CALL printf
ADD ESP, 8
if_6060438086917950614:
MOV EAX, 3
PUSH EAX
MOV EAX, [EBP-4]
POP EBX
CMP EAX, EBX
CALL binop_je
PUSH EAX
MOV EAX, 1
PUSH EAX
MOV EAX, [EBP-4]
POP EBX
CMP EAX, EBX
CALL binop_jl
NOT EAX
NOT EAX
NOT EAX
PUSH EAX
MOV EAX, 1
PUSH EAX
MOV EAX, [EBP-4]
POP EBX
CMP EAX, EBX
CALL binop_jg
POP EBX
AND EAX, EBX
POP EBX
OR EAX, EBX
CMP EAX, False
JE if_else_6060438086917950614
MOV [EBP-4], EAX
MOV EAX, 2
JMP if_end_6060438086917950614
if_else_6060438086917950614:
if_end_6060438086917950614:
PUSH DWORD 0
MOV [EBP-8], EAX
MOV EAX, 2
PUSH EAX
MOV EAX, 4
PUSH EAX
MOV EAX, 6
POP EBX
ADD EAX, EBX
POP EBX
IDIV EAX, EBX
PUSH EAX
MOV EAX, 1
PUSH EAX
MOV EAX, 0
POP EBX
IDIV EAX, EBX
PUSH EAX
MOV EAX, 2
PUSH EAX
MOV EAX, 4
PUSH EAX
MOV EAX, 2
NEG EAX
POP EBX
IMUL EAX, EBX
POP EBX
IDIV EAX, EBX
PUSH EAX
MOV EAX, 2
PUSH EAX
MOV EAX, 3
PUSH EAX
MOV EAX, 6
POP EBX
IDIV EAX, EBX
POP EBX
IMUL EAX, EBX
PUSH EAX
MOV EAX, 3
POP EBX
ADD EAX, EBX
POP EBX
SUB EAX, EBX
POP EBX
ADD EAX, EBX
POP EBX
SUB EAX, EBX
PUSH DWORD 0
MOV [EBP-12], EAX
MOV EAX, 3
MOV [EBP-12], EAX
MOV EAX, [EBP-4]
PUSH EAX
MOV EAX, [EBP-12]
POP EBX
ADD EAX, EBX
PUSH DWORD 0
MOV [EBP-16], EAX
MOV EAX, [EBP-12]
PUSH EAX
MOV EAX, [EBP-8]
POP EBX
ADD EAX, EBX

  ; interrupcao de saida (default)

  PUSH DWORD [stdout]
  CALL fflush
  ADD ESP, 4

  MOV ESP, EBP
  POP EBP

  MOV EAX, 1
  XOR EBX, EBX
  INT 0x80