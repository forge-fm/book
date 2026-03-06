# 9: The Problem With Traces

###### tags: `Tag(sp22)`

* Forge 2 is out!
* Curiosity modeling will be out on Friday. Think of this like a miniature final project: you'll use Forge to model something you're interested in, on a relatively small scale. **Starting finding parters now, and thinking about ideas.** If you don't know anyone in the class, we'll provide some help. 
* Remember Tim's hours (Monday 11am).


## Common "Forge Isn't Updating" Issues

### Forge terminating without opening Sterling

Make sure you have Java installed, and that it's on your path (can you run `java` from a terminal?) If Java isn't installed, Forge `run` commands can't start the solver and so Sterling won't open.

### VSCode not running Forge when you click run

Try running `racket` directly on your `.frg` file in a terminal (from outside VSCode). E.g., I might type `racket feb14.frg`. 


### Can't even run Racket from the terminal 

If you still can't run Racket from your terminal, make sure you have Racket installed. If you have Racket installed, find where the installation is on your computer, and use the absolute path to the `racket` (MacOS/Linux) or `Racket.exe` (Windows) executable.

* On a Mac, Racket is usually installed somewhere in the `/Applications/` folder, and the executable is inside a `bin` subdirectory of the Racket installation. 
* On Windows, install locations vary a bit more but if you've got a shortcut to `Racket` or `DrRacket` in your start menu, you can right click and go to its location. Run `Racket.exe` and give the full path, e.g., `C:\Program Files\Racket\Racket.exe feb14.frg`. 

If the absolute path has spaces in it, you may need to escape them. For example, on Windows, If I open `cmd` and type `C:\Users\Tim>C:\Program Files\Racket\Racket.exe`, I get an error saying that `C:\Program` is not recognized as an internal or external command, operable program or batch file. That's because of the space. Instead (on Windows) wrap the whole thing in double-quotes. On MacOS, you can also use a backslash before the space.

### Forge updates: "Cannot update linked packages"

If `raco pkg update forge` gives you "raco pkg update: cannot update linked packages; except with a replacement package source" error, the problem is often that the installation `raco` knows about was built from Git, not Racket's package system. If you see follow-up info like

```
package name: forge
package source: /Users/Tim/repos/Forge/forge
```

or some other source path with a double `forge` in it, it's likely that `raco` is still pointing to a Git-installed version. You have two options:

* Stay with the Git install: instead of running `raco pkg update`, instead `cd` to the repository and `git pull`; you should see new commits. Then `raco setup forge`. Crucially, do not run `raco pkg install forge` (since the added `forge` at the end invokes the package system).
* Switch to the package system: remove the old Git version with `raco pkg remove forge`, and then reinstall with `raco pkg install forge`. 

If these don't work, you can get additional information to share via `raco pkg show forge`.

### Missing module path (and related errors from Racket)

Make sure the first line in your model file is a `#lang` annotation. If you're running a model for a homework or lab, try to use the header you're given (and plug in your anonymous grading ID). E.g., 

```
#lang forge/bsl "forge2/river_crossing" "1234567890"
```

The problem label helps with our grading system. The anonymous ID helps us correlate error logging with your homework submission, so that we can spot and hopefully correct major issues. We use your anonymous ID here to help keep the grading system unbiased.


## One More Way To Test

We've seen `test expect` blocks. But Forge actually provides [another way to test](https://github.com/tnelson/Forge/wiki/Testing): concrete `example`s. Where a `test` is usually about checking satisfiability or unsatisfiability of some set of constraints, an `example` is about whether a _specific_ instance satisfies a given predicate. 

Since Forge's essential function involves checking whether an instance satisfies constraints, this style of test can be extremely useful for checking that (e.g.) small helper predicates do what you expect.

Why use `example` at all? A couple of reasons:
* It is often much more convenient (once you get past the odd syntax) than adding `one sig`s or `some` quantification for every object in the instance, provided you're trying to describe an _instance_ rather than a property that defines a set of them.
* Because of how it's compiled, an `example` can often be much faster than a constraint-based approach. 

You may be wondering whether there's a way to leverage that same speedup in a `run` command. Yes, there is! But for now, let's get used to the syntax just for writing examples. Here are some, well, examples:

```alloy
-- Do not try to write, e.g., `State0.board = ...
example emptyBoardXturn is {some s: State | XTurn[s]} for {
  State = `State0
  no board
}
```

Here, we've said that there is one state in the instance, and its `board` field has no entries. **NOTE**: we didn't write `State0.board` on the left side of these statements; Forge's example syntax, for the moment, requires us to describe "one big field" for all states.

```alloy
-- You need to define all the sigs that you'll use values from
example xMiddleOturn is {some s: State | OTurn[s]} for {
  State = `State0
  Player = `X0 + `O0
  X = `X0
  O = `O0
  board = `State0 -> 1 -> 1 -> `X0
}

```

You can see the "one big field" notation above: there's one entry, but we have to say whose entry it is as part of the definition.

This syntax is admittedly strange, but it will turn out to be useful next week, when we start using more in Forge.


## Proving Preservation Inductively

How can we prove that it's impossible for the system to reach a `cheating` state _without_ generating traces of ever-increasing length?

This might not be immediately obvious. After all, it's not as simple as asking Forge to run `all s: State | not cheating[s]`. (Why not?)

<details>
<summary>Think, then click!</summary>
Because that would just be asking Forge to find us instances full of good, non-cheating states. Really, we want a sort of higher-level `all`, something that says: "for all **games**, it's impossible for the game to contain a cheating state".
</details>

This simple example illustrates a **central challenge in software and hardware verification**. Given a discrete-event model of a system, how can we check whether all reachable states satisfy some property? In your other courses, you might have heard properties like this called _invariants_, as in:  "Does my `LinkedList` class maintain the invariant that the last node's `next` pointer is null?""


One way to solve the problem _without_ the limitation of bounded-length traces goes something like this:
* Ask Forge whether any starting states are cheating states. If not, then at least we know that games of length 0 obey our invariant. (It's not much, but it's a start---and it's easy for Forge to check.)
* Ask Forge whether it's possible, in any non-cheating state, to transition to a cheating state. 
 
Consider what it means if both checks pass. We'd know that games of length $0$ cannot involve a cheating state. And since we know that non-cheating states can't transition to cheating states, games of length $1$ can't involve cheating either. And for the same reason, games of length $2$ can't involve cheating, nor games of length $3$, and so on.

How do we write this in Forge?

```alloy
test expect {
  noCheatingAtStart: {
    wellformed
    some s: State | init[s] and cheating[s]
  } is unsat
  noCheatingTransitions: {
    wellformed
    some pre, post: State | 
    some row, col: Int, p: Player | {
      not cheating[pre]
      move[pre, row, col, p, post]
      cheating[post]
    }
  } is unsat
}
```

If both of these pass, we've just shown that cheating states are impossible to reach via valid moves of the game.

Does this technique always work? Well, that's another lecture.







