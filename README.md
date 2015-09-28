# A minimal S-expression library for D.

This library is for handling S-expressions.  
Provides conversion functions between S-expression data and S-expression string.

# Example
```d
import sexp;

Sexp s = parse("(+ 1 (- 3 2))");
assert(s.toString == "(+ 1 (- 3 2))");

Sexp consed = s.cons(0);
assert(consed.toString == "(0 + 1 (- 3 2))");
```
