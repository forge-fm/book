# 3: Modeling in Forge (Part 1)

###### tags: `Tag(sp22)`

**Reminder: pre-load the concentration checker model**

#### Monday Jan 31: Logistics

* Tim accidentally released a herd of wild frogs in Gradescope, and one of them hit the "Sync with Canvas" button when it oughtn't to have. Please submit under your **anonymous** ID, not your real name, as those accounts will be removed to preserve your privacy. 
* Please fill out the lab time preference form ASAP. Today! We're adding a 4th section (and have hired another TA).
* Install Forge! You can either install from the package system or from Git. At this point you should have version `1.0.0` (prior years have been major version `0`). Expect updates roughly weekly. 
* The Forge docs are being revised along with my lecture notes. We have a reasonable baseline, but we'll be expanding the Forge wiki over time. 

#### Capstoning 1710

The 1710 capstone requires one component: a capstone-quality final project. This means:
* a topic more directly related to CS than required otherwise (since the capstone is, at least in principle, supposed to integrate your CS course experience); 
* clear outcomes (what are you planning to learn, or verify, based on your capstone project?); 
* a somewhat higher bar in evaluating those outcomes; and
* more careful review of your project proposal by Tim, and a discussion, usually brief, during which the bar for success will be set.

Yes, capstone final projects are still group projects! And your partner(s) don't need to be capstoning the course themselves. But make sure your project partners are aware of the ambition, and be prepared to drive the project while also respecting their own priorities and learning goals.


## Summary

This chapter contains a tour of modeling systems in Forge, and is meant to be the first part of a multi-lecture series. By the end of this material, you should:
* understand the concepts of _constraint_ and _instance_;
* understand what it means for an instance to satisfy constraints; and
* be able to write and execute simple models in Forge.

At the most basic level, Forge accepts _constraints_ as input and produces _instances_ that satisfy those constraints. But what does that mean? Let's start with an example.

Brown University itself doesn't have very complicated graduation requirements: 30 credits (and 32 "enrollment units") a couple of writing classes, and a concentration. But each concentration has different requirements, and the complexity there can be staggering. 

Let's model what it means to satisfy a set of concentration requirements. I like the example because it's important to all of us, easy to start working with, and also deceptively complex. We'll start simple, and gradually refine and expand the model over the rest of the semester. 

## Attempt 1

Before we start writing the model in Forge, let's be more clear about the terminology.

### Concept: Constraints

What's a **constraint** in this setting? Informally, we might start with something like: _"You must take 5 intermediate courses, distributed across the 3 categories of Math, Systems, and Theory"._ Today you'll see how to write these in Forge.

### Concept: Instances

What's an **instance** in this setting? An instance is whichever type of thing satisfies (or fails to satisfy!) the constraints. So maybe today it's a concentration declaration that lists courses you intend to take. On other days, the instances will look different because we'll be talking about different kinds of things. (More on this later.)

**Warning:** Although Forge makes heavy use of terminology from object-oriented programming, this one term differs from what you're used to. In Java, we'd speak of objects as "instances of a class"; here an instance is the world that contains the objects themselves. 

### Types and Fields

Before we can write constraints, we need to tell Forge what kinds of objects can exist in an instance. You can think of these as similar to objects in an object-oriented program. Each has a class it belongs to, along with possibly some relationships to other objects. Here's an example:

```
sig Student {
    numberWRIT: one Int
}
```

In Forge, we call classes `sig`s for historical reasons I'll talk about later in the semester. I'll also use the convention of capitalizing `sig` names, just like we tend to capitalize class names in languages like Java or Python. 

We've also given every `Student` an integer field, containing the number of WRIT-designated courses they've taken. The `one` keyword means that the value must always be present -- no nulls allowed! Note that we _haven't_ added a field for the student's name, or their age, or their ID number. Why not? Because we don't need that information to talk about whether a set of courses suffices to graduate. Best to leave that out until our model really needs it; this is called an _abstraction choice_, and it's something we'll come back to almost every day in this course.

So far all we have is a number of WRIT courses taken, but this is enough to build a tiny requirements-checker. Let's ask Forge to find us situations where a student can potentially graduate:

```
run {
    some s: Student | s.numberWRIT >= 2
}
```

Let's break this down. 

#### Quantifiers (`some` and `all`)

Since constraints describe what a desirable instance looks like, it makes sense that we might want to identify a particular object in the instance, or say that a constraint holds for _every_ object. These are analogous to operators like `any` and `all` in Python. 

The constraint inside the `run` command says that some `Student` (named `s`) exists who has taken two or more WRIT courses. Instances without any students, or where every student has taken fewer than two WRIT courses, would be excluded by this constraint. If we had wanted to say that _every_ student had that many WRIT courses, we'd have used `all` instead of `some`.

