# Temporal Forge Overview

Temporal mode extends Forge with temporal operators to ease specification and checking of dynamic systems. This mode draws heavily on the [Electrum work](http://haslab.github.io/Electrum/) by INESC TEC and ONERA, and the newer Alloy 6 version, but there are (slight) differences.

To use Temporal Forge, just use `#lang forge/temporal`. This will cause a number of changes in how Forge processes your models, the largest one being that it will now always search for **lasso traces** (see below) rather than arbitrary instances. The maximum length of the trace is given by `option max_tracelength <k>` and defaults to `5`. The minimum length of the trace is given by `option min_tracelength <k>` and defaults to `1`. 

~~~admonish info title="Using Minimum Trace Length"
The temporal solver works by iterative deepening: try length 1, then length 2, ... and so _sometimes_ (not always) a longer minimum trace length can speed up the process.
~~~

## Variable state (`var`)

Electrum mode allows `var` annotations to be placed on `sig` and field definitions. Such an annotation indicates that the contents of the corresponding relation may vary over time. Any sigs or fields that are not declared `var` will _not_ vary over time.

~~~admonish warning title="Importance of `var`"
If no sigs or fields are declared `var`, the temporal solver cannot change anything from state to state.
~~~

~~~admonish example title="`var` declarations"
Writing `sig Vertex { var edges: set Vertex }` defines a directed graph whose edge relation may vary. 

Writing `var sig Student {}` denotes that the set of students need not remain constant.
~~~

## Temporal Mode Semantics (Informally)

When the temporal solver is enabled, instances are always traces, and a trace is an **infinite** object, containing a state for every natural number $k$. However, the solver underlying Forge needs to finitize the problem in order to solve it. The solution to this, given a finite state-space, is to invoke the Pigeonhole Principle and seek traces that end in a loop: "lassos".

~~~admonish warning title="Lassos must loop back!"
If your system needs more steps before it loops back than the maximum trace length (e.g., an integer counter that overflows with a small trace length), Forge may tell you that there are no traces. Always pay attention to your `max_tracelength` option, and be convinced that it is sufficient to include the lassos you're interested in.
~~~

Temporal formulas and expressions are always evaluated with respect to a state index. At the top level of any formula, the index is $0$ (the first state of the trace). Temporal operators either change or "fan out" across multiple state indexes to let you express things like:
* "in the next state, ..." (add 1 to the state index)
* at some point in the future, ... (search for `some` state index)
* at all points in the future, ... (check `all` future indexes)
* ...

## Added relational operators: priming

Electrum mode adds one relational operator: priming (`'`). Any relational expression that is primed implicitly means "this expression **in the next state**". Thus, you can use priming to concisely write transition effects. 

~~~admonish example title="Priming"
Writing `cookies' in cookies` would mean that in every transition, the set of `cookies` never grows over time (will either shrink or remain the same).
~~~

## Added formula operators

Electrum mode adds a number of formula operators, corresponding to those present in Linear Temporal Logic (LTL) and Past-Time Linear Temporal Logic.

### Traditional LTL (future time)

#### Next State

- `next_state <fmla>` is true in a state `i` if and only if: `fmla` holds in state `i+1`.

~~~admonish example title="next_state"
In a model with `one sig Nim { var cookies: set Cookie }`, writing `next_state no Nim.cookies` expresses the sad fact that, in the next state, Nim has no cookies.
~~~

~~~admonish warning title="Let and temporal operators" 
Don't try to write something like:
```
let oldCount = Counter.count | 
    next_state Counter.count = add[oldCount, 1]
```

The `let` construct is implemented with substitution, and so the above will be rewritten to:
```
next_state Counter.count = add[Counter.count, 1]
```
which expresses that, in the next state, the counter must be one greater than itself. This will be unsatisfiable.
~~~

#### Always (now and in the future)

- `always <fmla>` is true in a state `i` if and only if: `fmla` holds in every state `>=i`.

~~~admonish example title="always"
In a model with `one sig Nim { var cookies: set Cookie }`, writing `always no Nim.cookies` expresses an alarming universal truth: from now on, Nim will never have any cookies.

Of course, operators like `always` can be used inside other operators. So this lamentable destiny might be avoided. E.g., `not always no Nim.cookies` would mean the reverse: at some point, Nim will in fact have cookies.
~~~

#### Eventually (now or sometime in the future)

- `eventually <fmla>` is true in a state `i` if and only if: `fmla` holds in some state `>=i`.

~~~admonish example title="eventually"
In a model with `one sig Nim { var cookies: set Cookie }`, writing `eventually no Nim.cookies` expresses that at some point either now or in the future, Nim will lack cookies. Before and after that point, nothing prevents Nim from acquiring cookies.
~~~

#### Until and Release (obligations)

- `<fmla-a> until <fmla-b>` is true in a state `i` if and only if: `fmla-b` holds in some state `j>=i` and `fmla-a` holds in all states `k` where `i <= k < j`. Note that the obligation to see `fmla-a` ceases in the state where `fmla-b` holds.

~~~admonish example title="until"
In a model with `one sig Nim { var cookies: set Cookie }`, writing `no Nim.cookies until some Nim.vegetables` expresses that, _starting at this point in time_, Nim must have no cookies until they also have vegetables. Once Nim obtains vegetables (including at this point in time), the obligation ends (and thus after that point Nim may have only cookies but no vegetables).
~~~

A natural question to ask is: what happens if `fmla-b` holds at multiple points in the future? However, this turns out not to matter: the definition says that the `until` formula is true in the current state if `fmla-b` holds at **some** point in the future (and `fmla-a` holds until then).

There is an alternative way to express obligations, which we won't use much:

- `<fmla-a> releases <fmla-b>` is true in a state `i` if and only if: `fmla-a` holds in some state `j>=i` and `fmla-b` holds in all states `k` where `i <= k <= j`, or `fmla-a` never occurs in a later state and `fmla-b` holds forever after. Note that the intuitive role of the two formulas is reversed between `until` and `releases`, and that, unlike `until`, the obligation extends to the state where `fmla-a` holds.

### Past-time LTL 

_Past-time_ operators are useful for concisely expressing some constraints. They don't add more expressive power to the temporal language, but they do sometimes make it easier to avoid adding state, etc.

#### Previous State

- `prev_state <fmla>` is true in a state `i` if and only if: `fmla` holds in state `i-1`. 

~~~admonish warning title="There is nothing before the first state"
The formula `prev_state <fmla>` is canonically false if `i=0`, since there is no prior state. This holds regardless of what `<fmla>` contains; `prev_state` asserts the existence of a prior state.
~~~

#### Historically (always in the past)

- `historically <fmla>` is true in a state `i` if and only if: `fmla` holds in every state `<=i`.

#### Once (at some point in the past)

- `once <fmla>` is true in a state `i` if and only if: `fmla` holds in some state `<=i`.

## Note for Alloy Users

Alloy 6 and Electrum use the keywords `after` and `before` where Forge uses `next_state` and `prev_state`. We changed Forge to use these (admittedly more verbose) keywords in the hopes they are more clear. For example, `after` sounds like it could be a binary operator; in English, we might say "turn left after 3 stops". Also, `next_state` is definitely a formula about the following state whereas `after` does not communicate the same sense of immediacy.
