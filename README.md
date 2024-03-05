# compilers

## Compiler Sintatic Diagram

![Sintatic Diagram](./sintatic_diagram.png)

## EBNF

```txt
EXPRESSION = TERM, { ("+" | "-"), TERM } ;
TERM = FACTOR, { ("*" | "/"), FACTOR } ;
FACTOR = ("+" | "-") FACTOR | "(" EXPRESSION ")" | number ;
```

## Weekly updates

![git status](http://3.129.230.99/svg/G3mha/compilers/)