#### Integers, Inequalities, and Arithmetic (Briefly)

We'll talk more about integers in Forge soon. For now, notice we can use inequalities in constraints. We won't need arithmetic in this model (at least, not yet), but you get that too in Forge. 

**WARNING**: Arithmetic in Forge uses a special syntax. Don't use `+`, `-`, and so on; instead, use `add`, `subtract`, etc. If you try to use `+` you may get an unexpected error message! 

You can find the full documentation for arithmetic [here](https://github.com/tnelson/Forge/wiki/Integers). There's a lot there, and we'll get to it in time.


#### Running

The `run` command tells Forge to search for an instance satisfying the given constraints. When we click Run, Forge solves the constraint and produces a satisfying instance, which it visualizes in a new browser window.

Notice what just happened. We didn't tell Forge _how_ to find that instance. We just said what we wanted, and Forge performed some kind of search to find it. So far the objects are simple, and the constraints basic, but hopefully the power of the idea is coming into focus. 

#### Something I wonder...

Maybe you notice something else. (If you don't, click the "Next" button a few times.) Do any students seem to violate the constraints? If so, why might this be?


#### The Type Hierarchy: `abstract` and `extends`

In order to represent the more complex requirements that individual concentrations have, we'll need something more than just a course count. Let's add a notion of courses to our model. 

```
abstract sig Course {}
sig Intermediate extends Course {}
sig Advanced extends Course {}
```

An `abstract sig` is just like an abstract class: any object of that `sig` must belong to one of the `sig`'s children. This means that any `Course` needs to be either `Intermediate` or `Advanced` course -- at least according to our model so far. 

#### Singleton Objects: `one`

If we wanted to tell the model about the existence of specific courses, we'd use the `one` annotation to create _singleton objects_: these `sig`s correspond to classes that only ever have one corresponding object:

```
one sig CSCI1710 extends Advanced {}
one sig CSCI0320 extends Intermediate {}
one sig APMA1650 extends Intermediate {}
```

#### Function Fields

Let's use our new concept of courses to enrich the student class. We'll keep track of which courses each student has taken by modeling their transcript:

```
abstract sig Grade {}
one sig A, B, C extends Grade {}
sig Student {
    numWRIT: one Int,
    transcript: pfunc Course -> Grade
}
```

Think of `pfunc` fields as akin to a `HashMap` in Java or a `dict` in Python: it maps keys to values, but needn't contain a value for every possible key. (The keyword `pfunc` is short for "partial function"). I've left out `S` and `S_DIST` to keep the model simple, but we can add them later if we want. Similarly, I've left out `NC` not only because I don't like them, but because, for now anyway, an `NC` is indistinguishable from not taking the course at all.

### Helper Predicates (`pred`)

Now that we have transcripts, we can write more complex requirements for graduation. Let's say that everybody needs to take 1710 to graduate! 

```
run {
    some s: Student | {
        s.numWRIT >= 2
        s.transcript[CSCI1710] = A or
          s.transcript[CSCI1710] = B or
          s.transcript[CSCI1710] = C 
        
    }
}
```

That's a bit unwieldy, isn't it? Fortunately, like in other languages, we can make helpers:

```
pred passingGrade[g: Grade] {
    g = A or g = B or g = C
}
```

A predicate (`pred`) in Forge is a helper for building constraints. We can use it in our `run` command to keep our constraints understandable:

```
run {
    some s: Student | {
        s.numWRIT >= 2
        passingGrade[s.transcript[CSCI1710]]
    }
}
```

Better, but I still don't like the fact that the constraints are about one specific student. Let's pull the graduation requirements out into their own predicate:

```
pred canGraduate[s: Student] {
    numberWrit >= 2
    passingGrade[s.transcript[CSCI1710]]
}
run {
    some s: Student | canGraduate[s]    
}
```

Much cleaner! If we click Run, we get a somewhat more complex instance. But it still satisfies all the constraints we gave Forge. 

Something to notice: the instance contains all the singleton objects (`one sig`s) we declared, but it also contains other objects! This is because Forge allows other objects to exist, up to a user-specified bound. Why is this valuable? Because it lets us more easily see the consequences of what we write: what would happen if, say, students just needed to take _any_ advanced course?

## Interlude: What are we missing?

Now that we've got the basics down, let's turn the classroom around. **You** tell **me** about concentration requirements that you've found complex or confusing! Do you foresee problems with representing those requirements in the current model?

This is also our in-class exercise for the day. While I'll be asking for contributions during class, please fill this out during the interlude:

[Exercise](https://forms.gle/1wn8uBmHdXZF7z4u5)

It will be useful to separate out which weaknesses are just "things we haven't represented yet" versus "things that will actively be tough to add, given choices we've already made".

Keep your answers in mind for next time; we'll pick up there.
