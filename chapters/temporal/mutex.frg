#lang forge

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
sig State {
  loc: func Thread -> Location,
  flags: set Thread
}

pred init[s: State] {
    all t: Thread | { s.loc[t] = Uninterested }
    no s.flags
}

pred raise[pre: State, t: Thread, post: State] {
    -- GUARD
    pre.loc[t] = Uninterested 
    -- ACTION
    post.loc[t] = Waiting
    post.flags = pre.flags + t -- also a bit of framing, because =
    -- FRAME
    all t2: Thread - t | post.loc[t2] = pre.loc[t2]
}

pred enter[pre: State, t: Thread, post: State] {
    -- GUARD
    pre.loc[t] = Waiting
    pre.flags in t -- no other processes
    -- ACTION
    post.loc[t] = InCS
    -- FRAME
    post.flags = pre.flags
    all t2: Thread - t | post.loc[t2] = pre.loc[t2]
}

pred leave[pre: State, t: Thread, post: State] {
    -- GUARD
    pre.loc[t] = InCS
    -- ACTION
    post.loc[t] = Uninterested
    post.flags = pre.flags - t
    -- FRAME
    all t2: Thread - t | post.loc[t2] = pre.loc[t2]
}

-- Combine all transitions. In the past, we'd call this anyTransition 
-- or something like that.
pred delta[pre: State, post: State] { 
    some t: Thread | {
        raise[pre, t, post] or 
        enter[pre, t, post] or 
        leave[pre, t, post] 
    }
}

-- Do some consistency tests for the initial and transition predicates. 
-- If these didn't pass, and we asked Forge to find us a bad transition, 
-- it might fail because of a bug in the _model_, not a problem with 
-- the algorithm.
test expect {
    canEnter: { 
        some t: Thread, pre, post: State | enter[pre, t, post]
    } is sat
    canRaise: { 
        some t: Thread, pre, post: State | raise[pre, t, post]
    } is sat
    canLeave: { 
        some t: Thread, pre, post: State | leave[pre, t, post]
    } is sat
    canStart: { 
        some s: State | init[s]
    } is sat

}

pred good[s: State] { 
    -- what we originally wanted
    #{t: Thread | s.loc[t] = InCS} <= 1
    -- strengthening the invariant: prove something stronger
    -- to prevent spurious counterexamples to induction
    all t: Thread | s.loc[t] != Uninterested implies 
      t in s.flags
}

assert all s: State | init[s] is sufficient for good[s]
  for exactly 1 State

pred startGoodTransition[s1, s2: State] {
    good[s1] 
    delta[s1, s2]
}
assert all s1, s2: State | startGoodTransition[s1, s2]
  is sufficient for good[s2]
  for exactly 2 State

--run {}

-------------

one sig Trace {
    initialState: one State ,
    nextState: pfunc State -> State 
}

pred trace {
    init[Trace.initialState]
    all s: State | some Trace.nextState[s] implies { 
        delta[s, Trace.nextState[s]]
    }
    -- adding for demo purposes
    -- no state in trace before Trace.initialState
    no Trace.initialState.~(Trace.nextState) --- OVERCONSTRAINT :-(
}

--run {trace} for {nextState is linear}

-- "lasso" trace: trace ending in a cycle
pred lasso { 
    trace
    all s: State | some Trace.nextState[s]
    -- what's the bug here?
}
-- won't work 
--run {lasso} for {nextState is linear}