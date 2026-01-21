# 5: Modeling in Forge (Part 3)

###### tags: `Tag(sp22)`

#### Friday Feb. 4nd: Logistics

* If you submitted PBT under a Canvas-synched ID, please resubmit from your anonymous account. Since some of yoy haven't done so, I've allowed submissions until end of day today.
* The second homework goes out today. 
* Expect Forge updates every week on the weekend. I'll be posting notes. For emergencies (e.g., Sterling issue), we'd update outside the cycle.
* Reading the notes from last time, and the tic-tac-toe example from today will help a great deal. **In general, notes will often contain more than we can cover in lecture; treat them like reading and at least skim them for parts we don't see in class.**
* The autograder may not be installed in Gradescope today, but we'll get it in soon. All this means is that those of you who upload very early won't get feedback immediately. We'll let you know when the autograder is in. (The context here is: we don't want to grade your tests in the Draconian way we did last year, and so we need to modify the autograder, and Gradescope is sometimes a pain.)

## Homework Discussion: Forge 1

We're asking you to model two things: a family tree, and a stack data structure. That's a bit of an oversimplification, though. 

### I Am My Own Grandparent

Suppose I told you that I was my own grandparent. How could this be possible? Is time travel required? 

<details>
<summary>Think, then click!</summary>
It depends on your definition of "grandparent"! If I meant *biological* grandparent, there's some time-travel tomfoolery going on. But what if we relax the definition a little bit, and think about grandparenthood _by marriage_?
</details>
<br/>

In this model, we'll limit the world to exactly 4 people. That should suffice to find an explanation.

### Stack Properties

Stacks are a mainstay of data structures courses: a linear sequence of elements, with adding and removing ("pushing" and "popping") from the same side of the list (the "top" of the stack). You may recall that this is the opposite of a queue, which adds elements at one end and removes them from the other.

What are some properties that stacks should exhibit? In other words, **what makes stacks useful at all**?

<details>
<summary>Think, then click!</summary>

Here's one example: if I push an element onto the stack, and then immediately pop the top element from the stack, I've got exactly the same elements I started with! This property describes some of what's unique to a stack. 
    
</details>

## Forge Performance

Some of you encountered really terrible Forge performance in lab. I looked into it this morning, and think it's useful to discuss the problem briefly. (I was hoping to defer the discussion of performance, but given lab I want to explain ASAP.)

Forge works by converting your model into a boolean satisfiability problem. That is, it builds a boolean circuit where inputs making the circuit true satisfy your model. But boolean circuits don't understand quantifiers, and so it needs to compile them out. 

The compiler has a lot of clever tricks to make this fast, and we'll talk about some of them around mid-semester. But if it can't apply those tricks, it uses a naive idea: an `all` is just a big `and`, and a `some` is just a big `or`. And this naive conversion process increases the size of the circuit exponentially in the depth of quantification. 

Here is a perfectly reasonable and correct way to approach part of this week's lab:

```alloy
pred notAttacking {
  all disj q1, q2 : Queen | {
    some r1, c1, r2, c2: Int | {
    // ...
    }
  }
```

The problem is: there are 8 queens, and 16 integers. It turns out this is a pathological case for the compiler, and it runs for a really long time. In fact, it runs for a long time even if we reduce the scope to 4 queens. We can see the timing info exactly by increasing the verbosity option: `option verbose 2`.

```
:stats ((size-variables 410425) (size-clauses 617523) (size-primary 1028) (time-translation 18770) (time-solving 184) (time-building 40)) :metadata ())
#vars: (size-variables 410425); #primary: (size-primary 1028); #clauses: (size-clauses 617523)        
Transl (ms): (time-translation 18770); Solving (ms): (time-solving 184)
```

The `time-translation` figure is the number of milliseconds used to convert the model to a boolean circuit. Ouch!

Instead, we might try a different approach that uses fewer quantifiers. In fact, we can write the constraint without referring to specific queens at all -- just 4 integers.

If you encounter bad performance from Forge, this sort of branching blowup is a common cause, and can often be fixed by reducing quantifier nesting, or by narrowing the scope of what's being quantified over.

## Tic-Tac-Toe Games

