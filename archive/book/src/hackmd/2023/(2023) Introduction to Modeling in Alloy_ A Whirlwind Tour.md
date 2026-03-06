# (2023) Introduction to Modeling in Alloy: A Whirlwind Tour

###### tags: `Tag(sp23)`

These notes are taken from (with modification) Tim's lecture notes from the first week of [Logic for Systems](https://csci1710.github.io/2023/) at Brown. They are intended to be a "whirlwind tour" of lightweight declarative modeling, and while they introduce a number of concepts they are _not intended as a replacement_ for documentation or more in-depth explanation of language semantics.

You can find Alloy source files corresponding to different points in this tour here:
* [tic-tac-toe boards](https://csci1710.github.io/2023/examples/alloy/ttt.als)
* [tic-tac-toe games (that reach a full board)](https://csci1710.github.io/2023/examples/alloy/ttt_games.als)
* [tic-tac-toe games (that may stop early)](https://csci1710.github.io/2023/examples/alloy/ttt_games_donothing.als)

## Tools, Documentation, and Supplemental Reading

We'll be using the [Alloy](http://alloytools.org/) declarative modeling language for this module. Alloy is a "lightweight" modeling tool. Lightweight techniques tend to eschew full formalization and embrace some partiality (see [Jackson and Wing](https://www.cs.cmu.edu/~wing/publications/JacksonWing96.pdf)) in exchange for cost-effectiveness, agility, and other benefits. As [Bornholt, et al.](https://www.amazon.science/publications/using-lightweight-formal-methods-to-validate-a-key-value-storage-node-in-amazon-s3) write in their recent paper, a lightweight approach "do(es) not aim to achieve full formal verification, but instead emphasize(s) automation, usability, and the ability to continually ensure correctness as both software and its specification evolve over time."

You can download Alloy 6 as a JAR via the preceding link. [Hillel Wayne's docs](https://alloy.readthedocs.io/en/latest/intro.htm) are great for basic Alloy reference, except that they don't currently cover temporal operators. For temporal reference, we suggest using the [High-Assurance Software Laboratory's materials](https://haslab.github.io/formal-software-design/overview/index.html).

## Systems vs. Models (and Implementations)

When we say "systems" in this module, we mean the term broadly. A distributed system (like [replication in MongoDB](https://github.com/visualzhou/mongo-repl-tla)) is a system, but so are user interfaces and hardware devices like CPUs and insulin pumps. Git is a system for version control. The web stack, cryptographic protocols, chemical reactions, the rules of sports and games---these are all systems too!

To help build intuition, let's work with a simple system: the game of [tic-tac-toe](https://en.wikipedia.org/wiki/Tic-tac-toe) (also called noughts and crosses). There are _many_ implementations of this game, including [this one](https://csci1710.github.io/2023/examples/ttt.py) that Tim wrote for these notes in Python. And, of course, these implementations often have corresponding test suites, like [this (incomplete) example](https://csci1710.github.io/2023/examples/test_ttt.py).

**Exercise**: Play a quick game of tic-tac-toe. If you can, find a partner, but if not play by yourself.

Notice what just happened. You played the game, and so doing ran your own "implementation" of the rules. The result you got was one of many possible games, each with its own specific sequence of legal moves, leading to a particular ending state. Maybe someone won, or maybe the game was a tie. Either way, many different games could have ended with that same board. 

Declarative modeling is different from programming. When you're programming traditionally, you give the computer a set of instructions and it follows them. This is true whether you're programming functionally or imperatively, with or without objects, etc. Declarative modeling languages like Alloy or Forge work differently. The goal of a model isn't to _run instructions_, but rather to express relationships between objects and describe the rules that govern systems. 

Here's a useful comparison to help reinforce the difference (with thanks to Daniel Jackson):
- An empty program **does nothing**.
- An empty model **allows every behavior**.

## Modeling Tic-Tac-Toe Boards

What are the essential concepts in a game of tic-tac-toe?

<details>
<summary>Think, then click!</summary>
We might list:

- the players `X` and `O`;
- the 3-by-3 game board, where players can put their marks;
- the idea of whose turn it is at any given time; and
- the idea of who has won the game at any given time.    
</details>

Let's start writing our model in Alloy! We certainly need a way to talk about the noughts and crosses themselves:


You can think of `sig` in Alloy as declaring a kind of object. A `sig` can extend another, in which case we say that it is a _child_ of its parent, and child `sig`s cannot overlap. When a sig is `abstract`, any member must also be a member of one of that `sig`'s children; in this case, any `Player` must either be `X` or `O`. Finally, a `one` sig has exactly one member---there's only a single `X` and `O` in our model.

We also need a way to represent the game board. We have a few options here: we could create an `Index` sig, and encode an ordering on those (something like "column A, then column B, then column C"). Another is to use Alloy's integer support. Both solutions have their pros and cons. Let's use integers, in part to get some practice with them.

Every `Board` object contains a `board` field describing the moves made so far. This field contains a table of (`Int`, `Int`, `Player`) tuples for each `Board`. We'll see how to work with this field shortly.

### What Is A Well-Formed Board?

These definitions sketch the overall shape of a board: players, marks on the board, and so on. But not all boards that fit this definition will be valid. For example:
* Alloy integers aren't true mathematical integers, but are bounded by a bitwidth we give whenever we run the tool. So we need to be careful here. We want a classical 3-by-3 board, not a board where row `-5`, column `-1` is a valid location. 
* A collection of (`Int`, `Int`, `Player`) 3-tuples allows for multiple players in the same square. Shouldn't only one player be able to move in any given square? 

We'll call these _well-formedness_ constraints. They aren't innately enforced by our `sig` declarations, but often we'll want to assume they hold (or at least check that they do). Let's encode these in a _wellformedness predicate_:

```alloy
-- a Board is well-formed if and only if:
pred wellformed[s: Board] {
  -- row and column numbers used are between 0 and 2, inclusive  
  all row, col: Int | {
    (row < 0 or row > 2 or col < 0 or col > 2) 
      implies no s.board[row][col]      
  }
  -- at most one player may move in any square
  all row, col: Int | {
    lone s.board[row][col]
  }
}
```

This predicate is true of any `Board` if and only if the above 2 constraints are satisfied. Let's break down the syntax: 
* Constraints can quantify over a domain. E.g.,`all row, col: Int | ...` says that for any pair of integers (up to the given bidwidth), the following condition (`...`) must hold. Alloy also supports, e.g., existential quantification (`some`), but we don't need that here. We also have access to standard boolean operators like `or`, `implies`, etc. 
* _Formulas_ in Alloy always evaluate to a boolean; _expressions_ evaluate to sets. For example,
    * the _expression_ `s.board[row][col]` evaluates to the set of `Player`s with marks at location (`row`, `col`) in board `s`; but
    * the _formula_ `lone s.board[row][col]` is true if and only if the above set contains at most one element.

The [docs linked above](https://alloy.readthedocs.io/en/latest/language/index.html) give much more detail about specific operators, and we suggest at least skimming the definitions there to get a sense of what Alloy supports. For now, just keep the formula vs. expression distinction in mind when working with Alloy.

Notice that, rather than describing a process that produces a well-formed board, or even instructions to check well-formedness, we've just given a declarative description of what's necessary and sufficient for a board to be well-formed. If we'd left the predicate body empty, _any_ board would be considered well-formed---there'd be no formulas to enforce!

### Running Alloy

The `run` command tells Alloy to search for an _instance_ satisfying the given constraints:

```alloy
run { some b: Board | wellformed[b]} 
```

<img style="float: right;" src="https://i.imgur.com/AKlADUg.png">

When we click Execute, the engine solves the constraints and produces a satisfying instance,  (Because of differences across solver versions, hardware, etc., it's possible you'll see a different instance than the one shown here.) We can then view the instance by clicking the blue link to the right of the Alloy window. 

<!--
<img style="float: right;"  src="https://i.imgur.com/jTwED1K.png">
-->

<img style="float: right;" src="https://i.imgur.com/34krUGX.png">

For now, we'll use the "Table" visualization. This instance contains a single board, and it has 9 entries. Player `O` has moved in all of them (the `$0` suffix of `O$0` in the display is an artifact of how Alloy's engine works). It's worth noticing two things:
* This board doesn't look quite right: player `O` occupies all the squares. We might ask: has player `O` been cheating? But the fact is that this board _satisfies the constraints we have written so far_. Alloy produces it simply because our model isn't yet restrictive enough, and for no other reason.
* We didn't say _how_ to find that instance. We just said what we wanted, and the tool performed some kind of search to find it. So far the objects are simple, and the constraints basic, but hopefully the power of the idea is coming into focus. 

### Modeling More Concepts: Starting Boards, Turns, and Winning

#### Starting Boards

What would it mean to be a _starting state_ in a game? The board is empty:

```alloy
pred starting[s: Board] {
  all row, col: Int | 
    no s.board[row][col]
}
```

#### Turns

How do we tell when it's a given player's turn? It's `X`'s turn when there are the same number of each mark on the board:

```alloy
pred XTurn[s: Board] {
  #{row, col: Int | s.board[row][col] = X} =
  #{row, col: Int | s.board[row][col] = O}
}
```

The `{row, col: Int | ...}` syntax means a set comprehension, and describes the set of row-column pairs where the board contains `X` (or `O`). The `#` operator gives the size of these sets, which we then compare.

**Question**: Is it enough to say that `OTurn` is the negation of `XTurn`? 

No! At least not in the model as currently written. If you're curious to see why, run the model and look at the instances produced. Instead, we need to say something like this:

```alloy
pred OTurn[s: Board] {
  #{row, col: Int | s.board[row][col] = X} =
  add[#{row, col: Int | s.board[row][col] = O}, 1]
}
```

Alloy supports arithmetic operations on integers like `add`. While it doesn't matter for this model yet, addition (and other operations) can overflow according to 2's complement arithmetic. For example, if we're working with 4-bit integers, then `add[7,1]` will be `-8`. 

Warning: don't try to use `+` for addition in Alloy; that will give you set union instead.

#### Winning the Game

What does it mean to _win_? A player has won on a given board if:
* they have placed their mark in all 3 columns of a row; 
* they have placed their mark in all 3 rows of a column; or
* they have placed their mark in all 3 squares of a diagonal.

We'll express this in a `winner` predicate that takes the current board and a player name. Let's also define a couple helper predicates along the way:

```alloy
pred winRow[s: Board, p: Player] {
  -- note we cannot use `all` here because there are more Ints  
  some row: Int | {
    s.board[row][0] = p
    s.board[row][1] = p
    s.board[row][2] = p
  }
}

pred winCol[s: Board, p: Player] {
  some column: Int | {
    s.board[0][column] = p
    s.board[1][column] = p
    s.board[2][column] = p
  }      
}

pred winner[s: Board, p: Player] {
  winRow[s, p]
  or
  winCol[s, p]
  or 
  {
    s.board[0][0] = p
    s.board[1][1] = p
    s.board[2][2] = p
  }
  or
  {
    s.board[0][2] = p
    s.board[1][1] = p
    s.board[2][0] = p
  }  
}
```

We now have a fairly complete model for a single tic-tac-toe board. Before we progress to games, let's decide how to fix the issue we saw above, where our model allowed for boards where a player has moved too often.

Should we add something like `OTurn[s] or XTurn[s]` to our wellformedness predicate? If we then enforced wellformedness for all boards, that would indeed exclude such instances---but at some risk, depending on how we intend to use the `wellformed` predicate. There are a few answers...
* If we were generating _valid boards_, a cheating state might well be spurious, or at least undesirable. In that case, we might prevent such states in `wellformed` and rule it out. 
* If we were generating (not necessarily valid) boards, being able to see a cheating state might be useful. In that case, we'd leave it out of `wellformed`.
* If we're interested in _verification_, e.g., we are asking whether the game of Tic-Tac-Toe enables ever reaching a cheating board, we shouldn't add `not cheating` to `wellformed`---at least, not so long as we're enforcing `wellformed`, or else Alloy will never find us a counterexample! 

**IMPORTANT:** In that last setting, notice the similarity between this issue and what we do in property-based testing. Here, we're forced to distinguish between what a reasonable _board_ is (analogous to the generator's output in PBT) and what a reasonable _behavior_ is (analogous to the validity predicate in PBT). One narrows the scope of possible worlds to avoid true "garbage"; the other checks whether the system behaves as expected in one of those worlds.

We'll come back to this later, when we've modeled full games. For now, let's separate our goal into a new predicate called `balanced`, and add it to our `run` command above:

```alloy
pred balanced[s: Board] {
  XTurn[s] or OTurn[s]
}
run { some b: Board | wellformed[b] and balanced[b]} 
```

To view instances for this new `run` command, select the Execute menu and then `Run run$2`.

<!--

* If we assert that the predicate must hold at all times, then we'll never be able to detect situations in which it's violated. 

-->

If we click the "Next" button a few times, we see that not all is well: we're getting boards where `wellformed` is violated (e.g., entries at negative rows, or multiple moves in one square). 

We're getting this because of how the `run` was phrased. We said to find an instance where _some board_ was well-formed and valid, not one where _all boards_ were. By default, Alloy will find instances with up to 4 `Boards`. So we can fix the problem either by telling Alloy to find instances with only 1 Board:

```alloy
run { some b: Board | wellformed[b] and balanced[b]} 
for exactly 1 Board
```

or by saying that all boards must be well-formed and valid:

```alloy
run { all b: Board | wellformed[b] and balanced[b]} 
```

## From Boards to Games

What do you think a _game_ of tic-tac-toe looks like? How should we model the moves between board states?

<details>
<summary>Think, then click!</summary>

It's often convenient to think of the game as a big graph, where the nodes are the states (possible board configurations) and the edges are transitions (in this case, legal moves of the game). Here's a rough sketch:  
    
![](https://i.imgur.com/YmsbRp8.png)
  
</details>
<br/>

A game of tic-tac-toe is a sequence of steps in this graph, starting from the empty board. Let's model it.

First, what does a move look like? A player puts their mark at a specific location. In Alloy, we'll represent this using a _transition predicate_: a predicate that says when it's legal for one state to evolve into another. We'll often call these the _pre-state_ and _post-state_ of the transition:

```alloy
pred move[pre: Board, row: Int, col: Int, p: Player, post: Board] {
  // ...
}
```

What constraints should we add? It's useful to divide the contents of such a predicate into:
* a _guard_, which allows the move only if the pre-state is suitable; and 
* an _action_, which defines what is in the post-state based on the pre-state and the move parameters.
 
For the guard, in order for the move to be valid, it must hold that in the pre-state:
* nobody has already moved at the target location; and
* it's the moving player's turn.
For the action:
* the new board is the same as the old, except for the addition of the player's mark at the target location.

Now we can fill in the predicate: 

<!-- We'll use an _if-then-else_ constraint):

```alloy
pred move[pre: Board, row: Int, col: Int, p: Player, post: Board] {
  no pre.board[row][col] -- nobody's moved there
  p = X implies XTurn[pre]  
  p = O implies OTurn[pre]  
  all row2, col2: Int | {    
    (row = row2 and col = col2) 
      =>   post.board[row2][col2] = p
      else post.board[row2][col2] = pre.board[row2][col2]     
  }
}
```
-->

```alloy
pred move[pre: Board, row: Int, col: Int, p: Player, post: Board] {
  -- guard:
  no pre.board[row][col]   -- nobody's moved there yet
  p = X implies XTurn[pre] -- appropriate turn
  p = O implies OTurn[pre]  
  
  -- action:
  post.board[row][col] = p
  all row2: Int-row, col2: Int-col | {        
     post.board[row2][col2] = pre.board[row2][col2]     
  }  
}
```

There are many equivalent ways to write this predicate; some of them are even more concise. However, we're going to stick with this form because it calls out an important point. Suppose we had only written `post.board[row][col] = p` without the following lines. Those added lines, which we'll call a _frame condition_, say that all other squares remain unchanged; without them, the contents of any other square might change in any way. Leaving them out would be what's called an _underconstraint bug_: the predicate would be too weak to accurately describe moves in tic-tac-toe. 

**Exercise**: comment out the 3 frame-condition lines and run the model. Do you see moves where the other 8 squares change arbitrarily?

#### A Relational Alternative 

We could have written the action in just one line:
```
  post.board = pre.board + (row -> col -> p)  
```
This says that the contents of the post-state board are the _union_ of the previous contents and the new entry for this location (`->` means product in Alloy). You'll often see concise relational constraints like this in "real" models. 

#### What We _Didn't_ Say

We didn't require that the row and column be 0, 1, or 2. Why not? Because, if we're asserting the wellformed predicate as a baseline, we don't need to! This is the first reason why we chose to _not_ enforce `valid` as part of `wellformed`, although it could be argued that it's better to enforce that restriction as part of `move` anyway.

### Generating Transitions

Let's see if Alloy can find us a transition where someone becomes a winner:

```alloy
run {  
  some pre, post: Board | {
    wellformed[pre]
    some row, col: Int, p: Player | 
      move[pre, row, col, p, post]
    not winner[pre, X]
    not winner[pre, O]
    winner[post, X]    
  }
} 
```

**Exercise:** This seems a little verbose. What's the purpose of each of these lines?

### A Simple Property

Once someone wins a game, does their win still persist, even if more moves are made? I'd like to think so: moves never get undone, and in our model winning just means the existence of 3-in-a-row for some player. 

We probably believe this without checking it, but not all such _preservation properties_ are so straightforward. We'll check this one in Alloy as an example of how you might prove something similar in a more complex system.

<!--
**Looking Ahead**: This is our first step into the world of _verification_. Asking whether or not a program, algorithm, or other system satisfies some assertion is a core problem in formal methods, and has a long and storied history that we'll be talking about over the next weeks. 
-->

We'll tell Alloy to find us pairs of states, connected by a move: the _pre-state_ before the move, and the _post-state_ after it. That's _any_ potential transition in tic-tac-toe. The trick is in adding two more constraints. We'll say that someone has won in the pre-state, but they _haven't won_ in the post-state.

```alloy
pred winningPreservedCounterexample {
  some pre, post: Board | {
    some row, col: Int, p: Player | 
      move[pre, row, col, p, post]
    winner[pre, X]
    not winner[post, X]
  }
}
run {
  all s: Board | wellformed[s]
  winningPreservedCounterexample
}
```

Alloy finds a counterexample. Whoops---something must be broken. Let's re-examine our `move` predicate, in particular the frame condition in the action:

```alloy
  all row2: Int-row, col2: Int-col | {        
     post.board[row2][col2] = pre.board[row2][col2]     
  } 
```

This says that for any board location where _both the row and column differ_ from the move's, the board remains the same. But is that what we really wanted? Suppose `X` moves at location `1`, `1`. Then of the 9 locations, which is actually protected?

|Row|Column|Protected?|
|---|------|----------|
|  0|     0|yes       |
|  0|     1|no (column 1 = column 1)|
|  0|     2|yes       |
|  1|     0|no (row 1 = row 1)|
|  1|     1|no (as intended)|
|  1|     2|no (row 1 = row 1)|
|  2|     0|yes       |
|  2|     1|no (column 1 = column 1)|
|  2|     2|yes       |

Our frame condition was _too weak_! We need to have it take effect whenever _either_ the row or column is different. 

```alloy
  all row2: Int, col2: Int | 
    ((row2 != row) or (col2 != col)) implies {    
       post.board[row2][col2] = pre.board[row2][col2]     
  }  

```

And now our check passes.

## Generating Complete Games

Recall that our worldview for this model is that systems _transition_ between _states_, and thus we can think of a system as a directed graph. If the transitions have arguments, we'll sometimes label the edges of the graph with those arguments. This view is sometimes called a _discrete event_ model, because one event happens at a time. Here, the events are moves of the game. In a bigger model, there might be many different types of events.

So, how do you think we could get Alloy to find us complete valid games of Tic-Tac-Toe? A game is an execution of the system; this is sometimes called a _trace_. We'll tell Alloy to apply a total ordering to all `Board`s by opening the `util/ordering` module:

```alloy=
open util/ordering[Board]
```

and then we'll define a predicate to find traces of the game:

```alloy
pred traces {
    -- The trace starts with an initial state
    starting[first]     
    -- Every transition is a valid move
    all s: State | some s.next implies {
      some row, col: Int, p: Player |
        move[s, row, col, p, s.next]
    }
}

-- 10 states is just enough for a full game
run { wellformed } for 10 Board 
```

One thing to beware here is that `util/ordering` enforces _exact_ bounds on the `sig` being ordered. The above `run` command only finds traces of length 10. If we want arbitrary-length traces (e.g., that can terminate early) we would need to account for that by modifying our transition system.

### Running And The Evaluator

You may have noticed that Alloy's default visualization for boards is difficult to use. Directed graphs are great for some applications, but not so good here. That's why we've been using the "table" visualization.

There's some new work in visualizing Alloy instances that we'll see more during the summer school itself, but for now, here's an example of a custom visualization for moves taken in tic-tac-toe games:

![](https://i.imgur.com/m6KRWtI.png)


### The Evaluator

Moreover, since we're now viewing a single fixed instance, we can _evaluate_ Alloy expressions in it. This is great for debugging, but also for just understanding Alloy a little bit better. Open the evaluator here at the bottom of the right-side tray, under theming. Then enter an expression or constraint here:

![](https://i.imgur.com/tnT8cgo.png)


Type in something like `some s: State | winner[s, X]`. Alloy should give you either `#t` (for true) or `#f` (for false) depending on whether the game shows `X` winning the game.

### Optimizing

You might notice that this model takes a while to run (30 seconds on my laptop). Why might that be? Let's re-examine our bounds and see if there's anything we can adjust. In particular, here's what the evaluator says we've got for integers:

![](https://i.imgur.com/UJJUqdB.png)

Wow---wait, do we really **need** to be able to count up to `7` for this model? Probably not. If we change our integer bounds to `3 Int` we'll still be able to use `0`, `1`, and `2`, and the Platonic search space is much smaller; Alloy takes under 3 seconds now on my laptop.


## Doing Nothing (Productively)

If we look at `traces` produced so far, probably we'll only see games that continue until every space is filled. What would happen if we wanted to stop as soon as someone had won?

As we saw earlier, with `exactly 10 State`, Alloy won't ever produce a trace smaller than 10 states.  We need to allow the model some flexibility---but not too much!

Let's add an additional transition that does nothing. We can't "do nothing" in the predicate body, though -- that would just mean _anything_ could happen. What we mean to say is that the state of the board remains the same, even if the before and after `Board` objects differ.

```alloy
pred doNothing[pre: Board, post: Board] {
    pre.board = post.board
}
```

We also need to edit the `traces` predicate to allow `doNothing` to take place:

```alloy
pred traces {
    -- The trace starts with an initial state
    starting[first]     
    -- Every transition is a valid move
    all s: Board | some s.next implies {
      some row, col: Int, p: Player |
        move[s, row, col, p, s.next]
        or doNothing[s, s.next]
    } 
}
```

As it stands, this fix solves the _overconstraint_ problem of never seeing an early win, but introduces a new _underconstraint_ problem: we don't want `doNothing` transitions to happen just anywhere!

Here's how I like to fix it:

```alloy
pred gameOver[s: Board] {
  some p: Player | winner[s, p]
}
```

Why a new predicate? Because I want to use different predicates to represent different concepts. 

When should a `doNothing` transition be possible? _When the game is over!_

```alloy
pred doNothing[pre: Board, post: Board] {
    gameOver[pre] -- guard of the transition
    pre.board = post.board -- effect of the transition
}
```

If we wanted to, we could add a `not gameOver[pre]` to the `move` predicate, enforcing that nobody can move at all after someone has won.

## Do The Rules Allow Cheating?

Let's ask Alloy whether a `cheating` state is possible under the rules. 

```alloy
run {
  wellformed
  traces
  some bad: State | cheating[bad]
} for exactly 10 State for {next is linear}
```

#### XTurn vs. OTurn

At this point, we have another reason why we couldn't just define `OTurn` as the negation of `XTurn`. We just checked that, using our move predicate, it's impossible to reach a "cheating" state from the start state. For example, we should never be able to reach a state that has 5 `X` marks and 1 `O` mark. If we can show this, then we've increased our confidence in the way we've modeled the rules of Tic-Tac-Toe. The way I wrote `XTurn` and `OTurn` in class, we can proceed as follows...

```alloy
pred cheating[s: State] {
  not XTurn[s]
  not OTurn[s]
}
```

Any state that satisfies the above predicate is a state where someone's cheated---or, perhaps, where our model has failed to faithfully represent the rules. If we'd defined `OTurn` as `not XTurn`, this wouldn't be so simple to phrase!

## Checking Conjectures

When I was very small, I thought that moving in the middle of the board would guarantee a win at Tic-Tac-Toe. Now I know that isn't true. But could I have used Alloy to check my conjecture?

<details>
<summary>Think, then Click!</summary>
Here's how I did it:    
    
```alloy
run {
  wellformed
  traces
  -- "let" just lets us locally define an expression
  --  good for clarity in the model!
  -- here we say that X first moved in the middle
  let second = first.next |
    second.board[1][1] = X
  -- ...but X didn't win
  all s: Board | not winner[s, X]
} for exactly 10 Board
```    
    
</details>


## Will This Always Work?

Let's say you're checking properties for a real system. A distributed-systems algorithm, maybe, or a new processor. Even a more complex version of Tic-Tac-Toe! 

Next time, we'll talk about the problems with traces, which turn out to be  **central challenges in software and hardware verification**. 




