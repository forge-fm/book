# Options

Forge has a number of options that affect how it functions and how its solver is configured. They all have the same form: `option <key> <value>`. **Settings are case sensitive.** The available setting keys are:

* `verbose`: governs the amount of information provided in the REPL. `1` is standard; `0` will omit statistical information (useful for test suites); `10` will print exceedingly verbose debugging information. Values between `1` and `10` gradually increase verbosity.
* `solver`: sets the solver used by Forge's worker process. The default is `SAT4J`, a Java-based solver. Other solvers can be more performant, and produce different instance orderings, depending on model. The `MiniSatProver` solver will enable extraction of unsat cores. Support for native solvers varies by OS. Currently: 
  * MacOS (x64 and arm64 `.dylib`):
    * `MiniSat`, `MiniSatProver`, and `Glucose`
  * Linux (`.so`): 
    * `MiniSat`, `MiniSatProver`, and `Glucose`
  * Windows (`.dll`):
    * `MiniSatProver`
  * All: 
    * `"<path-to-solver>"`, which lets you run a solver of your own that accepts DIMACS input (see the section below for instructions). 
* `logtranslation`: controls how much of the translation from Forge to boolean logic is logged. The default is `0`; must be `1` or higher to extract unsatisfiable cores.
* `coregranularity`: controls how fine-grained an unsatisfiable core will be returned. Default is `0`. Suggested value is `1` if you want to see cores.
* `core_minimization`: controls whether cores are guaranteed minimal. Default is `off`. For minimal cores, use `rce`; `hybrid` is not guaranteed minimal but is often better than `off` while being faster than `rce`.
* `sb`: controls maximum size of symmetry-breaking predicate. `20` is default. Higher numbers increase Forge's ability to rule out equivalent instances, at a potential performance cost.
* `skolem_depth`: gives how many layers of universal quantifiers to Skolemize past. Default is `0`; to disable Skolemization, give `-1`.
* `engine_verbosity`: sets the Logger level used by Pardinus (default=0). The following table is current as of version 1.5.0 (when the option was added):
```
case 0 : return Level.OFF;
case 1 : return Level.SEVERE;
case 2 : return Level.WARNING;
case 3 : return Level.INFO;
case 4 : return Level.FINE;
case 5 : return Level.FINER;
case 6 : return Level.FINEST;
default : return Level.ALL;
```
* `run_sterling`: decides whether to use the Sterling visualizer. Default is `on`. To disable, give `off`. Alternatively, pass a string containing the file path of a visualizer script to auto-load it in Sterling.
* `sterling_port`: sets the port used by the Racket web-server that Sterling connects to. The default picks an unused ephemeral port.
* `test_keep`: controls Forge's behavior when running test suites. The default (`first`) will cause Forge to stop immediately on the first test failure. The only currently-supported alternative (`last`) will cause Forge to run all tests and print a report at the end; only the *final test failure* will remain open for use with Sterling.
* `problem_type`: used to enable `temporal_mode` for Alloy6-style LTL support. **This option is deprecated in favor of using `#lang forge/temporal` instead**, and may be removed in future versions.
* `no_overflow` (default: `false`): when set to `true`, enables the Pardinus/Kodkod backend's overflow protection. This will _exclude_ instances which satisfy the given problem only due to bitwidth overflow semantics. E.g., `Counter.x = add[2,2]` would not be satisfiable at bitwidth `3` with this option set to `true`, because `4` is greater than the maximum value available with 3 bits. 


~~~admonish warning title="Location matters!"

Options apply from the point they occur onward until either the file ends or the same setting is changed. For instance, only the second `run` command in this example will print verbose debugging information.

```
sig Node {edges: set Node}
run {}
option verbose 10
run {}
option verbose 1
run {}
```
~~~

## Custom Solvers 

Forge can use a solver of your choice to produce instances; this is most often used to experiment with the solver you build in the DPLL homework. There are a few factors to be aware of.

### Limitations

While the "Next" button will be enabled in Sterling, the custom solver functionlity will always return the _first_ instance found by the custom solver. There is also no support for unsatisfiable-core extraction; the custom solver will only report "unsat" for an unsatisfiable problem. 

### Instructions

To invoke a custom solver, provide a double-quoted filepath literal as the solver name:

```
option solver "<filepath-to-solver>"
```

Note that:
* the file must exist at the path specified;
* the file must be executable;
* the file must implement the DIMACS input/output format given in the DPLL assignment stencil;
* if the file is a script using a `#!` preamble, the preamble must point to the correct location. E.g., if the file is a Python script that begins with `#!/usr/bin/python3`, your Python 3 executable must reside at `/usr/bin/python3`. 

The solver engine doesn't return rich information in the case of failure. Should any of these conditions not be met, you'll see a generic Pardinus crash error. 

~~~admonish note="An aside for Windows users"
If you're using Windows directly (rather than the Linux subsystem), extensions like `.py` will not be treated as executable. It may be useful to create a batch file (`.bat` extension) that invokes your solver, and give that batch file as the path in `option solver` instead.
~~~

### Examples

If you want to create a batch script on MacOS or Linux, you might try something like this in a `run.sh` file: 

```
#!/bin/sh
python3 solver.py $1
```

On windows, you could try something like this, in a `run.bat` file:

```
@ECHO OFF
python3 solver.py %1
```

You might then invoke your solver via a `.frg` file like this:

```
#lang forge

-- MacOS or Linux:
option solver "./run.sh"

-- Windows:
-- option solver "./run.bat"


sig Node {edges: set Node}

test expect {
    s: {some edges} for 1 Node is sat
    u: {no edges 
        all n: Node | some n.edges} for exactly 1 Node is unsat
        
}

-- This will work, but will only ever show one instance:
--run {}
```

If your script can be executed directly, then you can replace `./run.sh` in the above with the path to your script, including filename. On Windows, you will only be able to reference `.bat` or `.exe` files in your Forge solver option.