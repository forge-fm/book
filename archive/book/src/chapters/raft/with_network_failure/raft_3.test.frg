#lang forge/temporal 

open "messages.frg"
open "rpc.frg"
open "raft_3.frg"

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
    election_init
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (some s: Server | winElection[s])
  } for 6 Message is sat 

  -- Start -> Vote -> Halt 
  sat_start_make_halt: {
    election_init
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (haltElection)
  } is sat 

  -- Start -> Halt
  sat_start_halt: {
    election_init
    (some s: Server | startElection[s])
    next_state (haltElection)
  } is sat 
  
  -- Start -> Vote -> Win -> Start
  sat_start_make_win_start: {
    election_init
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (some s: Server | winElection[s])
    next_state next_state next_state (some s: Server | startElection[s])
  } is sat 

  -- Start -> Vote -> Win -> Start -> StepDown
  sat_start_make_win_start_stepdown: {
    election_init
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
  -- The no-op transition can fire immediately, in a starting state, and continue to do so
  do_nothing_to_start_sat: {election_init and always {election_doNothing}} for exactly 4 Server is sat 

  -- No server should ever transition directly from `Leader` to `Canx`didate`. 
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

  -- Regression test: it is possible to run with more than 3 Servers in the cluster,
  -- where >1 becomes leader. Remember to provide sufficient messages: 1 for each request, 
  -- and (#Server - 1) replies. 
  cluster_5_two_in_succession: { 
    electionSystemTrace 
    some disj s1, s2: Server | {
      eventually s1.role = Leader 
      eventually s2.role = Leader 
  }} for exactly 5 Server, 12 Message is sat

  i_understand_ltl_maybe: { 
    (some disj s1, s2: Server | {
      eventually s1.role = Leader 
      eventually s2.role = Leader 
    })
    iff 
    (some disj s1, s2: Server | {
      eventually {
        s1.role = Leader 
        eventually s2.role = Leader 
      }
    })
  } for exactly 5 Server, 12 Message is checked
}

////////////////////////////
// Tests for network failure
////////////////////////////

test expect {
  // Failure during an election
  sat_drop_during: {electionSystemTrace and eventually {
    (some c: Server | c.role = Candidate) and network_error}} is sat
  // Failure outside an election
  sat_drop_outside: {electionSystemTrace and eventually {
    (no c: Server | c.role = Candidate) and network_error}} is sat
  // Failure can involve dropping a message
  sat_failure_drop: {electionSystemTrace and eventually {
    network_error and Network.messages' in Network.messages}} is sat
  // Failure can involve duplicating a message
  sat_failure_dupe: {electionSystemTrace and eventually {
    network_error and Network.messages in Network.messages'}} is sat

  // A failure cannot occur if the network is empty (no messages to duplicate or drop)
  unsat_failure_empty: {electionSystemTrace and eventually { 
    network_error and no Network.messages
  }} is unsat

  // If there is one message in flight, a duplication followed by a drop will be idempotent
  prop_1_dupe_drop_idempotent: {
    electionSystemTrace 
    eventually {
      one Network.messages

      network_error // duplicate
      Network.messages in Network.messages'

      next_state network_error // drop
      Network.messages'' in Network.messages'

      // Seek counterexample to idempotence. Note that dropping may not drop the same _atom_, but 
      // we need to define idempotence extensionally, i.e., by the field values of the remaining message. 
      not {
        one Network.messages''
        message_extensional_equality[Network.messages, Network.messages'']
      }
    }

  } is unsat
}