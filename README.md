# Lua Compiler in Swift

This project is a Lua-to-assembly compiler written in Swift. It parses Lua code, evaluates it, and generates equivalent assembly code. This compiler supports basic Lua constructs like variable assignment, arithmetic operations, conditional statements, and loops.

## Table of Contents

- [Features](#features)
- [EBNF Grammar](#ebnf-grammar)
- [Railroad Diagram](#railroad-diagram)
- [Usage](#usage)
- [Components](#components)
- [Examples](#examples)
- [Acknowledgments](#acknowledgments)

## Features

- Supports variable declaration and assignment
- Handles arithmetic operations
- Implements conditional statements (if-else)
- Supports loops (while)
- Basic I/O operations (print, read)

## EBNF Grammar

```ebnf
BLOCK = { STATEMENT };
STATEMENT = ( IDENTIFIER, "=", BOOL_EXP | "local", IDENTIFIER, ["=", BOOL_EXP] | "print", "(", BOOL_EXP, ")" | "while", BOOL_EXP, "do", "\n", { ( STATEMENT )}, "end" | "if", BOOL_EXP, "then", "\n", { ( STATEMENT ) }, [ "else", "\n", { ( STATEMENT )}], "end" ), "\n" ;
BOOL_EXP = BOOL_TERM, { ("or"), BOOL_TERM } ;
BOOL_TERM = REL_EXP, { ("and"), REL_EXP } ;
REL_EXP = EXPRESSION, { ("==" | ">" | "<"), EXPRESSION } ;
EXPRESSION = TERM, { ("+" | "-" | ".."), TERM } ;
TERM = FACTOR, { ("*" | "/"), FACTOR } ;
FACTOR = NUMBER | STRING | IDENTIFIER | (("+" | "-" | "not"), FACTOR ) | "(", BOOL_EXP, ")" | "read", "(", ")" ;
IDENTIFIER = LETTER, { LETTER | DIGIT | "_" } ;
NUMBER = DIGIT, { DIGIT } ;
LETTER = ( "a" | "..." | "z" | "A" | "..." | "Z" ) ;
DIGIT = ( "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "0" ) ;
STRING = '"', ({ LETTER | DIGIT | "_" }), '"' ;
```

## Railroad Diagram

![Railroad Diagram](./docs/img/railroad_diagram.png)

_Generated by: [DrawGrammar](https://jacquev6.github.io/DrawGrammar/)_

## Usage

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/your-repo/lua-compiler-in-swift.git
   cd lua-compiler-in-swift
   ```

2. **Compile and Run**:
   Ensure you have Swift installed. Then, compile and run the main Swift file with a Lua source file as an argument:

   ```bash
   swiftc main.swift -o lua-compiler
   ./lua-compiler path/to/source.lua
   ```

3. **Generated Assembly**:
   The compiler will generate an assembly file with the same name as the Lua source file but with a `.asm` extension.

## Components

### Assembler Class

Handles the generation of assembly code:

- **header**: Contains assembly code constants and setup.
- **footer**: Contains assembly code for program termination.
- **addInstruction**: Adds a line of assembly instruction.
- **generate**: Generates the final assembly file.

### PrePro Class

Preprocesses the Lua code:

- **filter**: Removes comments and unnecessary spaces from the Lua code.

### SymbolTable Class

Manages variables and their values:

- **initVar**: Initializes a new variable.
- **setValue**: Sets the value of a variable.
- **getValue**: Retrieves the value of a variable.
- **getOffset**: Gets the memory offset for a variable.

### Node Protocol and Implementations

Represents parts of the abstract syntax tree (AST):

- **Block**: Represents a block of statements.
- **BinOp**: Represents a binary operation.
- **UnOp**: Represents a unary operation.
- **IntVal**: Represents an integer value.
- **StringVal**: Represents a string value.
- **NoOp**: Represents a no-operation.
- **VarDec**: Represents a variable declaration.
- **VarAssign**: Represents a variable assignment.
- **VarAccess**: Represents variable access.
- **Statements**: Represents a list of statements.
- **WhileOp**: Represents a while loop.
- **IfOp**: Represents an if-else statement.
- **ReadOp**: Represents a read operation.
- **PrintOp**: Represents a print operation.

### Token and Tokenizer Classes

Tokenizes the input Lua code:

- **selectNext**: Selects the next token in the source code.

### Parser Class

Parses the tokenized Lua code and generates the AST:

- **parseFactor**
- **parseTerm**
- **parseExpression**
- **parseRelationalExpression**
- **parseBooleanTerm**
- **parseBoolExpression**
- **parseStatement**
- **parseBlock**
- **run**: Parses and evaluates the Lua code.

## Examples

### Sample Lua Code

```lua
local a = 10
local b = 20
if a < b then
  print(a)
else
  print(b)
end
```

### Generated Assembly

```assembly
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
MOV EAX, 10
MOV [EBP-4], EAX
PUSH DWORD 0
MOV EAX, 20
MOV [EBP-8], EAX
if_DJdIyHOAkk:
MOV EAX, [EBP-8]
PUSH EAX
MOV EAX, [EBP-4]
POP EBX
CMP EAX, EBX
CALL binop_jl
CMP EAX, False
JE if_else_DJdIyHOAkk
MOV EAX, [EBP-4]
PUSH EAX
PUSH formatout
CALL printf
ADD ESP, 8
JMP if_end_DJdIyHOAkk
if_else_DJdIyHOAkk:
MOV EAX, [EBP-8]
PUSH EAX
PUSH formatout
CALL printf
ADD ESP, 8
if_end_DJdIyHOAkk:

; interrupcao de saida (default)

PUSH DWORD [stdout]
CALL fflush
ADD ESP, 4

MOV ESP, EBP
POP EBP

MOV EAX, 1
XOR EBX, EBX
INT 0x80%
```

## Acknowledgments

- [DrawGrammar](https://jacquev6.github.io/DrawGrammar/) for generating the railroad diagrams.
- [Lua](https://www.lua.org/) for the inspiration and language reference.

## License

This project is licensed under the AGPL License.

Feel free to contribute, open issues, or submit pull requests to improve this project. Happy coding!
