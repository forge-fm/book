#lang forge/temporal
option max_tracelength 10


// STARTING HERE: let's fix the algorithm


/*
  Assumptions: Peterson Lock only works on 2 threads, so we model only
    2 threads. (We need a different algorithm if we want 3+.)

  Abstract algorithm: both threads running this code 

  while(true) {
    // location: uninterested 
    this.flag = true
    // location: halfway
    polite = me // global
    // location: waiting 
    while(other.flag == true || polite != me) {} // hold until their flag is lowered _or_ the other is being polite
    // location: in CS 
    run_critical_section_code(); // don't care details
    this.flag = false
  }
*/

abstract sig Location {}
one sig Uninterested, Halfway, Waiting, InCS extends Location {}

-- We might also call this "Process" in the notes; in the 
-- _abstract_ these are the same. 
abstract sig Thread {} 
one sig ThreadA, ThreadB extends Thread {} 

-- State of the locking algorithm (AND the threads' locations)
-- "quick" conversion to temporal mode
one sig World {
  var loc: func Thread -> Location, -- about the domain
  var flags: set Thread,            -- about the system
  var polite: lone Thread           -- about the system
}

-- are we in an initial state RIGHT NOW?
pred init {
    all t: Thread | { World.loc[t] = Uninterested }
    no World.flags
    no World.polite
}

pred raiseEnabled[t: Thread] {
    World.loc[t] = Uninterested 
}
pred raise[t: Thread] {
    -- GUARD
    raiseEnabled[t]
    -- ACTION
    World.loc'[t] = Halfway
    World.flags' = World.flags + t -- also a bit of framing, because =
    -- FRAME
    all t2: Thread - t | World.loc'[t2] = World.loc[t2]
    World.polite' = World.polite
}

pred noYouEnabled[t: Thread] {
    World.loc[t] = Halfway 
}
pred noYou[t: Thread] {
    -- GUARD
    noYouEnabled[t]
    -- ACTION
    World.loc'[t] = Waiting
    World.polite' = t
    -- FRAME
    all t2: Thread - t | World.loc'[t2] = World.loc[t2]
    World.flags' = World.flags
}

pred enterEnabled[t: Thread] {
    World.loc[t] = Waiting
    {World.flags in t  -- no other processes with flag raised
     or 
     World.polite != t -- OR someone else is being polite now
    }
}
pred enter[t: Thread] {
    -- GUARD
    enterEnabled[t]
    -- ACTION
    World.loc'[t] = InCS
    -- FRAME
    World.flags' = World.flags
    World.polite' = World.polite
    all t2: Thread - t | World.loc'[t2] = World.loc[t2]
}

pred leaveEnabled[t: Thread] {
    World.loc[t] = InCS
}
pred leave[t: Thread] {
    -- GUARD
    leaveEnabled[t]
    -- ACTION
    World.loc'[t] = Uninterested
    World.flags' = World.flags - t
    World.polite' = World.polite
    -- FRAME
    all t2: Thread - t | World.loc'[t2] = World.loc[t2]
}

-- follow the methodology or this will be broken: 
-- GUARD + {ACTION, FRAME}
pred doNothing {
    -- GUARD
    all t: Thread | {
        not raiseEnabled[t]
        not noYouEnabled[t]
        not enterEnabled[t]
        not leaveEnabled[t]
    }
    -- only if no other transitions possible 

    -- ACTION, FRAME: changing nothing
    World.loc = World.loc' 
    World.flags = World.flags'
    World.polite = World.polite'
}

-- Combine all transitions. In the past, we'd call this anyTransition 
-- or something like that.
pred delta { 
    some t: Thread | {
        raise[t] or 
        noYou[t] or
        enter[t] or 
        leave[t] 
    } or 
    doNothing 
}

pred lasso {
    init -- time 0
    always { delta } -- always in the next state, we evolve using transitions
}

-- run {lasso}

-- mutual exclusion property in temporal forge 
-- (not trying to be efficient -- so not inductive approach)
pred req_mutual_exclusion {
    always {#{t: Thread | World.loc[t] = InCS} <= 1}
}
assert lasso is sufficient for req_mutual_exclusion

// -- nobody has to wait forever
pred req_non_starvation { 
    all t: Thread {
        always { World.loc[t] = Waiting implies 
                   eventually { World.loc[t] = InCS } }
    }
}
assert lasso is sufficient for req_non_starvation 

test expect {
    -- "vacuity test": if no lassos are possible, there's a huge problem.
    lassoSat: {lasso} is sat
}

// -- Check optional domain predicates for consistency
test expect {
    canRaiseSomewhereInLasso: {
        lasso
        -- Note: you need to wrap quantifiers in parens or braces when used like this:
        eventually { some t: Thread | raise[t]}} is sat

    -----------------------------------------------------------------
    -- Here is an issue (I've reversed the test expectation so it illustrates truth,
    --  not what we perhaps expect.) Is the problem that:
    --   (1) our model makes the _very_ strong abstraction choice that threads never
    --     finish wanting access; or 
    --   (2) the scheduler may just never be allowing ThreadA to go at all?
    -- Which of these our "our problem"?
    canStop: { 
        lasso
        eventually always {World.loc[ThreadA] = Uninterested}
    } is sat
}