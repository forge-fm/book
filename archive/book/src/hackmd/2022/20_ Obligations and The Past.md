# 20: Obligations and The Past

###### tags: `Tag(sp22)`

* The first Electrum-mode homework is out! Ask questions early, and we'll try to answer or clarify as needed. 
* Remember the definition of "configuration": the value of all relations that aren't marked `var`. Thus, if you click the Sterling button that asks for a _new_ configuration, the solver will always find a new trace that varies on one or more of those relations.
* TA applications are open, and close on Wednesday! 
* The Electrum lab is/was the last formal lab. We'll have "col-labs" for some projects, but they won't be new deliverables to check off.
* Final-project presentations will be roughly from May 13th through May 18th---if you need to travel, and prefer to present earlier, early slots are possible. These are likely to be over Zoom, and public. 
* Our official finals date is the 17th, so I suggest **graduating seniors** try to get slots before that, so I can get your grades in on time.

Looking ahead, we'll spend a couple more days on LTL (at least). One of those days, I want to model the temporal logic in the same way we modeled boolean logic, so we can play with the definitions.

After that, we'll start talking technically about how Forge works. Many of you have been curious, and it will set you up well for the homework after Spring break, where you'll be building your own solver.

## Back to LTL: Obligation

The `until` operator can be used to express a stronger sort of `eventually`. If I write `stopped until green_light`, it means _two_ things:
* the light eventually turns green; and
* the `stopped` predicate holds until the light turns green.

This operator is a great way to phrase obligations in properties and constraints. 

Some logics include a "weak" `until` operator that doesn't actually enforce that the right-hand side ever holds, and so the left-hand side can just be true forever. But, for consistency with industrial languages, Forge's `until` is "strong", so it requires the right-hand side hold eventually.

## Priming: "next state" expressions

You can talk about the value of an expression _in the next state_ by appending `'` to the expression. So writing `flags'` means the value of the flags relation in the state after this one.

## The Past (Rarely Used, but Sometimes Useful)

You won't need to use this often, but Forge also includes temporal operators corresponding to the _past_. E.g., you can say:

`prev_state init` 

to mean that the _previous_ state satisfied the initial-state predicate. But beware: traces are infinite in the forward direction, but _not_ infinite in the backward direction. For any subformula `F`, `prev_state F` is false if the current state is the first state of the trace.

There are also analogues to `always` and `eventually` in the past: `historically` and `once`. 

You've seen some of these in lab, or in the documentation that the lab refers you to. We won't use all these operators in 1710.

## Modeling Deadlock

A deadlock state is one where _no_ outgoing transitions are possible. How can we write a test in temporal mode that tries to find a reachable deadlock state? There are two challenges:

* How do we phrase the constraint, in terms of the transition predicates we have to work with? 
* How do we even allow Forge to find a deadlock, given that temporal mode *only* ever finds lasso traces? (A deadlock in a lasso trace is impossible, since a deadlock prevents progress!)

Let's solve the second challenge first, since it's more foundational.

### Finding Deadlocks Via Lassos

We could prevent this issue by allowing a `doNothing` transition from every state. Then from Forge's perspective there's no "deadlock", and a lasso trace can be found. 

But this fix causes new problems. If we allow a `doNothing` transition to happen _anywhere_, our liveness property is definitely destroyed, even if we were modeling a smarter algorithm. So we need to reduce the power of `doNothing` somehow.

Put another way: we started with an _overconstraint_ bug: if only lassos can be found, then we can't find a trace exhibiting deadlock. Adding `doNothing` fixes the overconstraint but adds a new _underconstraint_, because we'll get a lot of garbage traces where the system can just pause arbitrarily (while the trace continues).

We'll figure out how to fix this next time.



