# 2023.5 Introduction to Modeling (Part 3, Transitions)

Today's livecode is [here](./intro_modeling_ttt_3_inclass.frg).

<!-- this is post-lab, so move is written, they have some experience with the model** -->

Let's continue where we left off. In your lab this week, you probably saw a finished `move` predicate that was _very_ similar to the one we started writing. 

Suppose we ended up with something like this:

```alloy
pred move[pre: Board, row: Int, col: Int, p: Player, post: Board] {
  -- guard:
  no pre.board[row][col]   -- nobody's moved there yet
  p = X implies XTurn[pre] -- appropriate turn
  p = O implies OTurn[pre]  
  
  -- action:
  post.board[row][col] = p
  all row2: Int, col2: Int | (row!=row2 and col!=col2) implies {        
     post.board[row2][col2] = pre.board[row2][col2]     
  }  
}
```

There's actually a bug in this predicate. Can you use Forge to find it? 

<details>
<summary>Think, then click</summary>
The `all row2...` formula says that for any board location where _both the row and column differ_ from the move's, the board remains the same. But is that what we really wanted? Suppose `X` moves at location `1`, `1`. Then of the 9 locations, which is actually protected?

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

Our frame condition was _too weak_! We need to have it take effect whenever _either_ the row or column is different. Something like this will work:

```alloy
  all row2: Int, col2: Int | 
    ((row2 != row) or (col2 != col)) implies {    
       post.board[row2][col2] = pre.board[row2][col2]     
  }  

``` 
</details>

### A Simple Property

Once someone wins a game, does their win still persist, even if more moves are made? I'd like to think so: moves never get undone, and in our model winning just means the existence of 3-in-a-row for some player. 

We probably believe this without checking it, but not all such _preservation properties_ are so straightforward. We'll check this one in Forge as an example of how you might prove something similar in a more complex system.

**Looking Ahead**: This is our first step into the world of _verification_. Asking whether or not a program, algorithm, or other system satisfies some assertion is a core problem in formal methods, and has a long and storied history that we'll be talking about over the next weeks. 

We'll tell Forge to find us pairs of states, connected by a move: the _pre-state_ before the move, and the _post-state_ after it. That's _any_ potential transition in tic-tac-toe. The trick is in adding two more constraints. We'll say that someone has won in the pre-state, but they _haven't won_ in the post-state.

```alloy
pred winningPreservedCounterexample {
  some pre, post: Board | {
    some row, col: Int, p: Player | 
      move[pre, post, row, col, p]
    winner[pre, X]
    not winner[post, X]
  }
}
run {
  all s: Board | wellformed[s]
  winningPreservedCounterexample
}
```

The check passes---Forge can't find any counterexamples. We'll see this reported as "UNSAT" in the visualizer. 

**Aside:** the visualizer also has a "Next" button. If you press it enough times, Forge runs out of solutions to show. Right now, this is indicated by some frowning emoji---not the best message.

## Generating Complete Games

Recall that our worldview for this model is that systems _transition_ between _states_, and thus we can think of a system as a directed graph. If the transitions have arguments, we'll sometimes label the edges of the graph with those arguments. This view is sometimes called a _discrete event_ model, because one event happens at a time. Here, the events are moves of the game. In a bigger model, there might be many different types of events.

Today, we'll ask Forge to find us traces of the system, starting from an initial state. We'll also add a `Game` sig to incorporate some metadata.

```alloy
one sig Game {
  initialState: one Board,
  next: pfunc Board -> Board
}

pred traces {
    -- The trace starts with an initial state
    starting[Game.initialState]
    no sprev: Board | Game.next[sprev] = Game.initialState
    -- Every transition is a valid move
    all s: Board | some Game.next[s] implies {
      some row, col: Int, p: Player |
        move[s, row, col, p, Game.next[s]]
    }
}
```

By itself, this wouldn't be quite enough; we might see a bunch of disjoint traces. We could add more constraints manually, but there's a better option: tell Forge, at `run`time, that `next` represents a linear ordering on states.

```alloy
run {
  traces
} for {next is linear}
```

The key thing to notice here is that `next is linear` isn't a _constraint_; it's a separate annotation given to Forge alongside a `run` or a test. Never put such an annotation in a constraint block; Forge won't understand it. These annotations narrow Forge's _bounds_ (the space of possible worlds to check) which means they can often make problems more efficient for Forge to solve.

You'll see this `{next is linear}` annotation again in lab this week. In general, Forge accepts such annotations _after_ numeric bounds. E.g., if we wanted to see full games, rather than unfinished game prefixes (remember: the default bound on `Board` is up to 4) we could have asked:

```alloy
run {
  traces
} for exactly 10 Board for {next is linear}
```

