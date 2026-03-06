# Running

There are two primary ways of running your spec. You can either as Forge to show you instances that satisfy a predicate you wrote with the run command, or ask Forge to look for counterexamples to a predicate you wrote with the check command.

#### Run

The run command can be used in a few different ways, show below:

```
<run-name>: run <pred> for <bounds>
<run-name>: run { <expr> } for <bounds>
```

Note that the run-name is optional to provide, but is helpful to distinguish what different run commands are showing.

When using the run command, Forge will display possible worlds (instances) where the predicates or expressions you specified evaluate to true, within the given bounds. Instances are displayed in [Sterling](https://github.com/tnelson/Forge/wiki/Sterling-Visualizer) If no such instances are found, "UNSAT" is displayed.

When no more satisfying instances can be found, Sterling displays "No more instances found".

#### Check

The check command is used to ask Forge to look for counterexamples to a given set of predicates, i.e. instances where the predicate or expression evaluates to false. The syntax is the same as for the run command, just with the keyword `check` instead:

```
<check-name>: check <pred> for <bounds>
<check-name>: check { <expr> } for <bounds>
```

If no counterexamples are found, Sterling displays "No counterexamples found. Assertion may be valid". When no more counterexamples can be found, Sterling displays "No more instances found".

```admonish warning title="Common Mistake!"
Unless defined in the run/test statement, predicates don't take effect!
```
