# 6: Continuing with State and Traces

###### tags: `Tag(sp22)`

## Logistics

* Continue to ignore the autograder results for Forge 1; we'll let you know when they are integrated properly into Gradescope.
* Forge update coming soon (I fixed a bug this morning and want to test further). We'll make an Ed post when it's ready. When it's ready, update Forge! (`raco update forge` if you've installed via Racket's package system; pull and run `raco setup forge` if you've installed via `git`) Expect to do this weekly.
* The second Forge lab is out today! You'll be modeling a simplified version of a classic distributed systems problem. You'll also be generating _traces_ of system behavior---not just 2 or 3 states, as in the homework out now.
* Some of you have reasonably asked about how it's ever possible to be one's own grandparent, given our definition of "related". See my answer to [post 122](https://edstem.org/us/courses/15791/discussion/1097723). A big part of 1710 is about the places that the real world and our "definitions" meet (even when those definitions are fuzzy, or contested). **So if you're wondering about this, you're thinking exactly the right thoughts.**
* I've endorsed several questions on EdStem that contain useful info. Moreover, it appears that a totally non-fictional fellow student of yours, Nim Telson, is auditing 1710 again this year. Nim is a bit of a troublemaker, so I've instructed the staff not to engage with their questions. However, Nim manages to always ask questions that touch on subtle or confusing points from lecture, and labels them with `[Nim Telson]` in the subject line. So I'd like to ask **YOU** to reply and discuss those questions! (If you know the answer, try to reply in a way that stimulates discussion without spoiling the thought process.) 
* I'm holding extra [Forge Clinic hours](https://edstem.org/us/courses/15791/discussion/1096988) today. If you're having trouble with installation, running, etc. I'll be around in my Zoom to help you out. (So far nobody has left Forge Clinic unable to run Forge or work on the homework, and that's not because nobody has come to Forge Clinic.)

## Tac-Tac-Toe Two

We went through the Tic-Tac-Toe model pretty quickly on Friday, because I wanted to cover a broad set of things in preparation for your homework (including some suggestions about debugging performance issues). 

Consequently, a lot was left unsaid. What was that "if-then-else" constraint, again? What are the arguments to a transition predicate? Why did we not define `OTurn` to be the negation of `XTurn`? And so on. Today we'll resolve some of those questions and finally get Forge to give us _games_, rather than just a single move.

### Reminder and Terminology

Our worldview for this model is that systems _transition_ between _states_, and thus we can think of a system as a directed graph. If the transitions have arguments, we'll sometimes label the edges of the graph with those arguments.

This view is sometimes called a _discrete event_ model, because one event happens at a time. Here, the events are moves of the game. In a bigger model, there might be many different types of events.

### Modeling Choice 1: XTurn vs. OTurn

Some of you were curious why we couldn't just define `OTurn` as the negation of `XTurn`. This is a subtle point, and a good question to ask.

Next time we will use Forge to prove that, using our move predicate, it's impossible to reach a "cheating" state from the start state. For example, we should never be able to reach a state that has 5 `X` marks and 1 `O` mark. If we can show this, then we've increased our confidence in the way we've modeled the rules of Tic-Tac-Toe. The way I wrote `XTurn` and `OTurn` in class, we can proceed as follows...

```alloy
pred cheating[s: State] {
  not XTurn[s]
  not OTurn[s]
}
```

Any state that satisfies the above predicate is a state where someone's cheated---or, perhaps, where our model has failed to faithfully represent the rules. Note that if we'd defined `OTurn` as `not XTurn`, this wouldn't be so simple to phrase. 

#### Should `not cheating` be part of the `wellformed` predicate?

Maybe. There are a few answers...
* If we were generating _valid boards_, a cheating state might well be spurious, or at least undesirable. In that case, we might add it to `wellformed` and rule it out. 
* If we were generating (not necessarily valid) boards, being able to see a cheating state might be useful. In that case, we'd leave it out of `wellformed`.
* If we're interested in _verification_, and are asking whether the game of Tic-Tac-Toe enables ever reaching a cheating board, we shouldn't add `not cheating` to `wellformed`---or else Forge will never find us a counterexample! 