You might notice that because of this, some traces are excluded. That's because `next is linear` forces exact bounds on `Board`. More on this next time.

<!-- ## Testing Models: Examples

Forge has a number of features that make it easier to _test_ your models. Here's one: `example`. We'll make a new file for our tests called `feb03_ttt.tests.frg` and open the model there. 

An _example_ in Forge is like a `run` except that it only opens the visualizer if the test fails. The example defines a full instance and then checks whether that instance satisfies a given predicate. So we'll make a new predicate that's "instance-wide", and checks wellformedness for all boards.

```alloy
#lang forge/bsl 
open "feb03_ttt.frg"

pred allWellformed {
    all b: Board | wellformed[b]
}
```

Then we'll fill in an example. These have a standard format, but the language of an example is a bit different: you're defining an _instance_, not a set of constraints.

```alloy
-- *TEST CASE* in Forge: this instance satisfies this predicate
example middleRowWellformed is {allWellformed} for {
    -- "for 3 Int" (prefer that outside examples)
    #Int = 3
    -- the backquote denotes an OBJECT by name
    -- use only these on the right-hand side of = here
    X = `X0
    O = `O0
    Player = `X0 + `O0
    Board = `Board0
    board = `Board0 -> (1 -> 0 -> `X0 + 
                        1 -> 1 -> `X0 +
                        1 -> 2 -> `X0)    
}
```

This is a bit verbose, but it completely defines an instance with 1 board and 3 moves placed. You can read the `board =` line as saying, for `Board0`, there's a dictionary with these 3 entries.

More on testing next time! -->

## Running And The Evaluator

Forge's default visualization for boards is difficult to use. Directed graphs are great for some applications, but not so good here. That's why we've been using the "table" visualization.
Our visualizer (called Sterling) allows you to write short JavaScript visualization scripts. The following script produces game visualizations with states like this:

![](https://i.imgur.com/m6KRWtI.png)

We'll talk more about visualization scripts later. For now, here's an example from last year---this year's scripts are less verbose and more straightforward to write.

<details>
<summary>Click to see script.</summary>

```javascript=
const d3 = require('d3')
d3.selectAll("svg > *").remove();

/*
  Visualizer for the in-class tic-tac-toe model. This is written in "raw" 
  D3, rather than using our helper libraries. If you're familiar with 
  visualization in JavaScript using this popular library, this is how you 
  would use it with Forge.

  Note that if you _aren't_ familiar, that's OK; we'll show more examples 
  and give more guidance in the near future. The helper library also makes 
  things rather easier. 

  TN 2024

  Note: if you're using this style, the require for d3 needs to come before anything 
  else, even comments.
*/

function printValue(row, col, yoffset, value) {
  d3.select(svg)
    .append("text")
    .style("fill", "black")
    .attr("x", (row+1)*10)
    .attr("y", (col+1)*14 + yoffset)
    .text(value);
}

function printState(stateAtom, yoffset) {
  for (r = 0; r <= 2; r++) {
    for (c = 0; c <= 2; c++) {
      printValue(r, c, yoffset,
                 stateAtom.board[r][c]
                 .toString().substring(0,1))  
    }
  }
  
  d3.select(svg)
    .append('rect')
    .attr('x', 5)
    .attr('y', yoffset+1)
    .attr('width', 40)
    .attr('height', 50)
    .attr('stroke-width', 2)
    .attr('stroke', 'black')
    .attr('fill', 'transparent');
}


var offset = 0
for(b = 0; b <= 10; b++) {  
  if(Board.atom("Board"+b) != null)
    printState(Board.atom("Board"+b), offset)  
  offset = offset + 55
}
```
</details>

### The Evaluator

Moreover, since we're now viewing a single fixed instance, we can _evaluate_ Forge expressions in it. This is great for debugging, but also for just understanding Forge a little bit better. Open the evaluator here at the bottom of the right-side tray, under theming. Then enter an expression or constraint here:

![](https://i.imgur.com/tnT8cgo.png)

Type in something like `some s: State | winner[s, X]`. Forge should give you either `#t` (for true) or `#f` (for false) depending on whether the game shows `X` winning the game.

### Optimizing

You might notice that this model takes a while to run, after we start reasoning about full games. Why might that be? Let's re-examine our bounds and see if there's anything we can adjust. In particular, here's what the evaluator says we've got for integers:

![](https://i.imgur.com/UJJUqdB.png)

Wow---wait, do we really **need** to be able to count up to `7` for this model? Probably not. If we change our integer bounds to `3 Int` we'll still be able to use `0`, `1`, and `2`, and the Platonic search space is much smaller; Forge takes under 3 seconds now on my laptop.

