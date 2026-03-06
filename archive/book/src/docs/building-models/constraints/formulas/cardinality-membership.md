# Cardinality and Membership

The following operators produce formulas from smaller expression arguments:

- `no <expr>`: true when `<expr>` is **empty**
- `lone <expr>`: true when `<expr>` contains **zero or one** elements
- `one <expr>`: true when `<expr>` contains **exactly one** element
- `some <expr>`: true when `<expr>` contains **at least one** element
- `<expr-a> in <expr-b>`: true when `<expr-a>` is a **subset** of or equal to `<expr-b>`
- `<expr-a> = <expr-b>`: true when `<expr-a>` and `<expr-b>` contain exactly the **same elements**
