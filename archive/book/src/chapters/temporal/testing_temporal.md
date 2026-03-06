
# Validation in a Temporal Setting

We had previously discussed some [methodology for testing](../validation/validating_events.md). Now that we've started using Temporal Forge and begun modeling more robust systems, we should revisit the topic of validation. 

We had two principles to follow before:
* Principle 1: Are you testing the _model_, or the _system_? 
* Principle 2: Test both Inclusion and Exclusion.

Now we'll add 2 more considerations. 

## Principle 3: What's the Domain? What's the System? 

Systems don't run in isolation: there's usually an external environment that the system influences and is influenced by. Sometimes (but not always) this division is straightforward. In a model of networks, one might see:
* connectivity, packets, queues, etc. as the _domain model_; and 
* forwarding policies, router behavior, etc. as the _system_.

When we're writing a model, it's useful to know when we're talking about the _system_, and when we're talking about the _domain_ that the system is operating on. Let's look at the [Peterson lock](../temporal/fixing_lock_temporal.md) in this light.

* **The domain has a set of behaviors it can perform.** In this example, the threads represent the domain: programs running concurrently. As yet, there's no restriction on how the threads behave; the set of behaviors is enormous.
* **The system restricts that set of behaviors.** In this example, the Peterson lock is the system. Usually the system functions by putting limits and structure on otherwise unfettered behavior. (E.g., without a locking algorithm in place, threads would still run! They just might violate mutual exclusion.)
* Because we usually have goals about how, exactly, the system constrains the domain, we often state **requirements** (i.e., properties about the system) in terms of how the domain behaves in the system's presence.
* The domain has some state $D$, and the system has some state $S$. The domain cannot always "see" everything in $S$, and the system cannot always directly affect everything $D$. The variables on which they communicate (that is, $S \cap D$) are called the **interface**. We'll strive to phrase our requirements for the system in terms of $D$&mdash;in terms of what can be observed outside the details of the system. (Of course, our **validation tests** for the model itself may refer to whatever state is needed.)



<!-- When you add something to a model, it's good to have a rough sense of where it comes from. E.g., we added a `polite` field to turn our original lock into the Peterson lock. Is that state Is a piece of state visible in the domain?  of the domain, part of the system, or both? Does it represent an internal system state, which should probably not be involved in a requirement, but perhaps should be checked in model validation?

~~~admonish note title="Have we been disciplined about this so far?"
No we have not! And we may be about to encounter some problems because of that. 
~~~-->

## Principle 2: What Can Happen?

Ask what behaviors might be important in the domain, but not necessarily always happen. These are sometimes referred to as _optional predicates_, because they may or may not hold. In real life, here are some optional predicates:
* we have class today;
* it's raining today; 
* homework is due today; etc. 

**Exercise:** What are some optional predicates about the domain in our locking algorithm model? 

<details>
<summary>Think, then click!</summary>

We might see, but won't necessarily always see:
* different sequences of the threads taking steps forward;
* threads that are both simultaneously interested;
* threads that are uninterested; 
* etc.

As the model includes more domain complexity, the set of optional predicates grows. 

</details>

Notice that we wrote actual tests to confirm when these behaviors could (or couldn't) happen.

~~~admonish note title="For Next Time"
We'll consider questions of atomicity (how granular should transitions be?), and model a different variation of this lock.
~~~

