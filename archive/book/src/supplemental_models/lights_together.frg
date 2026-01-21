#lang forge 

/*
  "There's lights that are on and lights that are off."
*/

/*
-- There is a kind of thing called a university. 
sig University {}
-- There is a specific, particular university: Brown. And another, WPI
one sig Brown, WPI extends University {} 
-- but there might be _other_ Universities. 
-- If I had instead said:
abstract sig University {} 
-- then the only universities allowed would be Brown and WPI, because "abstract"
-- means that you can be a university, but you must be something more specific too.
-- without abstract, you can just be a university and nothing more specific. 
-- I can make a hierarchy: 
abstract sig University {}  -- the only universities allowed are ones that "fit" sub-types
sig TwoYear, FourYear extends University {} -- you CAN be just an anonymous TwoYear or FourYear
-- but you could also be something more specific 
one sig WPI extends FourYear {}
one sig DVC extends TwoYear {}
one sig Brown extends FourYear {}
*/

-- A status is either on or off. 
abstract sig Status {}
-- Just like "Brown University" there is only *one* object that represents "On"-ness.
-- "On" is a type. But there's only ever "one" of it. So we can use it to refer to that value.
one sig On, Off extends Status {}

-- I can have as many lights as I want. 
sig Light {
  --status: one Status, -- but each light has only one status
  --  ^ We need to allow this to change with time! So we'll re-define it:
  status: func State -> Status,
  neighbors: set Light -- my neighbors change too when my lever is pulled
}

-- run {} for exactly 5 Light

-- GEOMETRY!!!
pred wellformed { 
  -- neighbors are neighbors of each other
  -- ANY PAIR of lights you find in the instance... 
  all l1, l2: Light | {
    -- ... this has to be true.
    -- "all" can be read "any". It's short for "for all ..."
    (l1 in l2.neighbors and l2 in l1.neighbors)
    or
    (l1 not in l2.neighbors and l2 not in l1.neighbors)
  }
  -- no being your own neighbor
  all l: Light | l not in l.neighbors
}

-- HOW ARE THE LIGHTS LAID OUT?
pred puzzle_shape {
    -- Linear puzzle
    -- There are start and end lights 
    some s, e: Light | { 
        s != e 
        one s.neighbors 
        one e.neighbors 
        (s not in e.neighbors and e not in s.neighbors)

        -- Each light only has two neighbors 
        all l: Light | { 
            l = s or 
            l = e or 
            #l.neighbors = 2
        }
        -- Tim might have written this (stylistic choice, because highlights the obligation)
        -- ... but let's check to make sure that these are the same?
        --all l: Light | (l != e and l != s) implies {
        --    #l.neighbors = 2
        --}
    }
    -- s and e are only available INSIDE their squigglies (so not out here!)
    
}


pred puzzle {
  -- there is some light that starts on
  //some l: Light | l.status = On
}

-- We can tell Forge to NOT try to eliminate instances that are "the same"
-- (Definition: up to renaming atoms, but NOT shuffling any "one sig"s or fields etc.)
-- option sb 0


/*run {  
  wellformed
  puzzle_shape
} for exactly 5 Light
*/


--------------------------------------------
-- Let's find out! Seems they are equivalent
--------------------------------------------

pred way1[s, e: Light] {
    all l: Light | { 
        l = s or 
        l = e or 
        #l.neighbors = 2
    }
}
pred way2[s, e: Light] {
    all l: Light | (l != e and l != s) implies {
        #l.neighbors = 2
    }
}
-- If both of these tests pass, they are logically equivalent (UP TO THE BOUNDS GIVEN)!
assert all s,e: Light | way1[s,e] is sufficient for way2[s,e] for 10 Light
assert all s,e: Light | way2[s,e] is sufficient for way1[s,e] for 10 Light


---------------
-- Let's introduce an idea of time, so that the lights' status can change. 
sig State {}
one sig Solution {
  firstState: one State,
  nextState: pfunc State -> State, -- we want some state w/o a next state, hence pfunc
  finalState: one State -- and we choose to make this a variable
}

pred move[pre, post: State] {
  some flipped: Light | {
    -- This breaks if we ever have 3+ light values! (But we aren't.)
    flipped.status[pre] != flipped.status[post]
    all n: flipped.neighbors | n.status[pre] != n.status[post]
    
    -- "frame condition"
    all other: Light | (other != flipped and other not in flipped.neighbors) implies {
      other.status[pre] = other.status[post]
    }
  }
}

pred puzzle_moves {
  all s: State | some Solution.nextState[s] implies {
    move[s, Solution.nextState[s]]
  }
}

pred solve_puzzle {
  all l: Light | l.status[Solution.finalState] = Off
}

run {
  wellformed
  puzzle_shape
  -- trace shape (with plinear below helping)
  no Solution.nextState[Solution.finalState]
  no s: State | Solution.nextState[s] = Solution.firstState
  -- because we said plinear, not linear:
  reachable[Solution.finalState, Solution.firstState, Solution.nextState]
  puzzle_moves
  solve_puzzle

  -- interesting puzzle!
  #{l: Light | l.status[Solution.firstState] = On} = 1
} for exactly 5 Light, 5 State for {nextState is plinear}
-- ^ is plinear says that SOME of the States should be used, and when used, they form
-- a linear ordering.







