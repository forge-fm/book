#lang forge/temporal 

open "messages.frg"
open "rpc.frg"
open "raft_2.frg"


-- Transition-system checks for combinations of transitions; no use of the trace pred yet.
test expect {
  -- All of these transitions (except the no-op) should be mututally exclusive. 
  overlap_start_make: {eventually {some s1, s2, s3: Server | startElection[s1] and makeVote[s2, s3]}} is unsat
  overlap_start_win: {eventually {some s1, s2: Server | startElection[s1] and winElection[s2]}} is unsat
  overlap_start_halt: {eventually {some s1: Server |     startElection[s1] and haltElection }} is unsat
  overlap_make_win: {eventually {some s1, s2, s3: Server | makeVote[s1, s2] and winElection[s3]}} is unsat
  overlap_make_halt: {eventually {some s1, s2: Server |     makeVote[s1, s2] and haltElection}} is unsat
  overlap_win_halt: {eventually {some s1: Server |     winElection[s1] and haltElection}} is unsat
  
  -- It should be possible to execute all the transitions. We'll encode this as specific
  -- orderings, rather than as different "eventually transition_k" checks. 

  -- Halfway through, we made sure these were all rooted in an initial state.
  
  -- Start -> Vote -> Win
  sat_start_make_win: {
    init
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (some s: Server | winElection[s])
  } for 6 Message is sat 

  -- Start -> Vote -> Halt 
  sat_start_make_halt: {
    init
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (haltElection)
  } is sat 

  -- Start -> Halt
  sat_start_halt: {
    init
    (some s: Server | startElection[s])
    next_state (haltElection)
  } is sat 
  
  -- Start -> Vote -> Win -> Start
  sat_start_make_win_start: {
    init
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (some s: Server | winElection[s])
    next_state next_state next_state (some s: Server | startElection[s])
  } is sat 

  -- Start -> Vote -> Win -> Start -> StepDown
  sat_start_make_win_start_stepdown: {
    init
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (some s: Server | winElection[s])
    next_state next_state next_state (some s: Server | startElection[s])
    next_state next_state next_state next_state (some s: Server | stepDown[s])
  } is sat
}



-- Transition-system checks that are aware of the trace predicate, but focus on interplay/ordering 
-- of individual transitions.
test expect {
  -- Cannot Halt, Vote, or Win until started -- provided non-trivial cluster
  win_implies_started: {
    electionSystemTrace implies
    (some s: Server | winElection[s]) implies 
    once (some s: Server | startElection[s])
  } is checked 
  halt_implies_started: {
    electionSystemTrace implies
    (haltElection) implies 
    once (some s: Server | startElection[s])
  } is checked 
  vote_implies_started: {
    electionSystemTrace implies
    (some s1, s2: Server | makeVote[s1, s2]) implies 
    once (some s: Server | startElection[s])
  } is checked 
}

-- Domain-specific checks involving the trace pred
test expect {
  -- No server should ever transition directly from `Leader` to `Candidate`. 
  no_direct_leader_to_candidate: {
    electionSystemTrace implies
    (all s: Server | {
      always {s.role = Leader implies s.role' != Candidate}
    })} is checked

  leader_stops_leading: {
    electionSystemTrace 
    eventually {
      some s: Server | s.role = Leader 
      eventually { 
        no s: Server | s.role = Leader
      }
    }
  } is sat

  -- It should be possible to witness two elections in a row.
  sat_two_elections_in_a_row: { 
    two_elections_in_a_row
  } is sat

  -- It should be possible for two different servers to win elections in the same trace. 
  two_different_winners_in_succession: {
    electionSystemTrace
    some disj s1, s2: Server | {
        eventually s1.role = Leader 
        eventually s2.role = Leader 
    } } is sat

  two_simultaneous_candidates: {
    electionSystemTrace
    some disj s1, s2: Server | eventually {
        s1.role = Candidate
        s2.role = Candidate
    }
  } is sat

  -- It should be invariant that there is only ever at most one `Leader`. 
  invariant_lone_leader: {
    electionSystemTrace implies
    always {lone role.Leader}
  } is checked

  -- Check that the term is being advanced (dependent on trace length settings)
  term_can_reach_3: {
    electionSystemTrace 
    eventually {some s: Server | s.currentTerm = 3}
  } is sat
}