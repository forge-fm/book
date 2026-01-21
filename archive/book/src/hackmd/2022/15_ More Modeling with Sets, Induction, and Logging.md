# 15: More Modeling with Sets, Induction, and Logging

###### tags: `Tag(sp22)`

## Logistics: Forge Update and Logging

We're updating Forge soon---likely this evening or tomorrow. There are some improvements to the sequence library. But there is also a fix to logging, which was previously not happening. 

**Since logging is now enabled, I want to be open about what we're logging, and how you can opt out if you wish.**

### What We're Logging, And Where To

By default, the new Forge version will record, for every run:
* a copy of the model;
* a timestamp and source IP;
* the language name (e.g., `forge/bsl`);
* the project name;
* the anonymous ID;
* the filename and anonymized directory name; and
* error output (if any).

These all get saved into a temporary directory you can find by running:
```
$ racket
Welcome to Racket v8.3 [cs].
> (require basedir)
> (writable-config-file "lfs2022.rktd" #:program "forge")
#<path:/Users/tim/.config/forge/lfs2022.rktd>
```

These files are periodically uploaded to the cloud for storage (so they won't eat up too much disk space).

### Why We're Logging

* We log a copy of the model, so we can...
    * learn whether Forge's error messages are effective or misleading by seeing how models change in response; and
    * discover new variant partial solutions that we might not have anticipated.
* We log a timestamp, filename, anonymized directory name, and anonymous ID so we can...
    * disambiguate different model versions or threads of development in case of bugs in our logging; and
    * have the capability to diagnose, de-anonymize and send mail if we notice any errors in the logger that could impact a student's Forge performance or experience. 
* We log the source IP so we can...
    * further disambiguate between different threads of development (in case the placeholder ID is left in).
* We log the language name and project name so we can...
    * learn in which projects students have particular trouble with Forge; and
    * learn whether, and how, students will prefer Froglet on later assignments.
* We log error output so we can...
    * learn what errors students are seeing, and hopefully improve their quality over time.
    
Forge (especially Froglet) is under active development. Some error messages are currently terrible, and there are the occasional crash bugs etc. Logging helps us make improvements we might not think to make on our own, unless you manually file a bug report. It's also useful for evaluating how _effective_ teaching Froglet was this year. 

However, we understand that you might prefer to **not** participate in logging.

### How To Opt Out

If you wish to turn off logging, just leave off the project ID and anonymous ID on the `#lang` line of your file. E.g., instead of:

```
#lang forge/bsl "cm" "jdsnfjnasfjnsdf@gmail.com"
```
for curiosity modeling, you'd just use:

```
#lang forge/bsl
```

Doing this will disable the logging infrastructure. 

### Logging Is Unrelated To Your Grade

While we hope you'll keep logging on, whether or not you have logging enabled **will not** affect your grade in the course. 

If you decide to not use logging, we understand---and hope you'll continue to file manual bug reports (with details and context) [here](https://report.forge-fm.org/).


## Modeling A Mutual-Exclusion Protocol

If you have two independent threads running concurrently, many subtle bugs can manifest. For instance, if both threads can write to the same region of memory, they might overlap their writes. A great example of this is simply incrementing a counter. If both threads have:

```java
  counter = counter + 1;
```

in their code, then the following sequence of operations would be problematic:
* Thread 1: read the current value of `counter`
* Thread 2: read the current value of `counter`
* Thread 1: add `1` to that value
* Thread 1: write the new value to `counter`
* Thread 2: add `1` to that value
* Thread 2: write the new value to `counter`
because then the counter's value is only `1` higher than its original value.

We often call the property that such traces can't exist _mutual exclusion_, and the piece of code that shouldn't ever be run by 2 threads at once the _critical section_.

Today we'll model a very simple approach to mutual-exclusion. The approach turns out not to work, but it's one of the first "bad" solutions you'd see in a course like 1760.

### A Simplified Mutual-Exclusion Algorithm

Consider the pseudocode below, and imagine it running on two separate threads of execution. I've marked _program locations_ in square brackets---note how they correspond to the spaces in between lines of code executing.

```java
while(true) { 
    [state: disinterested]
    this.flag = true;
    [state: waiting]
    while(other.flag == true);    
    [state: in-cs]    
    this.flag = false;    
}
```

Both processes will always continuously try to access the critical section. When they become interested, they set a public `flag` bit to true. Then, they don't enter until their counterpart's flag is false. When they're done executing the critical section, they lower their flag and restart. 

Notice we aren't modeling the critical section itself. The exact nature of that code doesn't matter for our purposes; we just want to see whether both process can be at the `in-cs` location at once. If so, mutual exclusion fails!

### Modeling

We'll start with sigs:

```alloy
abstract sig Location {}
one sig Disinterested, Waiting, InCS extends Location {}

abstract sig Process {}
one sig ProcessA, ProcessB extends Process {}

sig State {
    loc: func Process -> Location,
    flags: set Process
}
```

An initial state is one where all processes are disinterested, and no process has raised its flag:

```alloy
pred init[s: State] {
    all p: Process | s.loc[p] = Disinterested
    no s.flags 
}
```

We then have three different transition predicates, each corresponding to one of the lines of code above, and a transition predicate `delta` that represents _any_ currently-possible transition:

```alloy

pred raise[pre: State, p: Process, post: State] {
    pre.loc[p] = Disinterested
    post.loc[p] = Waiting
    post.flags = pre.flags + p
    all p2: Process - p | post.loc[p2] = pre.loc[p2]
}

pred enter[pre: State, p: Process, post: State] {
    pre.loc[p] = Waiting 
    pre.flags in p -- no other processes have their flag raised
    post.loc[p] = InCS    
    post.flags = pre.flags
    all p2: Process - p | post.loc[p2] = pre.loc[p2]
}

pred leave[pre: State, p: Process, post: State] {
    pre.loc[p] = InCS    
    post.loc[p] = Disinterested    
    post.flags = pre.flags - p
    all p2: Process - p | post.loc[p2] = pre.loc[p2]
}

-- the keyword "transition" is reserved
pred delta[pre: State, post: State] {
    some p: Process | 
        raise[pre, p, post] or
        enter[pre, p, post] or 
        leave[pre, p, post]
}
```

We won't create a `Trace` sig or `traces` predicate at all. We're going to do everything with induction today.

### Model Validation

```alloy
test expect {
    canEnter: {        
        some p: Process, pre, post: State | enter[pre, p, post]        
    } is sat
    canRaise: {        
        some p: Process, pre, post: State | raise[pre, p, post]        
    } is sat    
    canLeave: {        
        some p: Process, pre, post: State | leave[pre, p, post]        
    } is sat    
}
```


### Does Mutual Exclusion Hold?

Before we run Forge, ask yourself whether the algorithm above guarantees mutual exclusion. (It certainly has another kind of error, but we'll get to that later. Focus on this one property.)

It seems reasonable that the property holds. But if we try to use the inductive approach to prove that:

```alloy
pred good[s: State] {
    #{p: Process | s.loc[p] = InCS} <= 1
}

test expect {
    baseCase: {not {all s: State | init[s] implies good[s]}} for exactly 1 State is unsat
    inductiveCase: {
        not {
            all pre, post: State | 
                delta[pre, post] and good[pre] implies good[post]
        }
    } for exactly 2 State is unsat
```

The inductive case _fails_. Let's see what the counterexample is:

```alloy
    run {
      not {
        all pre, post: State | 
          delta[pre, post] and good[pre] implies good[post]
        }
    } for exactly 2 State
```

Yields:

![](https://i.imgur.com/UFREBrD.png)

or, in the table view:

![](https://i.imgur.com/tJsdyDV.png)

Notice that neither process has raised its flag in either state. This seems suspicious...


### Enriching The Invariant

This counterexample shows that the property we wrote _isn't inductive_. But it might still an invariant of the system---it's just that Forge has found an unreachable prestate. To prevent that, we'll add more conditions to the `good` predicate (we call this _enriching the invariant_ or _proving something stronger_). Let's say that, in order for a process to be in the critical section, its flag needs to be true:

```alloy
pred good2[s: State] {
    all p: Process | s.loc[p] = InCS implies p in s.flags        
    #{p: Process | s.loc[p] = InCS} <= 1        
}
```

But the inductive case still fails! Let's enrich again. The flag _also_ has to be raised if a process is waiting for its counterpart's flag to become false:

```alloy
pred good3[s: State] {
    all p: Process | (s.loc[p] = InCS or s.loc[p] = Waiting) implies p in s.flags    
    #{p: Process | s.loc[p] = InCS} <= 1        
}
```

Now the inductive check passes. We've just shown that this algorithm satisfies mutual exclusion.

### Sanity-Checking The Proof

We should probably make sure the two proof steps aren't passing vacuously:

```alloy
test expect {
    baseCaseVacuity: {
        some s: State | init[s] and good1[s]
    } for exactly 1 State is sat
    
    inductiveCaseVacuity: {
        some pre, post: State | 
                delta[pre, post] and good3[pre]
    } for exactly 2 State is sat

}
```

## In-Class Exercise

The link is [here](https://forms.gle/k8eVkKohvZavkD6w9).