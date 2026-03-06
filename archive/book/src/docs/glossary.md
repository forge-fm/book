# What should I do if...?

## Pardinus CLI shut down unexpectedly 

This means that the backend solver process (Pardinus) has terminated early. Usually there is an error message, or at least some error state that is displayed. If you don't see anything, turn on `option verbosity 2`, which will echo back the info messages that Pardinus sends. 

### Arity too large

You might see an info message like this:
```
(info "Arity too large 5 for a universe of size 131 line 10, pos 56:
r:posture [-> none -> none -> none -> none none :: {130 128 129 129 128}]
                                                       ^
")
```

This is a low-level translation error, and it comes from the fact that Pardinus needs to index all possible tuples in every relation. Even tuples that cannot exist because of typing constraints must have an index. But indexes can only go as high as Java's `Integer.MAX_VALUE`&mdash;just over 4 billion.

To see this happening, you can try running this small example. The problem can happen when you have "wide" fields like this. It's natural to want to model a router or firewall as a wide relation or function:

```forge
#lang forge
option verbosity 2
sig Interface {}
sig IP {}
sig ForwardingTable {
  posture: set Interface -> IP -> IP -> Interface
}
run {} for 1 Interface, 1 IP, 1 ForwardingTable, 7 Int
```

In principle, there is only $1$ possible tuple that could inhabit `posture`, because there are never more than 1 of each of the non-integer types. This should be _easy_ to solve! But Pardinus crashes with the above error. Why? Because at `7 Int`, there are $2^7 = 128$ integer atoms, and thus $131 \times 131 \times 131 \times 131 \times 131 = 131^5 = 38,579,489,651$ tuples in the indexable space that Pardinus will try to optimize. But this is far above Java's `Integer.MAX_VALUE`. 

Adding constraints or more typing information won't solve this problem. Not even a partial `inst` will help. There are effectively only two things you can do:
* reduce the number of potential atoms in any instance; or 
* reduce the arity of your model's relations.
Neither of these are ideal, but you can often make progress by reducing scopes on your `sig`s, especially `Int`. If you don't need `Int`, reduce the bitwidth to the minimum: `1 Int`. That may reduce the number of atoms enough. 
You can also try refactoring your model to make relations smaller. 

This is, unfortunately, a low-level issue that the Forge team can't easily fix. And it's a rare problem. But when it occurs, it can be a big problem. Hence this entry. 


### Errors Related to Bounds

#### Please specify an upper bound for ancestors of ...

If `A` is a `sig`, and you get an error that says "Please specify an upper bound for ancestors of A", this means that, while you've defined the contents of `A`, Forge cannot infer corresponding contents for the parent `sig` of `A` and needs you to provide a binding. 
~~~admonish example title="Example"
Given this definition:
```
sig Course {}
sig Intro, Intermediate, UpperLevel extends Course {} 
 ```
and this example:
```
example someIntro is {wellformed} for {
    Intro = `CSCI0150
}
```
the above error will be produced. Add a bound for `Course`:
```
example someIntro is {wellformed} for {
    Intro = `CSCI0150
    Course = `CSCI0150
}
```
~~~

### Errors Related to Testing

#### Invalid example ... the instance specified is impossible ... 

If an `example` fails, Forge will attempt to disambiguate between:
* it actually fails the _predicate under test_; and 
* it fails because it violates the type declarations for sigs and fields. 
 
Consider this example: 

~~~forge
#lang forge/bsl 

abstract sig Grade {} 
one sig A, B, C, None extends Grade {} 
sig Course {} 
sig Person { 
    grades: func Course -> Grade,
    spouse: lone Person 
}

pred wellformed { 
    all p: Person | p != p.spouse 
    all p1,p2: Person | p1 = p2.spouse implies p2 = p1.spouse
}

example selfloopNotWellformed is {wellformed} for {
    Person = `Tim + `Nim 
    Course = `CSCI1710 + `CSCI0320
    A = `A   B = `B   C = `C   None = `None 
    Grade = A + B + C + None

    -- this violates wellformed
    `Tim.spouse = `Tim 
    
    -- but this violates the definition: "grades" is a total function
    -- from courses to grades; there's no entry for `CSCI0320.
    `Tim.grades = (`CSCI1710) -> B
~~~

If you receive this message, it means your example does something like the above, where some type declaration unrelated to the predicate under test is being violated.

### Errors related to syntax

#### Unexpected type or Contract Violation

In Forge there are 2 kinds of constraint syntax for use in predicates:
* formulas, which evaluate to true or false; and 
* expressions, which evaluate to values like specific atoms. 

If you write something like this:

~~~admonish example title="Contract Violation"
```
#lang forge/bsl 
sig Person {spouse: lone Person}
run { some p: Person | p.spouse}
```
produces (along with a filename, row, and column location):
```
some quantifier body expected a formula, got (join p (Relation spouse))
```
In older versions of Forge, it would produce:
```
some: contract violation
  expected: formula?
  given: (join p (Relation spouse))
```
~~~
 
The syntax is invalid: the `some` quantifier expects a _formula_ after its such-that bar, but `p.spouse` is an expression. Something like `some p.spouse` is OK. 
 
Likewise:  
~~~admonish example title="Unexpected Type"
```
sig Person {spouse: lone Person}
run { all p1,p2: Person | p1.spouse = p2.spouse implies p2.spouse}
```
results in (along with a filename, row, and column location):
```
argument 2 of 2 to => had unexpected type. Expected boolean-valued formula, got (p2.spouse), which was atom- or set-valued expression.
```
Older versions of Forge would produce something like:
```
=>: argument to => had unexpected type. 
  expected #<procedure:node/formula?>,
  got (join p2 (Relation spouse))
```
~~~
 
Since `implies` is a boolean operator, it takes a *formula* as its argument. Unfortunately, `p2.spouse` is an expression, not a formula. To fix this, express what you really meant was _implied_. 
