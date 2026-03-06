# Singleton and Maybe Sigs

A sig declaration can be annotated to indicate:
- that there is always exactly one object of that sig (`one sig`);
- that there is never more than one object of that sig (`lone sig`); or
- that any object of that sig must also be a member of some child sig (`abstract sig`).


~~~admonish example title="One Sig"
```clike
sig Dog {}
-- "Beauty without Vanity, Courage without Ferosity, Strength without Insolence"
one sig Boatswain extends Dog {}
```

If you'd asked [Lord Byron](https://en.wikipedia.org/wiki/Epitaph_to_a_Dog), there was only one Boatswain---whose tomb was famously larger than Lord Byron's own.
~~~

~~~admonish example title="Abstract Sig"
```clike
abstract sig Student {}
sig Undergrad, Grad extends Student {}
```

In this example, any `Student` must be either an `Undergrad` or `Grad` student.
~~~

~~~admonish example title="Lone Sig"

Lone sigs aren't used much; you can think of them in the same way you'd use a `one` sig, but with the possibility that the sig will be empty. This can sometimes be useful for efficiency. E.g., if we were modeling soup recipes:

```clike
abstract sig Ingredient {}
lone sig Potatoes extends Ingredient {}
lone sig Carrots extends Ingredient {}
lone sig Celery extends Ingredient {}
lone sig Water extends Ingredient {}
// ...
```

There might be dozens of possible ingredients. But if we only want to use a few at a time, it can be useful to set a lower bound on `Ingredient` and allow un-used ingredients to simply not exist.
~~~
