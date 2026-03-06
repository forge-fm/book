# Obligations and The Past

~~~admonish hint title="Temporal Forge Reminders"
* Remember the definition of "configuration": the value of all relations that aren't marked `var`. Thus, if you click the Sterling button that asks for a _new configuration_, the solver will always find a new trace that varies on one or more of _those_ relations. 
* _Do not_ try to use `example` in temporal mode. In fact, it's disabled; you'll get an error message. For reasons we'll get to soon (when we talk about how Forge works) `example` and `inst` both constrain _all states_ in temporal mode, and so an example will prevent anything it binds from ever changing in the trace. This can still be useful for optimization, but isn't so great if you're trying to write an example where things change over time. Start using `assert` more often!
~~~

<!-- 

The in-class exercise is [here](https://docs.google.com/forms/d/e/1FAIpQLSemtfAG44sxqkRSS4imTcGC1LVwcHgJWOrgrHp3wXyLbuMAZw/viewform?usp=sf_link). The livecode is the same model we've been working on: the [locking algorithm](./mutex_temporal.frg), and the (new) [traffic lights example](./traffic.frg). -->

~~~admonish note title="Temporal Forge Documentation"
Consult the [Forge documentation](https://csci1710.github.io/forge-documentation/electrum/electrum-overview.html) if you want further clarification on temporal operators.
~~~

Suppose we've written a model where `stopped` and `green_light` are predicates that express our car is stopped, and the light is green. Now, maybe we want to write a constraint like, at the current moment in time, it's true that:
* the light must eventually turn green; and 
* the `stopped` predicate must hold true until the light turns green. 

We can write the first easily enough: `eventually green`. But what about the second? We might initially think about writing something like: `always {not green implies stopped}`. But this doesn't quite express what we want. 

**Exercise:** Why not?

<details>
<summary>Think, then click!</summary>

The formula `always {not green implies stopped}` says that at any single moment in time, if the light isn't green, our car is stopped. This isn't the same as "the `stopped` predicate holds until the light turns green". For one thing, the latter applies _until_ `green` happens, and after that there is no obligation remaining on `stopped` for the rest of the trace. 

</details>

---

In LTL, the `until` operator can be used to express a stronger sort of `eventually`. If I write `stopped until green_light`, it encodes the meaning above. This operator is a great way to phrase obligations that might hold only until some releasing condition occurs.

~~~admonish tip title="Strong vs. Weak Until"
Some logics include a "weak" `until` operator that doesn't actually enforce that the right-hand side ever holds, and so the left-hand side can just be true forever. But, for consistency with industrial specification languages (at least, most of those we're familiar with) Forge's `until` is "strong": it requires the right-hand side hold _eventually_.
~~~

~~~admonish warning title="The car doesn't have to move!"
The `until` operator doesn't prevent its _left_ side from being true after its right side is. E.g., `stopped until green_light` doesn't mean that the car has to move immediately (or indeed, ever) once the light is green. It just means that the light eventually turns green, and the car can't move until then.
~~~

## The Past (Rarely Used, but Sometimes Useful)

Forge also includes temporal operators corresponding to the _past_. This isn't standard in some LTL tools, but we include it for convenience. It turns out that past-time operators don't increase the expressive power of the language, but they do make it much easier and sometimes _much_ more concise to write some constraints. Here are some examples:

### `prev_state init` 

This means that the _previous_ state satisfied the initial-state predicate. **Beware**: traces are infinite in the forward direction, but _not_ infinite in the backward direction. For any subformula `myPredicate`, `prev_state myPredicate` is _false_ if the current state is the first state of the trace.

### Past-Time `always` and `eventually`: `historically` and `once`

We can use `historically` to mean that something held in all past states and in the current one. I can write "I've never been skydiving" as `historically {not skydiving[Tim]}`. But if I go skydiving tomorrow, that formula won't be true tomorrow.

Likewise, `once` means that there was a time in the past (or currently) where something held. If I've been skydiving at all in my life, or if I'm skydiving right now, I could write `once {skydiving[Tim]}`. 