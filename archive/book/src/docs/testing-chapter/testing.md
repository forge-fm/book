# Testing

Forge supports several different testing constructs:

- `example`, for expressing that specific instances should satisfy (or not satisfy) a predicate; 
- `assert`, for expressing that a specific predicate should be necessary or sufficient for another; and 
- `test expect`, an expressive and general form that can be somewhat more difficult to use.

If tests pass, they do not open the visualizer, making them well-suited for building test suites for your Forge models.

**Note on terminology**: we will sometimes refer to `assert` and (some) `test expect` tests as _property tests_. This is because they can be used to express sweeping expectations about predicates, rather than just the point-wise, single-instance expectations that `example` can. 

~~~admonish note title="Shared Context"
All the subsections below contain tests for the same small model of tic-tac-toe:

```
abstract sig Player {}
one sig X, O extends Player {}
sig Board { board: pfunc (Int -> Int) -> Player }
pred wellformed {
  all b: Board | all row, col: Int | {
    (row < 0 or row > 2 or col < 0 or col > 2) implies
      no b.board[row][col] 
  } 
}
```

~~~

## Examples

The `example` syntax lets you test whether a specific instance is satisfied by some predicate in your model. An `example` contains three parts:
* a name for the example;
* which predicate the instance should satisfy (or not satisfy); and 
* the instance itself. 

~~~admonish example title="Example"

This `example`, named `diagonalPasses`, expresses that a board where X has moved in the upper-left, middle, and lower-right squares (and `O` has made no moves at all) should satisfy the `wellformed` predicate:

```
example diagonalPasses is {wellformed} for {
  Board = `Board0
  X = `X0 
  O = `O0
  A = `A0
  B = `B0
  C = `C0
  `Board0.board = (0,0)->`X + (1,1)->`X + (2,2)->`X
}
```

Notice that the `example` needs to give a value for _all_ `sig`s and _all_ fields, even the `one sig`s. 
~~~

Examples are analogous to unit tests in Forge. Every example says that if the instance were passed to the predicate, the predicate would return true (or false). This means that examples are a great way to explore potential design choices and map out your intent when modeling.

~~~admonish warning title="Temporal Forge"
The `example` keyword is not supported in Temporal Forge. 
~~~

#### How do examples work?

An example passes if and only if the instance given is consistent with the predicate given. 

~~~admonish warning title="Total vs. partial instances"
If you leave a sig or field unbound in an `example`, Forge is free to assign that sig or field in any way to achieve consistency with the predicate. The consequence is that it is possible to write apparently contradictory examples that pass. E.g., in the above example, if we left out the binding for `board`:

```
example exampleYes is {wellformed} for {
  Board = `Board0
  X = `X0 
  O = `O0
  A = `A0
  B = `B0
  C = `C0  
}
example exampleNo is {not wellformed} for {
  Board = `Board0
  X = `X0 
  O = `O0
  A = `A0
  B = `B0
  C = `C0  
}
```
**Both** of these examples would pass vs. the `wellformed` predicate, because Forge can find values for the `board` field that either satisfy or dissatisfy the `wellformed` predicate. 
~~~


### Notes on Example Syntax

The block within the second pair of braces must always be a concrete instance. That is, a series of assignments for each sig and field to some set of tuples, defined over atom names. Atom names must be preceded by a backquote; this reinforces the idea that they are atoms in a specific instance, rather than names in the model. You will not be able to refer to these atoms in predicates and most other Forge syntax.

_Don't_ try to assign to the same field twice. If you want a field to contain multiple entries, use `+` instead. Remember that `=` in the context of an instance is _assignment_, not a constraint, and that most constraints won't work inside an instance.