To avoid spoiling your homework, we'll shift gears and model something else that's stateful: boards of [tic-tac-toe](https://en.wikipedia.org/wiki/Tic-tac-toe) (also called noughts and crosses, among other names). 

Like a stack, tic-tac-toe games change over time. But instead of pushing or popping an element, tic-tac-toe games change when a player moves. 

What do you think a tic-tac-toe game state should look like? And, can we visualize the moves between states?

<details>
<summary>Think, then click!</summary>

It's often convenient to think of the game as a big graph, where the nodes are the states (possible board configurations) and the edges are transitions (in this case, legal moves of the game). Here's a rough sketch:  
    
![](https://i.imgur.com/YmsbRp8.png)
  
</details>
<br/>

A game of tic-tac-toe is a sequence of steps in this graph, starting from the empty board. Let's model it.

**Note:** Today we'll move through the model pretty fast, so that you're maximally prepared for your homework. On Monday, we'll return to this model and step through it more slowly, and also write some tests to validate it.

### Modeling Tic-Tac-Toe in Forge

We certainly need a way to talk about the noughts and crosses themselves:

```alloy
abstract sig Player {}
one sig X, O extends Player {}
```

But we also need a way to represent the game board. We have a few options here: we could create an `Index` sig, and encode an ordering on those (something like "column A, then column B, then column C"). Another is to use integers. 

Both solutions have their pros and cons. Let's use integers, in part to get more practice with them in Forge.

```alloy
-- In every state of the game, each square has 0 or 1 marks.
sig State {
  board: pfunc Int -> Int -> Player
}
```

#### What Is A Well-Formed Board?

What do you think describes a well-formed board of Tic-Tac-Toe?

<details>
Some good properties are:    
    * Indexes used can't be less than $0$ or greater than $2$;
    * There's no "cheating"; e.g., the board doesn't have all "X" markings without the right number of "O" markings.
    
We'll start with the first one now, and fill in the second next time, when we're able to express it.
</details>    

Since the number of integers that can exist depends on the bitwidth we give to Forge, we need to be careful here. We want a classical 3-by-3 board, not a board where row `-5`, column `-1` is a valid location. Let's starting writing a wellformedness predicate:

```alloy
pred wellformed {
  all s: State | {
    all row, col: Int | {
      (row < 0 or row > 2 or col < 0 or col > 2) 
        implies no s.board[row][col]    
    }
  }
}
```

Now even if boards are *really* bigger than 3-by-3 internally, it's only the 9 squares between `0,0` and `2,2` that can be used in any state. 
    
### Starting Boards

What would it mean to be a _starting state_ in a game? The board is empty:

```alloy
pred starting[s: State] {
  all row, col: Int | 
    no s.board[row][col]
}
```

What does a move look like? A player puts their mark at a specific location. In Forge, we'll represent this using a _transition predicate_: a predicate that says when it's legal for one state to evolve into another. We'll often call these the _pre-state_ and _post-state_ of the transition:

```alloy
pred move[pre: State, row: Int, col: Int, p: Player, post: State] {
  // ...
}
```

What constraints should we add? We need to say that, in order for the move to be valid, in `pre` state it must hold that:
* nobody has already moved at the target location; and
* it's the player's turn.
 
We also need to describe the effect of the move on the `post` state:
* the new board is the same as the old, except for the addition of the player's mark at the target location.

How do we tell when it's a given player's turn?

```alloy
pred XTurn[s: State] {
  #{row, col: Int | s.board[row][col] = X} =
  #{row, col: Int | s.board[row][col] = O}
}
```

**Question**: Is it enough to say that `OTurn` is the negation of `XTurn`? 

No! (If you're curious about why, try it out in Forge, and see what instances you get.) Instead, we need to say something like this:

```alloy
pred OTurn[s: State] {
  #{row, col: Int | s.board[row][col] = X} =
  add[#{row, col: Int | s.board[row][col] = O}, 1]
}
```

Now we can write the `move` predicate. We'll use an _if-then-else_ constraint):

```alloy
pred move[pre: State, row: Int, col: Int, p: Player, post: State] {
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

What does it mean to _win_?

```alloy

pred winRow[s: State, p: Player] {
  -- note we cannot use `all` here because there are more Ints  
  some row: Int | {
    s.board[row][0] = p
    s.board[row][1] = p
    s.board[row][2] = p
  }
}

pred winCol[s: State, p: Player] {
  some column: Int | {
    s.board[0][column] = p
    s.board[1][column] = p
    s.board[2][column] = p
  }      
}

pred winner[s: State, p: Player] {
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

Let's see if Forge can find us a transition where someone becomes a winner:

```alloy
run {
  wellformed
  some pre, post: State | {
    some row, col: Int, p: Player | 
      move[pre, row, col, p, post]
    not winner[pre, X]
    winner[post, X]    
  }
} 

```

Soon we'll talk about how to write a quick JS visualization that makes this a lot more pleasant to look at. For now we can either use table view, or theming.

### A Simple Property

Once someone wins a game, does their win still persist, even if more moves are made? I'd like to think so: moves never get undone, and in our model winning just means the existence of 3-in-a-row for some player. 

We probably believe this without checking it in Forge, but not all such _preservation properties_ are so straightforward. We'll check this one in Forge as an example of how you might prove something similar in a more complex system (or on your homework).

**Looking Ahead**: This is our first step into the world of _verification_. Asking whether or not a program, algorithm, or other system satisfies some assertion is a core problem in formal methods, and has a long and storied history that we'll be talking about over the next weeks. 

#### Checking It

We'll tell Forge to find us pairs of states, connected by a move: the _pre-state_ before the move, and the _post-state_ after it. That's _any_ potential transition in tic-tac-toe. 

The trick is in adding two more constraints. We'll say that someone has won in the pre-state, but they _haven't won_ in the post-state.

```alloy
pred winningPreservedCounterexample {
  some pre, post: State | {
    some row, col: Int, p: Player | 
      move[pre, row, col, p, post]
    winner[pre, X]
    not winner[post, X]
  }
}
run {
  wellformed
  winningPreservedCounterexample
}
```




