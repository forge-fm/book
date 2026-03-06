# Comments

Forge models support 3 different syntactic styles of comment:
- lines beginning with `--` are ignored;
- lines beginning with `//` are ignored; and 
- all text between `/*` and `*/` are ignored. 

~~~admonish warning title="No nesting comments"

`/* ... */` comments may **not** be nested. E.g., 

```clike
/*
/*
*/
*/
```
would be a syntax error, because the first instance of `*/` terminates all preceding instances of `/*.
~~~