**IMPORTANT:** In that last setting, notice again the similarity between this question, and the PBT homework. Here, we're forced to distinguish between what a reasonable _board_ is (analogous to the generator's output in PBT) and what a reasonable _behavior_ is (analogous to the `is_valid` predicate in PBT). One narrows the scope of possible worlds; the other checks whether the system behaves as expected in one of those worlds.

We'll come back to this predicate on Wednesday, because today I want to focus on **actually generating full games!***

## Generating Complete Games

How do you think we could get Forge to find us complete valid games of Tic-Tac-Toe? 

Today, we'll ask Forge to find us traces of the system, starting from an initial state. We'll also add a `Game` sig to incorporate some metadata.

```alloy
one sig Game {
  initialState: one State,
  next: pfunc State -> State
}

pred traces {
    -- The trace starts with an initial state
    starting[Game.initialState]
    no sprev: State | Game.next[sprev] = Game.initialState
    -- Every transition is a valid move
    all s: State | some Game.next[s] implies {
      some row, col: Int, p: Player |
        move[s, row, col, p, Game.next[s]]
    }
}
```

By itself, this wouldn't be quite enough; we might see a bunch of disjoint traces. We could add more constraints manually, but there's a better option: tell Forge, at `run`time, that `next` represents a linear ordering on states:

```alloy
run {
  wellformed
} for {next is linear}
```

The key thing to notice here is that `next is linear` isn't a _constraint_; it's a separate annotation given to Forge alongside a `run` or a test. Never put such an annotation in a constraint block; Forge won't understand it. These annotations narrow Forge's _bounds_ (the space of possible worlds to check) which means they can often make problems more efficient for Forge to solve.

You'll see this `{next is linear}` annotation again in lab this week. In general, Forge accepts such annotations _after_ numeric bounds. E.g., if we wanted to see full games, rather than unfinished game prefixes (remember: the default bound on `State` is 4) we could have asked:

```alloy
run {
  wellformed
  traces
} for exactly 10 State for {next is linear}
```

### Running And The Evaluator

Let's run that last command. Forge gives us an instance! But it's a little bit cluttered. 

![](https://i.imgur.com/KPxtABM.png)


We can resolve this by _projecting_ over State; you'll do this in your lab.  But Sterling also allows you to write short JavaScript visualization scripts. The following script produces game visualizations with states like this:

![](https://i.imgur.com/m6KRWtI.png)

We'll talk more about visualization scripts later.


```javascript=
const d3 = require('d3')
d3.selectAll("svg > *").remove();

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
  if(State.atom("State"+b) != null)
    printState(State.atom("State"+b), offset)  
  offset = offset + 55
}
```

### The Evaluator

Moreover, since we're now viewing a single fixed instance, we can _evaluate_ Forge expressions in it. This is great for debugging, but also for just understanding Forge a little bit better. Open the evaluator here at the bottom of the right-side tray, under theming. Then enter an expression or constraint here:

![](https://i.imgur.com/tnT8cgo.png)


Type in something like `some s: State | winner[s, X]`. Forge should give you either `#t` (for true) or `#f` (for false) depending on whether the game shows `X` winning the game.

### Optimizing

You might notice that this model takes a while to run (30 seconds on my laptop). Why might that be? Let's re-examine our bounds and see if there's anything we can adjust. In particular, here's what the evaluator says we've got for integers:

![](https://i.imgur.com/UJJUqdB.png)

Wow---wait, do we really **need** to be able to count up to `7` for this model? Probably not. If we change our integer bounds to `3 Int` we'll still be able to use `0`, `1`, and `2`, and the Platonic search space is much smaller; Forge takes under 3 seconds now on my laptop.


## Exercise

Do the [exercise for today](https://forms.gle/ecgccZ1B2fsyZ8U6A)! 
