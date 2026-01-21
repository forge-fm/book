# 21: Debugging and Testing Temporal Models

###### tags: `Tag(sp22)`

**UPDATE: If you're running Windows, there is a fix to a  freeze bug in version 1.5.0. Update if you haven't already!**

Some notes:

* Milda Zizyte is giving a guest lecture next Wednesday. Attend virtually or physically! She'll be talking about 1710-related content in hybrid systems (think robots).
* MC1 extended by a day (MC2 out as planned, but also extended---minimize disruption of everyone's schedule for possible travel etc.)
* Autograding is sometimes tough, especially for new assignments. Consider: under-specification not just in semantics but in **syntax**: where does `always` go? Inside the property predicate? Outside the property predicate?
* There will be a new Forge version coming soon. (Some error improvements, but more importantly printing the instance that witnesses an `unsat` or `theorem` test failure. I'd like this to go to Sterling, but I can't promise that quickly.)
* Also trying to discover if there's a Windows-only freeze problem in the engine, when there's lots of quantification.

## Model Checking 1 Commentary

`root` is not the top of the stack; is the bottom. This isn't very realistic, even I was confused a bit after having paged out the assignment! It is admittedly contrived, and exists only to get you practice using reachability and transitive closure.

How to write the "top of stack" helper? It can be either a `fun` or `pred`. The key is: what _describes_ the top of the stack? Perhaps these would be a good start:
  * reachable from root
  * "the last one" (no next?)

If you want to turn that into a function, you can use set comprehension, e.g.,  `{e: Element | ...}`. 

### Linearity

Don't use `next is linear` on Stack. While it might work nominally, there are risks in a partially-constructed model. Can make some debugging tricks below more difficult, since cores don't know about bounds annotations.

## Test blocks vs. Examples

Examples in temporal mode are only good for talking about _one state_ traces. You can't use priming on the left-hand side of a bind, and you can't refer to state objects on the right-hand side. 

Moreover, because of how bounds are passed to the engine, bounds in an example apply to _all_ states. So beware! See this example:

```alloy
#lang forge

option problem_type temporal

abstract sig Color {}
sig Red, Yellow, Green extends Color {}
one sig Light {
  var colors: set Color
}

pred init {
  -- get away without mentioning Light, since it's just an empty set 
  no colors -- arity 2 empty (none->none)
}

pred tick {
    -- add colors, never remove them
    colors in colors'
}

test expect {
    aTest: {
        init        
        no colors -- first state, so consistent with init!
    } is sat
    aTest2: {
        init        
        no colors -- first state, so consistent with init!
        colors' = Light->Red
    } is sat
}

-- looks great, right?
example anExample is {init} for {    
    no colors
}

example anExample2 is {init} for {    
    no colors
    colors' = Light->Red
}
-- "Invalid bind: (= (prime (Relation colors)) (-> (Sig Light) (Sig Red)))"
--    What?
```

## Avoiding Quantification

Unnecessary quantification causes branching; eliminate this when possible! Consider this example: 

```alloy

pred push[e : one StackElement] {
    some oldTop : StackElement | {        
        oldTop = topElement[Stack]
        // ...
    }
}
```

Instead, either use `let` to give a name to the result of the helper, or just use the helper expression.

## Writing Tests, Unsat, Scaling

Some of you are experiencing a problematic difference in performance (seemingly mostly on Windows). We're looking into this, but for now, here are some workarounds. 

The fragment below is taken from a student's question, so it's incomplete:

```alloy

// No spoilers above (from an EdStem post)

// Large divergence in performance:
//    - Tim's laptop: ~5 seconds vs Tim's desktop never finishing (outside VSCode)
// Mitigations:
//    - lower level of detail
//    - use a testing module to leverage bounds in your favor
//      `inst` syntax doesn't leverage bounds well in temporal mode,
//      so use "one" sigs to identify c1, c2, ... that you'd normally `some` quantify
//      do this in a separate module to avoid cluttering the main model
test expect {
    
    exampleMoreDetailed: {
		some c1, c2, c3: Cell, v1, v2, v3, v4: Value | {
			-- Make sure cells are distinct
			next = c1->c2 + c2->c3 + c3->c1
			isRing

			-- State 0
			no content
			Read.ref = c1
			Write.ref = c1

			-- State 1
			content' = c1->v1
			Read.ref' = c1
			Write.ref' = c2

			-- State 2
			content'' = c1->v1 + c2->v2
			Read.ref'' = c1
			Write.ref'' = c3

			-- State 3
			content''' = c1->v1 + c2->v2 + c3->v3
			Read.ref''' = c1
			Write.ref''' = c1

			-- State 4
			content''' = c1->v1 + c2->v2 + c3->v3
			Read.ref''' = c1
			Write.ref''' = c2

			-- Checking predicates
			writeValue[v1]
			next_state writeValue[v2]
			next_state next_state writeValue[v3]
			next_state next_state next_state writeValue[v4]
        }
    } is unsat
}
```

### Reduce granularity, speak in broad strokes (lower detail test)

This test can be rewritten:

```alloy
     exampleLessDetailed: {
      some v1, v2, v3, v4: Value | {
          -- Make sure cells are distinct         
          isRing

          -- State 0
          init
          -- Checking predicates
          writeValue[v1]
          next_state writeValue[v2]
          next_state next_state writeValue[v3]
          next_state next_state next_state writeValue[v4]
      }
    } for exactly 3 Cell is unsat
```    

It's less detailed, but requires less quantification.

If we weren't in temporal mode, this would be a great time for an `example` or `inst`. Unfortunately, we are.

### INSIDE temporal mode: use separate testing module and `one` sigs

The key is to reduce symmetry. We can still do that by adding `one` sigs to represent the constant values and cells in the test. I suggest creating a separate Forge file for this:

```alloy
#lang forge

-- whatever the base model is called
open "detailed_test.frg"

one sig c1, c2, c3 extends Cell {}
one sig v1, v2, v3, v4 extends Value {}

test expect {
  -- copied verbatim
  -- #vars: (size-variables 6397); #primary: (size-primary 590); 
  -- #clauses: (size-clauses 11527)  vs. (original module)
  -- #vars: (size-variables 11713); #primary: (size-primary 765); 
  -- #clauses: (size-clauses 21831)
  separateTest: {
			-- Make sure cells are distinct
			next = c1->c2 + c2->c3 + c3->c1
			isRing

			-- State 0
			no content
			Read.ref = c1
			Write.ref = c1

			-- State 1
			content' = c1->v1
			Read.ref' = c1
			Write.ref' = c2

			-- State 2
			content'' = c1->v1 + c2->v2
			Read.ref'' = c1
			Write.ref'' = c3

			-- State 3
			content''' = c1->v1 + c2->v2 + c3->v3
			Read.ref''' = c1
			Write.ref''' = c1

			-- State 4
			content''' = c1->v1 + c2->v2 + c3->v3
			Read.ref''' = c1
			Write.ref''' = c2

			-- Checking predicates
			writeValue[v1]
			next_state writeValue[v2]
			next_state next_state writeValue[v3]
			next_state next_state next_state writeValue[v4]
        
    } is unsat

}
```

This is just the original test verbatim, but without the quantifiers. It finishes quickly.

## Debugging Unsat

Debugging an unsatisfiable run can be challenging. I want to step through the process I usually follow, based on (a fragment of) a student's question on EdStem. This is meant to exist within the buffer problem:

```alloy
///////////////////////
// avoid spoilers above, from EdStem
//   not claiming anything is RIGHT; useful ex. for debugging

pred traces {
  init
  -- is ring
  isRing
  always (some v: Value | writeValue[v] or readValue[v])
}

test expect {
    cycle2: {        
        traces        
    } for exactly 2 Cell is sat
    cycle3: {
        traces        
    } for exactly 3 Cell is sat
}
```

We would expect both tests to pass. Unfortunately, `exactly 3 Cell` does not. What's the problem?

### Step 1: (Experimental) Unsat Cores

Forge has an experimental option to try and find a _minimal_ subset of the constraints that are responsible for unsatisfiability. Add the following 4 lines to your spec if you want to use the feature:

```alloy
-- experimental 
option solver MiniSatProver
option logtranslation 1
option coregranularity 1
option core_minimization rce
```

The console output will include a list of line numbers that, together, yield unsat (under the bounds given). At the moment, the output sometimes involves references to Forge's library. E.g., in this example, we got a reference to line 638 of a certain file, which is where Forge issues constraints for `one` or `func` fields. 

Try this on a spec of your own! Just remember to disable the 4 options when you're done, as they can impact performance.

In this case, there's not much in the core: `init`, for instance, isn't included. The `always ...` formula, however, is. 

### Debugging when `always` is involved

The core in this case pointed to the `always`. To debug this further, we'll _unroll_ it to specify:
* a trace of 1 state
* a trace of 2 states
* a trace of 3 states ...
until we either discover that a trace of $k$ states can't be produced, or we've concretized an example enough that running the unrolled constraint and opening it in Sterling will give us some insight into the problem.

### The Problem

Mantra: "the problem might be caused by temporal mode looking only for lassos". In this case, it turned out that we didn't give Forge enough states to build a lasso using those transitions. To fix this, we'll increase the trace length (6 suffices, but let's make it 10):

`option max_tracelength 10`

## Testing the Model vs. "Testing" the System

Recall that there are two very different kinds of "tests" in Forge. Consider these two:

* "Is the `push` predicate over-constrained?"
* "Does the stack data structure obey the property that for any stack and value, pushing the value and then popping results in the same stack as originally? Not Forge notation, but mathematically if $push: Stack \times Value \rightarrow Stack$ and $pop: Stack \rightarrow (Stack \times Value)$, then: $pop(push(s, v)) = (s, v)$"

The first is about checking the model is a reasonable approximation of the system we're trying to understand through the model. The second is using the model to learn something about the system (modulo the model's correctness and sufficient detail). Don't confuse these.