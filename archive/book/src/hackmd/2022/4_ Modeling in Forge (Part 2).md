# 4: Modeling in Forge (Part 2)

###### tags: `Tag(sp22)`

#### Wednesday Feb. 2nd: Logistics
* The first Forge homework goes out on Friday. You'll be modeling 2 things: a stack, and a family tree. 
* Between now and then you'll see more Forge syntax, and learn how to model state changes in a system. We'll also clear up some question from this week's lab! In principle, you'll get everything you need for labs and homeworks from lecture **and lecture notes** -- sometimes we'll assign reading from outside 1710, but **at least skim the notes for every class** or you risk missing something.
* **If you're having Forge installation issues, post on EdStem, and we'll get the issues resolved.**  We aren't going to penalize anybody for setup problems. 

## From Last Time: Identifying Abstraction Problems

Last time, you enumerated a few weaknesses of the current model. We'll work on eliminating them (and others) over time. It will be useful to separate out which weaknesses are just "things we haven't represented yet" versus "things that will actively be tough to add, given choices we've already made".

Some things we haven't added yet include...

<details>
<summary>Think, and then click!</summary>

* pathways;
* Sc.B. vs. A.B., CS vs. MATH-CS (and other concentrations);
* capstones;
* 2000-level courses; 
* different intro-sequence tracks; 
* enrollment units and different credit values;
* ...and lots more!
</details>