Names of `sig`s may be used on the right-hand-side of an assignment only if the block has previously defined the value of that `sig`` exactly, allowing straightforward substitution.

## Assert

The `assert` syntax allows you to write tests in terms of _necessary_ and _sufficient_ properties for a predicate. 

~~~admonish example title="Assertions"

If we first define these two predicates:

```
pred fullFirstRow {some b: Board | b.board[0][0] = X and b.board[0][1] = X and b.board[0][2] = X}
pred someMoveTaken {some b: Board, row, col: Int | some b.board[row][col] }
```

we can then write two assertions:

```
assert fullFirstRow is sufficient for winning for 1 Board
assert someMoveTaken is necessary for winning for 1 Board
```

which should both pass, since:
* if `X` occupied the entire first row, it has won; and 
* if someone has won the game, there must be moves taken on the board.
~~~

Assertions also support universal quantification (i.e. `all`, but not `some`, `one`, `lone`, etc). For example, if you instead wrote the predicates:

~~~admonish example title="AssertionsQuant"
```
pred fullFirstRow[b : Board] {b.board[0][0] = X and b.board[0][1] = X and b.board[0][2] = X}
pred someMoveTaken[b : Board, row : Int, col : Int] {some b.board[row][col] }
```

You could write the assertions
```
assert all b : Board | fullFirstRow[b] is sufficient for winning for 1 Board
assert all b : Board, row, col : Int | someMoveTaken[b, row, col] is necessary for winning for 1 Board
```
~~~


Assertions are an excellent way to check and document your goals and assumptions about your model. In a more complex setting, we might write assertions that enforce:
* Dijkstra's algorithm doesn't terminate until the destination vertex has been reached; 
* for a game of chess to be won, a king must be in check; or
* someone must first be logged into Gmail to read their mail.

### Notes on Assert Syntax

Both the left- and right-hand-side of the assertion must be predicate names. That is, you *cannot* provide arbitrary formulas enclosed in brackets to an `assert`. This restriction eases some analysis but also encourages you to create reusable predicates.

## Test-Expect Blocks

Forge's `test expect` blocks are the most general, but also the most complex, form of testing in the tool. You don't need to provide a concrete, specific instance for `test expect`, and can check general properties. 

Every `test expect` contains a set of individual checks. Each has:
* an optional test name;
* a predicate block; and 
* an intention (`is sat`, `is unsat`, `is checked`, or&mdash;rarely!&mdash;`is forge_error`). 

The meaning of each intention is:
* `is sat`: the predicate block is satisfiable under the given bounds; 
* `is unsat`: the predicate block is unsatisfiable under the given bounds; and 
* `is checked`: the predicate block's *negation* is unsatisfiable under the given bounds.
* `is forge_error`: running the predicate block under the given bounds results in a Forge error message. This is primarily used in our internal test suites. This intention allows an optional string that must match a substring of the actual error message. E.g., `... is forge_error "very bad"` would pass if the run produced a Forge error containing the substring `"very bad"`. 

Like the other test forms, each test may be accompanied by numeric scopes and `inst` bounds.

~~~admonish example title="Test expect"

This expresses that it's possible to satisfy the `someMoveTaken` predicate:
```
test expect { possibleToMove: {someMoveTaken} is sat }  
```
~~~

~~~admonish warning title="We encourage `assert` over `test expect` where possible"
Sometimes, `test expect` is the only way to write a test for satisfiability without undue effort. But, if your test is really an assertion that something _cannot_ happen, use an `assert` instead. Yes, a `test expect` with `is unsat` can express the same thing that an `assert` can, but we find that the `assert` form is more intuitive. 
~~~

## Suites: Organizing Your Tests

You should organize your tests into `test suite`s for each predicate you plan to test.

~~~admonish example title="Test Suite"
For example, you could combine all the above forms into one suite for the `winning` predicate:

```
test suite for winning {
  assert fullFirstRow is sufficient for winning for 1 Board
  assert someMoveTaken is necessary for winning for 1 Board
  
  test expect { possibleToWin_withoutFullFirstRow: {winning and not fullFirstRow} is sat } 
  
  example diagonalWin is {winning} for {
    Board = `Board0
    X = `X0 
    O = `O0
    A = `A0
    B = `B0
    C = `C0
    `Board0.board = (0,0)->`X + (1,1)->`X + (2,2)->`X
  }
}   
```
~~~

**Test suites can only contain tests of the above forms, and all tests should reference the predicate under test.**
