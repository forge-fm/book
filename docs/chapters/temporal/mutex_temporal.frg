#lang forge/temporal

option max_tracelength 10

/*
T1: read counter (0)
T2: read counter (0)
T1: adds 1 to value (1)
T1: write new value to counter 
T2: adds 1 to value (1)
T2: write new value to counter (1)
*/

/*
  Abstract algorithm: both threads running this code 

  while(true) {
    // location: uninterested 
    this.flag = true
    // location: waiting 
    while(other.flag == true) {} // hold until their flag is lowered
    // location: in CS 
    run_critical_section_code(); // don't care details
    this.flag = false
  }
*/

abstract sig Location {}
one sig Uninterested, Waiting, InCS extends Location {}

-- We might also call this "Process" in the notes; in the 
-- _abstract_ these are the same. 
abstract sig Thread {} 
one sig ThreadA, ThreadB extends Thread {} 

-- State of the locking algorithm (AND the threads' locations)
-- "quick" conversion to temporal mode
one sig World {
  var loc: func Thread -> Location,
  var flags: set Thread
}

-- are we in an initial state RIGHT NOW?
pred init {
    all t: Thread | { World.loc[t] = Uninterested }
    no World.flags
}

pred raiseEnabled[t: Thread] {
    World.loc[t] = Uninterested 
}
pred raise[t: Thread] {
    -- GUARD
    raiseEnabled[t]
    -- ACTION
    World.loc'[t] = Waiting
    World.flags' = World.flags + t -- also a bit of framing, because =
    -- FRAME
    all t2: Thread - t | World.loc'[t2] = World.loc[t2]
}

pred enterEnabled[t: Thread] {
    World.loc[t] = Waiting
    World.flags in t -- no other processes
}
pred enter[t: Thread] {
    -- GUARD
    enterEnabled[t]
    -- ACTION
    World.loc'[t] = InCS
    -- FRAME
    World.flags' = World.flags
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
    -- FRAME
    all t2: Thread - t | World.loc'[t2] = World.loc[t2]
}

-- follow the methodology or this will be broken: 
-- GUARD + {ACTION, FRAME}
pred doNothing {
    -- GUARD
    all t: Thread | {
        not raiseEnabled[t]
        not enterEnabled[t]
        not leaveEnabled[t]
    }
    -- only if no other transitions possible 

    -- ACTION, FRAME: changing nothing
    World.loc = World.loc' 
    World.flags = World.flags'
}

-- Combine all transitions. In the past, we'd call this anyTransition 
-- or something like that.
pred delta { 
    some t: Thread | {
        raise[t] or 
        enter[t] or 
        leave[t] 
    } or 
    doNothing 
}

pred lasso {
    init -- time 0
    always { delta } -- always in the next state, we evolve using transitions
}

--run {lasso}

///////////////////////////////////////////////////////////////////
// Temporal Practice, Mar 8
///////////////////////////////////////////////////////////////////

// next_state
pred almostThere[t: Thread] {
    next_state { World.loc[t] = InCS }
}

// always 
pred beingVeryRude[t: Thread] {
    -- starting now, and forever in the trace...
    always { World.loc[t] = InCS }
}

// eventually always 
pred willBecomeVeryRude[t: Thread] {
    -- at some point in future (or right now)...
    eventually { beingVeryRude[t] }
}

pred startsBeingRudeIn4Steps[t: Thread] {
    -- starts in AT MOST 4 steps (because "always")
    -- (If we wanted "not rude until then" we need more than this)
    next_state next_state next_state next_state
        { beingVeryRude[t] }
}

-- mutual exclusion property in temporal forge 
-- (not trying to be efficient -- so not inductive approach)
pred req_mutual_exclusion {
    -- right now, this only applies to the first state
    -- (assuming this predicate isn't called within a temporal op :-))
    --#{t: Thread | World.loc[t] = inCS} <= 1
    -- so we spread the obligation across _all_ states in future (including
    -- this one...)
    always {#{t: Thread | World.loc[t] = InCS} <= 1}
}

assert lasso is sufficient for req_mutual_exclusion

-- nobody has to wait forever
pred req_non_starvation { 
    // World.loc[t] = InCS

    -- if <that> is waiting, that implies.... 
    -- better also be true for all threads
    -- not eventually always (thread is waiting)
    all t: Thread {
        -- not enough: want access to be required repeatedly!
        -- eventually { World.loc[t] = InCS }    
        -- better: enforces repetition, but a little too heavy-handed
        -- obligation is not contingent, so not robust in "real" model
        -- always eventually { World.loc[t] = InCS }
        always { World.loc[t] = Waiting implies 
                   eventually { World.loc[t] = InCS } }
    }
}

-- This fails, as expected
-- assert lasso is sufficient for req_non_starvation 

test expect {
    -- "vacuity test": if no lassos are possible, there's a huge problem.
    lassoSat: {lasso} is sat
}

----------------------------------
-- Monday, March 11
----------------------------------

-- Check optional domain predicates for consistency
test expect {
    canRaiseSomewhereInLasso: {
        lasso
        -- Note: you need to wrap quantifiers in parens or braces when used like this:
        eventually { some t: Thread | raise[t]}} is sat
    -- etc.

}