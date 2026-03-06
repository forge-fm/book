# Overview

Forge is a tool (and a set of languages) that allows us to define models of systems and explore instances of those models. But **_what does that mean_**? Let's break it down:

## Systems

A **system** can be generally thought of as a particular way that various entities interact.  A system isn't necessarily a _computer_ system, although it can be. For example:
- The game of baseball is a system involving players, a ball, a field and bases, etc. along with rules that govern how those things interact with each other.
- Family trees are a system where there are people, and rules that express how they are related to each other.
- A cryptographic protocol is a system where there are parties, messages, cryptographic primitives, and rules that govern how messages can be encrypted, decrypted, sent, and received.
- Binary search trees are a system where there are nodes, values, connections between nodes, and rules that govern how nodes can be created, removed, and positioned relative to one another.
_There is no limit to the type or complexity of a system that we can discuss_, although different tools and techniques are useful for working with and able to express different kinds of systems.

---

## Models

A **model** is a _representation_ of a system that faithfully includes some but usually not all of the system's complexity. There are many different ways to model a system, all of which have different advantages and disadvantages. Think about what a car company does before it produces a new car design. Among other things, it creates multiple models. E.g.,
* it models the car in some computer-aided design tool; and then
* creates a physical model of the car, perhaps with clay, for testing in wind tunnels etc.

There may be many different models of a system, all of them focused on something different, and all of them useful for something. (As the statisticians say, "all models are wrong, but some models are useful".)

Models define a notion of what kinds of things exist in the system and (some of) the "rules" governing the system. In a well-crafted model, we can explore what scenarios are possible in the system, which gives us insight and the ability to reason about the system itself---within the bounds of what the model expresses. 

### Example: Friends

If we wanted to model a group of friends, we might define our model to have the following structure:

- There's a type of object, `Person`, in the system.
- Each `Person` has a `bestFriend` field, possibly containing a `Person`.
- Each `Person` has a best friend. 

These three items correspond to three different concepts in Forge: defining types (`sig`s), defining fields that those types have, and defining constraints. 

### A Note on Imperfect Representations

It is very difficult to fully model some systems. That being said, _we don't need to fully model a system for the model to be useful_. We can simplify or omit concepts as needed to approximate the system while preserving the fundamentals that we're interested in.

We can see this principle applied in the car-manufacturing example above. You could use a solid clay model of a car to accurately determine the car's aerodynamics in a wind tunnel, but you'd have a hard time exploring how the doors of the car operate or how any of the interior parts work. What you can explore is limited by how the system is modeled. If all you care about is exploring the aerodynamic profile of a car, then we can safely abstract out the internals of the car and focus on the shape. 

Likewise, in our "friend group" system example, we don't have to fully describe a `Person` in our model, we just have to describe the relevant properties of a `Person`. We abstract the idea of "friendship," combining all types of friends (best friend, acquaintance, etc.) into a single concept of "friend." We omit from our model the concept of a `Person`'s dietary restrictions and myriad other things. These are all choices that affect the scope of our model. If we wanted to distinguish between types of friends, or examine familial relationships as well, we would have to expand the model to include those concepts---and we could!

Learning how to model a system is a key skill for engineers; abstraction is one of our main tools in Computer Science, and modeling lies at the heart of abstraction.

---

## Instances

An **instance** is a concrete scenario that abides by the rules of a model, containing specific objects (_atoms_) and their relationships with each other.

~~~admonish warning title="Analogy to OOP" 
We can draw a very rough analogy to object-oriented programming here. We might say:
- a `sig` definition, along with its fields, is like a class; and
- atoms within an instance of a model are like objects (since each atom belongs to some `sig`).
This is a useful analogy! 

Just remember that **it is an analogy and not the exact truth**. There are important differences. For example, you might remember the heap from Java or some other language, and wonder how atoms (analogously to objects) are created or garbage-collected. But _there is no heap_ in Forge instances, only a set of atoms for each `sig`. Similarly, you might wonder how a Forge model executes. But it doesn't! A Forge model defines a set of possible instances, which the tool searches for. 
~~~

Each instance shows a single way that the constraints in the model can be satisfied. Here are two example instances, described in English:
* There are two people, `Tim` and `Nim`. `Tim` has `Nim` as a best friend, and `Nim` has `Tim` as a best friend. 
* There is one person, `Nim`, who has `Nim` as a best friend. 
* There are no people. 

Why do the second and third instance get produced? Because all we told Forge to enforce was:
* Each `Person` must have a best friend.

If there are no people, there is nobody to be obligated to have friends. The empty instance satisfies this constraint.

## Satisfiability and Unsatisfiability 

Semi-formally, we'll say that a model is _satisfied_ by an instance if:
* it contains sets of atoms for every `sig` in the model; 
* each atom has fields appropriate to its `sig`; and 
* the instance obeys all of the model's constraints. 

A model is _satisfiable_ if there exists some satisfying instance for it. A model is _unsatisfiable_ if there is no instance that satisfies it. 

~~~admonish example title="Another example"
If you play Sudoku, you might imagine modeling the game as a set of constraints. Then add:
* constraints that express the starting puzzle; and 
* a constraint expressing the need to populate every square in the board.

If the starting puzzle has a solution, the model will be satisfiable. If there is no solution, it will be unsatisfiable.
~~~

## Next Steps

In Forge, we use [`sig`s](./sigs.md) to define the types that exist in a system, and [constraints](./constraints.md) to define the "rules" of the system.