Some challenges you pointed out (selection is biased by Tim's familiarity with only a small number of concentrations at Brown) include...

<details>
<summary>Think, and then click!</summary>

* CSCI 1010 can be counted as either an intermediate or an advanced course, depending on how it's used in the concentration. Rather like Java, Forge doesn't allow a sig to extend more than one sig, and so it's unclear what a `CSCI1010` singleton object would extend.
* It feels like `numberWrit` duplicates information, or at least isn't grounded in a student's `transcript` field. We should really identify which courses are WRIT designated and count them. (But how do we do that?) 
</details>
    
Let's start by mindfully targeting a single specific concentration. There's the risk that this will lead us to make modeling choices that cause problems later, but if we try to begin by modeling *many* concentrations, it would get overwhelming.

## Attempt 2

Let's keep going. We'll start by resolving the `numberWrit` problem.

### Well-formedness constraints

If we keep the `numberWrit` field around, we need to make sure it's always _well formed_, that is, it really represents the number of WRIT-designated courses in the student's transcript. 

We don't yet know how to count in Forge, but we can still write a template that separates what we _do_ know, from what we _don't_:

```alloy
pred wellformed {
    all s: Student | {
        // ...
    }
}
```

We'll use this pattern a lot. The `...` indicates something we don't know how to do yet. Forge doesn't understand `...`, so we put it in a comment. If we ran the `wellformed` predicate right now, any instance would satisfy the constraint, since an empty constraint block `{ }` is always true: there are no constraints to satisfy!

We know we'll probably need to tell whether a course is WRIT-designated, so let's just make another `pred` for that:

```alloy
pred isWrit[c: Course] {
  c = CSCI1800 or  
  c = MCM0240 or 
  c = TAPS0100  
  // lots more, but let's keep this example small
}
```

Yeah, we need to add these courses to the list of `sig`s. Note that we can use commas to separate sig names if there are no differences between them, so we can write:

```alloy
one sig MCM0240, TAPS0100 extends Intermediate {}
```

#### Did You Notice Something?

What we just did was quite similar to what you're doing now on the PBT homework! There, you're describing what it means for a Poker deal to be valid. Here, we're describing what it means for a concentration declaration to be valid (in the `wellformed` predicate). 

We'll come back to this similarity later.

### Counting

To total the number of WRIT courses that a student has taken, we'll use the _counting_ operator: 

```alloy
#{c: Course | isWrit[c] and passingGrade[s.transcript[c]] }
```

We'll constrain that the student's `numWRIT` field is equal to this value. But this expression feels worth giving a name to, and saving for re-use. 

### Helper Functions (`fun`)

Like predicates, helper functions make it easy to give a name to a value. 

```alloy
fun countWrits[s: Student]: Int {
  #{c: Course | isWrit[c] and passingGrade[s.transcript[c]] }
}

pred wellformed {
    all s: Student | {
        s.numWRIT = countWrits[s]
    }
}
```

**Warning:** Don't confuse helper functions (declared using `fun` at the top level of the model) and function or partial-function fields (declared as part of a `sig` using `pfunc` or `func`). One is a way to enable code reuse; another is actual data in an object.

**Warning:** Always keep in mind that, although the language is object-oriented, it is not a *programming* language. Forge only ever lets us add constraints on the worlds that it finds. There are no "program statements" that execute, and thus no "new" operator. **We can say that an object exists, but we can't say "create a new object".**

#### Can Helper Functions Be Recursive?

Unfortunately, **no**. It would be convenient sometimes if they were, but that's an effort for future years. When we get to how Forge actually works, you'll see why this is a challenge. For now, know there are workarounds that we'll cover in class sometime soon.

### Unsatisfiable Problems

Sometimes there is no possible way to satisfy the constraints we write. If this happens, Forge will report an "unsatisfiable" or "UNSAT" result. This isn't necessarily bad! If you're trying to verify a property of your system, you're going to be asking Forge to find counterexamples to your property -- if none exist, that's good news. But an unsatisfiable result when unexpected or unwanted usually points to problems in your model. 

### Bugs

Since Forge is all about satisfying constraints, the _meaning_ of your model is a predicate on instances. That is, your model defines a function that accepts instances and returns a boolean. We'll often simplify this and say that your model defines a set of instances.

Given that, what would a bug in a model look like?

<details>
<summary>Think, then click!</summary>
There are two main kinds of bugs:
* **underconstraint**: your model allows instances that you didn't expect; and
* **overconstraint**: your model forbids instances that you expected.
</details>
<BR>

Which of these do you think is harder to debug?

<details>
<summary>Think, then click!</summary>
With underconstraint bugs, at least you have a chance to see an unexpected instance, and notice the problem. Then, you can open the evaluator (which we'll cover soon!) to help you find the cause. 
    
In constrast, overconstraint can be more subtle. Even in the extreme case, where it causes your model to be unsatisfiable, it's not clear right away how to debug the problem. And if the bug doesn't cause unsatisfiability, but just _some_ small loss of instances, you might not even notice.

</details>
<BR>

We'll talk more about debugging both of these issues throughout the semester.

### Bounds

Forge always searches for instances up to a finite _bound_. The default bound on all top-level `sig`s is `4`. If we want to change that, we can do so at the `run` command level:

```alloy
run {
    some s: Student | canGraduate[s]
} for 2 Student
```

This command will only search for instances with _up to 2 students_. If we want _exactly_ 2, we can use the `exactly` keyword:

```alloy
run {
    some s: Student | canGraduate[s]
} for exactly 2 Student
```

As you might guess, reconciling these bounds in the presence of inheritance and other complexities can get tricky. Forge will often give errors if it can't figure out what you mean, and it will sometimes implicitly increase your bounds if it thinks it needs to (like if you have more `one` sigs than you've made room for).

We'll come back to bounds around mid-semester, when we talk about how Forge really works.

#### Aside: Integers

Integers are always `exact` bounded by the bitwidth you set. If the bitwidth is 4, you get $2^4$ integers to work with, always! And half of those integers will be negative, always. Thus, a constraint like:

```alloy
all i: Int | i >= 0
```

can never be satisfied, since negative integers always exist, no matter the bitwidth. Similarly, if you state that there are `exactly 2` Students, but then add a counting constraint that forces 3 to exist, Forge won't find an instance.

### Theming

The default visualization can be unhelpful sometimes. For instance, here's a piece of a satisfying instance for the above `run`:

![](https://i.imgur.com/6py0JLV.png)

You can fix this sort of issue via _theming_. Click the Theme tab on the right side of Sterling:

![](https://i.imgur.com/1bV6WYB.png)

Under styles, click on the `transcript` field and click the "Show as Attribute" checkbox. It's not perfect, but it's better:

![](https://i.imgur.com/gRUwf39.png)

Alternatively, you can use the Table view. We'll talk about more ways to improve visualization soon!

### Tests

Sometimes you want to test your model, probing for potential over- and under-constraint bugs. But if you use `run`, it's a bit of a pain: you have to close out a browser tab and hit enter for every test. 

So instead, use the `test` and `example` forms if you're writing tests. These run Forge, but don't open a browser; they just pass or fail. (Forge will currently stop after the first failure.) Here's an example:

```alloy
test expect {
    wellformedAllowsNoWRIT: {
        wellformed 
        some s: Student | s.numWRIT = 0
    } is sat    
}
```

We're checking to make sure the `wellformed` predicate doesn't introduce an overconstraint. A `test expect` block can have any number of tests in it, and each tests gets an individual name (here `wellformedAlloysNoWRIT`) and a block like you would have in a `run` command. If you had custom bounds, you'd add them right after the constraint block. Finally, you say whether you expect the test to be satisfiable (`is sat`) or unsatisfiable (`is unsat`).

**Note:** This test looks quite similar to the predicate that we're testing. However, as models get more complex, it will be a good idea to make sure you mentally separate the ideas; otherwise it's easy to accidentally write a test that is just a subset of the thing you're testing.

## A Preview

One of your HTAs, Anirudh, is working on a more complete model of the CSCI concentration in Forge. Eventually we hope to use it to give suggestions, find problems early, and allow students (and advisors!) to explore the consequences of new requirements.

I wanted to show you to full model, or at least a piece of it. We haven't covered a lot of the stuff that the model uses yet (we've only had a day and a half of Forge!) but note: the thing we're playing with modeling right now is something that you really can model, and in a way that's scalable enough to help the department.

(See the lecture capture for this.)

### Exercise: Constraints and Instances

Go to this [Google Form](https://forms.gle/pX8i6Ls58BLDHxJX7). You'll see some pictures of instances alongside constraints. Do the instances satisfy the constraints? Why do you think so?


### Reachability (`reachable`) and contrasting `one` vs `lone`

There's a new bit of Forge syntax I want to introduce. It's a bit artificial to add it here, but I want to show it to you now (you'll need it for Friday's homework).

Suppose we want to add _prerequisites_ to courses. Right now, Forge gives us a way to do so. We'd just say:

```alloy
sig Course {
  prereq: lone Course
}
```

The `lone` keyword is like `one`, but allows the field to be empty. You can think of this as a sort of _nullable_ reference, as opposed to `one`, which forbids null. 

We could then ask whether a student has the prerequisite for a course they plan to take by writing:

```alloy
pred hasPrereqs[s: Student, c: Course] {
    some c.prereq implies
        some s.transcript[c.prereq]
}
```

(Strictly speaking we don't need the `implies` but I like to add it anyway for clarity.)

This looks innocent enough. But it's a good place to introduce a final idea. **What would happen if we needed to check, at this point, that the student had the prerequisite for the prerequisite?** 

I guess we'd need to add another constraint:

```alloy
pred hasPrereqs[s: Student, c: Course] {
    some c.prereq implies {
        some s.transcript[c.prereq]
        some c.prereq.prereq implies 
            some s.transcript[c.prereq.prereq]
    }
}
```

Good enough, but what if the course's prerequisite's prerequisite has, itself, a prerequisite? This could really get annoying, and, worse, we have no way of knowing when to *stop*! Fortunately, Forge provides a `reachable` helper predicate that we can use to simplify things. 

Writing `reachable[goal,start,F]` means that the `goal` object is reachable from the `start` object via the `F` field. Types matter: you'll get an error if `start` has no `F` field. 

**Warning:** The order of arguments to `reachable` matters! The first argument is the **GOAL** and the second argument is the **START**. Don't get them reversed. 

```alloy
pred hasPrereqs[s: Student, c: Course] {
    all c2: Course | 
        reachable[c2, c, prereq] implies
            some s.transcript[c2]
    }
}
```

**For your homework:** You'll be building family trees. If you want to know whether a person is an ancestor of another, the `reachable` built-in predicate is ideal. However, since a person usually has two biological parents, you'll need to compute reachability using **both** those fields. How? By using the fact that **`reachable` can take more than 3 arguments**: every argument after the 2nd is a field that can be used to compute reachability. So you could write, e.g., `reachable[Eadred, AethelredTheUnready, parent1, parent2]` -- at least, you could if the model had an awareness of obscure English history.



#### Aside For 0320 Students

Regarding `lone` vs. `one`: programming languages like Kotlin distinguish between whether a reference type can be null or not, and this is pretty cool: the type system helps prevent lots of potential errors. Imagine what would be possible with a _slightly_ more expressive type system than Java currently provides. 

## Looking Ahead

Next time we'll shift gears to model something different. The different setting will make it easier to cover some new concepts, and give you another example to build intuition from. 

