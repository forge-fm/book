# 29 and 30: Satisfiability Modulo Theories (SMT)

###### tags: `Tag(sp22)`

## Logistics

* Remember we have upcoming guest lectures! You can see them all on this [calendar](https://calendar.google.com/calendar/embed?src=c_npj8brm6vkp1bjj2747tajk2i8%40group.calendar.google.com&ctz=America%2FNew_York). 
* Tim's hours moved to Wednesday 11am this week.
* New Forge build. Problem is: can't get Racket's package system to believe in it last night. Should be able to pull via `git` to get the new version, at least.


## What's "Modulo Theories"?

Boolean solvers are powerful, but not very expressive. If you want to use them to solve a problem involving (e.g.)  arithmetic, you need to encode that idea with booleans. Forge does this by "bit-blasting": one boolean variable per bit in a fixed bitwidth, along with formulas that build boolean adders, multipliers, etc.

An SMT solver is a SAT solver that can handle various domain-specific concepts beyond boolean logic. Hence "modulo theories": it's satisfiability, but with the addition of (say) the theory of linear integer arithmetic.

From a certain point of view, Forge is an "SMT" solver, because it includes concepts like relations and bit-vector integers. But this isn't usually how people understand the term in 2022. SMT solvers can be either "eager" or "lazy". An eager solver translates to boolean logic and then uses a boolean solver engine---this is Forge's approach. A lazy solver actually implements domain-specific algorithms and integrates those with a boolean core. Most modern SMT solvers are lazy, since they can benefit from clever domain algorithms. 

Here are some common domains that SMT solvers tend to support:
* integer arithmetic (linear nearly always, non-linear sometimes)
* real arithmetic (yes, real numbers)
* bit vectors
* arrays
* datatypes

Some slightly less common domains include:
* relations
* lists
* strings

And of course there are many others. The solver we'll use this week supports many of these, but not all.

### A Key Difference

Most SMT solvers don't have "bounds" in the same way Forge does. You can declare a datatype that's bounded in size, but the addition of domains like mathematical integers or lists means that unless you're working in a very restricted space, the set of possible objects is infinite. This can cause some confusion vs. what we're used to.

What does it mean to say "For all $x$ of type $A$, $P(x)$ is true?" In Forge, $A$ always has an upper bound, and so the quantifier can always be converted to a boolean constraint. But in SMT, suppose the type is _integer_? There are infinitely many integers, which means the solver can't convert the quantifier to a (finite) boolean constraint. 

Try to avoid universal quantification in SMT, at least at first. If we had two weeks for SMT, we'd cover quantification in the second week.

Even without universal quantifiction, a problem might not necessarily be solvable. We'll talk more about why on Wednesday; for now, just be aware that the solver might return a third result in addition to sat and unsat: _unknown_ (the solver gave up or ran out of time).

## The Z3 Solver

### Setup

We'll be using the Python bindings for the Z3 solver, available [here](https://pypi.org/project/z3-solver/). You can also install via `pip`:

`pip3 install z3-solver`

To update to the latest version of the solver, you can run:

`pip install z3-solver --upgrade`

Another great solver is [CVC5](https://cvc5.github.io). Although we won't use it in class, it supports some things that Z3 doesn't (and vice versa). For instance: relations!

### Boolean

We've still got the boolean-logic capabilities of a normal SAT solver:

```python 
def demoBool(self):
        # Create a new solver
        s = Solver()

        # declare some boolean *solver* variables
        p, q = Bools('p q')         
        
        s.add(Or(p, q))
        if s.check() == sat:        
            print(s.model()) # "model" ~= "instance" here :/
        
        # (Think: how would we get a different instance?)

        # getting at pieces of a model for programmatic use
        print(s.model().evaluate(p)) # can pass a formula              
```

### Uninterpreted Functions And Integer Inequalities

If a symbol (function, relation, constant, ...) is _interpreted_, then its meaning is encoded via constraints built into the solver. In Forge, we'd say that:
* `add` is an interpreted function, since Forge assigns it a meaning innately; but
* relations you add as sig fields are uninterpreted, since absent constraints you add yourself, Forge treats their values as arbitrary.

With some exceptions, SMT solvers usually have functions, not relations. This is another reason for Froglet to be about functions---they're more useful as a foundation in other tools.


```python

    def demoUninterpreted(self):
        s = Solver()
        # ; Ints, UNINTERPRETED Functions (think of as like relations in Alloy)        
        a, b = Ints('a b')  
        f = Function('f', IntSort(), IntSort())
        s.add(And(b > a, f(b) < f(a)))        
        if s.check() == sat:        
            print(s.model()) 
        print(s.model().evaluate(f(a)))
        print(s.model().evaluate(f(b)))
        print(s.model().evaluate(f(1000000)))
```

## Arithmetic

Let's try something that involves arithmetic, and also explore how the solver handles real numbers vs. integers.

**TODO**: we use a forall here?


```python
 # Real numbers
    def demoReals(self):
        s = Solver()
        x = Real('x') #Int('x')  
        s.add(x*x > 4)
        s.add(x*x < 9)
        result = s.check()
        if result == sat:
            print(s.model())    
        else: 
            print(result)
        
    def demoFactoringInt(self):
        s = Solver()
        # (x - 2)(x + 2) = x^2 - 4
        # Suppose we know the RHS and want to find an *equivalent formula* LHS:
        # (x - ROOT1)(x + ROOT2) = x^2 - 4
        xi, r1i, r2i = Ints('x root1 root2') # int vars

        # Note: don't use xi ** 2 -- gives unsat?
        s.add(ForAll(xi, (xi + r1i) * (xi + r2i) == (xi * xi) - 4  ))
        result = s.check()
        if result == sat:
            print(s.model())    
        else: 
            print(result)

        s.reset()    
        # (x + 123)(x - 321) = x^2 - 198x - 39483
        s.add(ForAll(xi, (xi + r1i) * (xi + r2i) 
                         == (xi * xi) + (198 * xi) - 39483))
        result = s.check()
        if result == sat:
            print(s.model())    
        else: 
            print(result)
        # Note how fast, even with numbers up to almost 40k. Power of theory solver.

    def demoFactoringReals(self):
        s = Solver()
        x, r1, r2 = Reals('x root1 root2') # real number vars
        # ^ Solve for r1, r2 because they are unbound in outer constraints
        #   x is quantified over and therefore not a var to solve for

        # (x + ???)(x + ???) = x^2 - 198x - 39484         
        s.add(ForAll(x, (x + r1) * (x + r2) 
                         == (x * x) + (198 * x) - 39484))
        result = s.check()
        if result == sat:
            print(s.model())    
        else: 
            print(result)
        
        s.reset()

        # Here's how to start using cores in Z3 if you want, but
        # see the docs -- it's a bit more annoying because you need to create 
        # new boolean variables etc.

        #s.set(unsat_core=True) # there are so many options, at many different levels
        # use s.assert_and_track; need to give a boolean 
        # see: https://z3prover.github.io/api/html/classz3py_1_1_solver.html#ad1255f8f9ba8926bb04e1e2ab38c8c15 

        # Now, for the demo!
        
        # Note e.g., x^2 - 2x + 5 has no real roots (b^2 - 4ac negative)
        s.add(ForAll(x, (x + r1) * (x + r2) 
                         == (x * x) - (2 * x) + 5))
        
        result = s.check() 
        if result == sat:
            print(s.model())    
        else: 
            print(result)            

    def coefficients(self):

        s = Solver()
        x, r1, r2, c1, c2 = Reals('x root1 root2 c1 c2') # real number vars        
        s.add(ForAll(x, ((c1*x) + r1) * ((c2*x) + r2) == (2 * x * x)))
        result = s.check()
        if result == sat:
            print(s.model())    
        else: 
            print(result)  


```


### Another Demo: N-Queens

```python
   def nQueens(self, numQ):
        s = Solver()
        # Model board as 2d list of booleans. Note the list is *Python*, booleans are *Solver*
        cells = [ [ z3.Bool("cell_{i}{j}".format(i=i,j=j)) 
                    for j in range(0, numQ)] 
                    for i in range(0, numQ) ]
        #print(cells)
        
        # a queen on every row
        queenEveryRow = And([Or([cells[i][j] for j in range(0, numQ)]) for i in range(0, numQ)])
        #print(queenEveryRow) # for demo only
        s.add(queenEveryRow)

        # for every i,j, if queen present there, implies no queen at various other places
        # Recall: queens can move vertically, horizontally, and diagonally.
        # "Threaten" means that a queen could capture another in 1 move. 
        queenThreats = And([Implies(cells[i][j], # Prefix notaton: (And x y) means "x and y".
                                    And([Not(cells[i][k]) for k in range(0, numQ) if k != j] +
                                        [Not(cells[k][j]) for k in range(0, numQ) if k != i] +
                                        # Break up diagonals and don't try to be too smart about iteration
                                        [Not(cells[i+o][j+o]) for o in range(1, numQ) if (i+o < numQ and j+o < numQ) ] +
                                        [Not(cells[i-o][j-o]) for o in range(1, numQ) if (i-o >= 0 and j-o >= 0) ] +
                                        # flipped diagonals
                                        [Not(cells[i-o][j+o]) for o in range(1, numQ) if (i-o >= 0 and j+o < numQ) ] +
                                        [Not(cells[i+o][j-o]) for o in range(1, numQ) if (i+o < numQ and j-o >= 0) ]
                                        ))
                           for j in range(0, numQ)
                           for i in range(0, numQ)])
        #print(queenThreats) # for demo only
        s.add(queenThreats)

        if s.check() == sat:
            for i in range(0, numQ):
                print(' '.join(["Q" if s.model().evaluate(cells[i][j]) else "_" for j in range(0, numQ) ]))
        else: 
            print("unsat")

if __name__ == "__main__":
    demo = SMTDemo()
    demo.coefficients()
```

## Wednesday

Note: class will cover:
* boolean skeleton;
* congruence closure (intuition);
* Goldbach argument; and 
* undecidability.

I've had to copy a bunch of difference sources to construct this lecture given external tim constraints, so expect the notes to be less-than-ideal.


## What's Going On In The Solver?

Modern SMT-solvers tend to be _lazy_ (a technical term): they use a base boolean solver, and call out to domain-specific algorithms ("theory solvers") when needed. This is how Z3 manages to be so fast at algebraic reasoning.

But what shape of constraints do these theory-solvers accept? And how does an SMT solver manage to provide that? Let's look at one potential theory: systems of linear inequalities.

### An Example Theory-Solver: Linear Inequalities

If I gave you a system of linear inequalities, like this:

```
x + y < 3
x < 2y
```

Could you find a solution? Probably (at least, if you Googled or had an old algebra textbook to hand). Or, if you're like me, you might [enter it into Wolfram Alpha](https://www.wolframalpha.com/input?i=plot++x+%2B+y+%3C+3+and+x+%3C+2y):

![](https://i.imgur.com/NAETuFr.png)

But suppose we added a bunch of boolean operators into the mix. Now what? You can't solve a "system" if the input involves "or". 

SMT solvers use a technique to separate out the boolean portion of a problem from the theory-specific portion. For example, if I wrote: `x > 3 or y > 5`, the solver will convert this to a _boolean skeleton_, replacing all the theory terms with boolean variables: `T1 or T2`, where `T1` means `x > 3` and `T2` means `y > 5`.  It can now find an assignment to that boolean skeleton with a normal SAT-solver. And every assignment is implicitly conjunctive: there's no "or"s left! 

Suppose the solver finds `T1=True, T2=True`. Then we have the system:

```
x > 3
y > 5
```

If, instead, the solver found `T1=False, T2=True`, we'd have the system:

```
x <= 3
y > 5
```


### Another Example Theory-Solver: Uninterpreted Functions With Equality

Here are some constraints:

```
! ( f(f(f(a))) != a or f(a) = a ) 
f(f(f(f(f(a))))) = a or f(f(a)) != f(f(f(f(a))))
```

Are these constraints satisfiable? Does there exist some value of `a` and `f` such that these constraints are satisfied?

As before, we'll convert these to a boolean skeleton:

```
!(T1 or T2)
T3 or T4
```

### An Unproductive Assignment

This CNF is satisfied by the assignment `T1=False, T2=False, T3=True, T4=False`, which gives us the theory problem:

```
f3(a) = a
f(a) != a
f5(a) = a
f2(a) = f4(a)
```

(I won't even need that fourth constraint to show this skeleton-assignment won't work.)

This system of equalities can be solved via an algorithm called _congruence closure_. It goes something like this. First, collect all the terms involved in equalities and make


![](https://i.imgur.com/BKRgQH7.png)

Now draw undirected edges between the terms that the positive equality constraints force to be equivalent. Since we're being told that `f3(a) = a`, we'd draw an edge between those nodes. And similarly between `f5(a)` and `a`:

![](https://i.imgur.com/FnX80hb.png)

But equality is transitive! So we have learned that `f5(a)` and `f3(a)` are equivalent. (This is the "closure" part of the algorithm's name.)

From there, what else can we infer? Well, if `f3(a)` is the same as `a`, we can substitute `a` for `f(f(f(a)))` inside `f(f(f(f(f(a)))))`, giving us that `f(f(a))` (which we're calling `f2(a)` for brevity) is equivalent to `a` as well, since `f5(a) = a`. And since equality is transitive, `f2(a)` equals all the other things that equal `a`.

![](https://i.imgur.com/NweNJdR.png)

And if `f2(a) = a`, we can substitute `a` for `f(f(a))` within `f(f(f(a)))`, to get `f(a) = a`. 

But this contradicts the negative equality constraint `f(a) != a`. So we've found a contradiction.

![](https://i.imgur.com/6s7Rv6N.png)

### A Productive Assignment

Another way of solving the boolean skeleton is with the assignment `T1=False, T2=False, T3=False, T4=True`, which gives us the theory problem:

```
f3(a) = a
f(a) != a
f5(a) != a
f2(a) != f4(a)
```

We'd proceed similarly. But this time we don't have many unavoidable equalities between terms: `f3(a)` is linked with `a`, and we could say that `f6(a) = a` via substitution---if we cared about `f6(a)`. But it's not necessary for any of the inequalities to be violated. 



## Return to Decidability

There's a famous unsolved problem in number theory called [Goldbach's conjecture](https://en.wikipedia.org/wiki/Goldbach%27s_conjecture). It states:

> Every integer greater than 2 can be written as the sum of three primes.

This is simple to state. Yet, we don't know whether or not it holds for _all_ integers greater than 2. We've looked for small (and not so small) counterexamples, and haven't found one yet. 

But that illustrates a problem. To know whether Goldbach's conjecture is _false_, we just need to find an integer greater than 2 that cannot be written as the sum of 3 primes. Here's an algorithm for disproving the conjecture:

```python
    for i in Integers:
        for p1, p2, p3 in PrimesUpTo(i):
            if i = p1 + p2 + p3: 
                continue;
        return i;
```

If Goldbach's conjecture is wrong, this computation will eventually terminate and give us the counterexample.

But what about the other direction? What if the conjecture is actually true? Then this computation never terminates, and never gives us an answer. We never learn that the conjecture is true, because we're never done searching for counterexamples. 

Now, just because this specific algorithm isn't great doesn't mean that a better one might not exist. Maybe it's possible to be very smart, and search in a way that will terminate with _either_ true or false. 

Except that it's not. CSCI 1010 talks about this a lot more, but I want to give you a bit of a taste of the ideas today. 

Note that we can express Goldbach's conjecture in Z3...

## Undecidability

I want to tell you a story---with only _some_ embellishment. 

First, some context. How do we count things? Does ${1,2,3}$ have the same number of elements as ${A, B, C}$? What about $\mathbb{N}$ vs. $\mathbb{N} \cup \{BrownU\}$? If we're comparing infinite sets, then it seems reasonable to say that they have the same size if we can make a bijection between them: a 1-1 mapping. 

But then, counter-intuitively, $\mathbb{N}$ and $\mathbb{N} \cup \{BrownU\}$ are the same size. Why? Because of Hilbert's Hotel. Here's the idea: suppose you work at the front desk of a hotel with a room for every natural number. And, that night, every room is occupied. A new guest arrives. Can you find room for them?

<details>
<summary>Think, then click!</summary>
Yes! Here's how. For every room $i$, tell that guest to move into room $i+1$. You'll never run out of rooms, and room 0 will be free for the new guest.

![](https://i.imgur.com/vLlsryz.png)


</details>

So, it's the late 1800's. Hilbert's Hotel (and related ideas) have excited the mathematical world. Indeed, can we use this trick to show that _every_ infinite set is the same size? Are all infinities one?

There was a non-famous but moderately successful mathematician named Georg Cantor, in his 40s at the time. Georg suffers from depression, and indeed lived a tragic life (and died a tragic death). Cantor proves that the power set of $N$, that is, the set of subsets of $N$, must be strictly larger than $N$. This was groundbreaking work, and gives the lie to the conventional wisdom (thanks, Hardy) about young mathematicians.

There is pandemonium. There is massive controversy. He was, no kidding, called a corrupter of youth. Later, mathematicians said tht his ideas are 100 years too early, and Hilbert actually said, later, that "No one shall drive us from the paradise Cantor has created for us."

How did Cantor prove this? By contradiction. Assume you're given a bijection between a set $N$ and its power set. Now, an infinite table must exist, with subsets of $N$ as rows and elements of $N$ as columns. The cells contain booleans: true if the subset contains the element, and false if it doesn't. 

**PLACEHOLDER FOR FALL: sketch**

Cantor showed that there must always be a row (i.e., a subset of $N$) that isn't represented in the table. That is, a bijection cannot exist. Even _with_ the very permissive definition of "same size" we use for infinite sets, there are _still_ more subsets of (say) natural numbers than there are natural numbers.

Why does this matter to *US*? Let me ask you two questions:

**QUESTION 1**: How many syntactically-valid Java program source files are there?

**QUESTION 2**: How many mathematical functions from `int` inputs to `bool` outputs are there?

What is our conclusion? 

Try as you might, it is impossible to express all functions (of infinite type) in any programming language where program texts are finite. 

So we know that programs in any language must be unable to express _some_ things (indeed, most things). But is there anything NO language can express? Maybe all the things unexpressible nobody actually needs or cares about.

### Another Story

It's the early 1900's. Hilbert and others: *IS MATHEMATICS MECHANIZABLE*?

In 30's: Church, Turing, Godel: "No. At least not completely." 
  
Why? A few reasons. Here's a challenge. Write for me a program `h(f, v)` that accepts two arguments:
* another program; and
* an input to that program.

It must:
* always terminate; 
* return true IFF f(v) terminates in finite time;
* return false IFF f(v) does not terminate in finite time

Suppose `h` exists, and can be embodied in our language. Then consider this program.

```
def g(x):
  if h(g, x): # AM I GOING TO HALT? (remember h always terminates)
    while(1); # NUH UH IM NOT!
  else:       
    return;   # HAHAHAHAHA YES I AM
```

Argh! Assuming that our halting function h is a program itself: CANNOT EXIST! This is called the "halting problem".

 
  Exercise: what consequences for us? OK to be philosophical, uncertain.

  "Undecidability"
    
![](https://i.imgur.com/1VISrAR.png)

### What Does This Have To Do With SMT?

Gödel also proved that number theory is undecidable: if you've got the natural numbers, multiplication, and addition, it is impossible to write an algorithm that answers _arbitrary_ questions about number theory in an _always correct_ way, in _finite_ time.

There are also tricks you'll learn in 1010 that let you say "Well, if I could solve arbitrary questions about number theory, then I could turn the halting problem into a question about number theory!"

There's so much more I'd like to talk about, but this lecture is already pretty disorganized, so I'm not going to plan on saying more today.







## Looking Ahead

Friday: CEGIS
Deal with HO universals, other issues of optimization

Powerful, used with both SAT and SMT for e.g. program or circuit synthesis.



