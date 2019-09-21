## m2r-translator
Compiler for a custom source language that generates code for the object language m2r, using bison and flex.
## Syntactic specification of the source language
The syntax of the source language can be represented by the following grammar
![](https://i.gyazo.com/58f512821464556fcc8ad15c047f856a.png)
## Lexical specification of the source language
![](https://i.gyazo.com/47b34e911a290b40d68f3f4149507b91.png)
## Code execution
```
$ flex plp5.l
$ bison -d plp5.y
$ g++ -o plp5 plp5.tab.c lex.yy.c
```

## Authors
* **Tudor N. M.** - [TudorMN](https://github.com/tudorMN)
* **Alicia N. A.** - [Alicia6N](https://github.com/alicia6n)
