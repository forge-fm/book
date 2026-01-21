#lang forge/temporal 

/*
  Traces and tests corresponding to figure 8 of the extended Raft paper. 
  These examples focus on Safety (setion 5.4). The general behavior of concern is:
    "For example, a follower might be unavailable while the leader commits several log entries, 
     then it could be elected leader and overwrite these entries with new ones; as a result, 
     different state machines might execute different command sequences."
  This concern affects 2 parts of Raft:
    - who can be elected leader; and 
    - the rules for commiting an entry.

  Concretely:
    - For S to be elected, all the committed entries from previous terms must be present on S.
      This is checked when S requests a vote. S's log must be at least as "up-to-date" as the voter's.
        "Raft determines which of two logs is more up-to-date by comparing the index and term 
         of the last entries in the logs. If the logs have last entries with different terms, 
         then the log with the later term is more up-to-date. If the logs end with the same term, 
         then whichever log is longer is more up-to-date."   
    - An entry from a prior term is not considered committed, even if it is replicated to the majority 
      of servers. (Only entries from the current term can be considered committed in this way.)
        It seems that, for simplicity, Raft doesn't try to label any uncommitted entry from a prior term 
        as committed, even if it is replicated on all servers. 
        
    This explains the caption from 8(c) which says that the entry from term 2 has been replicated on 
    the majority of servers, but is NOT committed. 

    Note this subtle wording (caps mine) to motivate the second addition.
      "a leader knows that an entry from ITS CURRENT TERM is committed once that entry is stored 
       on a majority of the servers." 
      "a leader cannot immediately conclude that an entry from A PREVIOUS TERM is committed once it 
       is stored on a majority of servers"

    *** TAKEAWAY ***
    When a server crashes (or becomes inaccessible), a currently pending entry will either be 
    considered committed or not committed after a new leader is elected, depending on whether that
    entry is replicated on a majority of servers _at the time of the election_.

    
*/

open "messages.frg"     // network
open "rpc.frg"          // RPC messages
open "raft_3.frg"       // election system
//open "raft_3_logs.frg"  // log management

// These will be available globally within this module, which will be convenient. 
one sig S1, S2, S3, S4, S5 extends Server {}
one sig E1, E2, E3, E4 extends Entry {}


pred stateA {
    // * In (a) S1 is leader and partially replicates the log entry at index 2. 
    // (I believe this means that some followers have replicated the entry, but not enough of them
    //  for the entry to be considered "committed".)
    S1.role = Leader
  /*  S1.log = 0->E1 + 1->E2 
    S2.log = 0->E1 + 1->E2
    S3.log = 0->E1
    S4.log = 0->E1
    S5.log = 0->E1*/
}
pred stateB {
    // * In (b) S1 crashes; S5 is elected leader for term 3 with votes from S3, S4, and itself, 
    //   and accepts a different entry at log index 2. 
    S5.role = Leader
   /* S1.log = 1->E1 + 2->E2 
    S2.log = 1->E1 + 2->E2
    S3.log = 1->E1
    S4.log = 1->E1
    S5.log = 1->E1 + 2->E3 */
}
pred stateC {
    // * In (c) S5 crashes; S1 restarts, is elected leader, and continues replication. At this point, the
    //   log entry from term 2 has been replicated on a majority of the servers, but it is not committed. 
    S1.role = Leader
    S1.log = 1->E1 + 2->E2 + 3->E4
    S2.log = 1->E1 + 2->E2
    S3.log = 1->E1
    S4.log = 1->E1
    S5.log = 1->E1 + 2->E3
}
pred stateD { 
    // * If S1 crashes as in (d), S5 could be elected leader (with votes from S2, S3, and S4)
    // and **overwrite the entry** with its own entry from term 3. 
    S5.role = Leader
    S1.log = 1->E1 + 2->E3 
    S2.log = 1->E1 + 2->E3
    S3.log = 1->E1 + 2->E3
    S4.log = 1->E1 + 2->E3
    S5.log = 1->E1 + 2->E3
}
pred stateE { 
    // * However, if S1 **replicates an entry** from its current term on a majority of the servers
    // before crashing, as in (e), then **this entry is committed** (S5 cannot win an election). At
    // this point all preceding entries in the log are **committed** as well.
    S1.role = Leader
    S1.log = 1->E1 + 2->E3 + 3->E4 
    S2.log = 1->E1 + 2->E3 + 3->E4 
    S3.log = 1->E1 + 2->E3 + 3->E4 
    S4.log = 1->E1 
    S5.log = 1->E1 + 2->E3
}

pred setup {
    E1.termReceived = 1
    E2.termReceived = 2
    E3.termReceived = 3
    E4.termReceived = 4
}


/** This concrete trace doesn't specify the values for a number of fields. We will use it as a 
    consistency check: can a trace with these log shapes exist? Note that the first state, 
    fig8(a), cannot be the actual first state and thus the chain is wrapped in an "eventually". */ 
pred fig8_concrete_trace_abcd {
    setup
    eventually {
        stateA
        eventually { 
            stateB
            //eventually {
            //    stateC
                //eventually { stateD }
                //}}
        }
    }
}
// pred fig8_concrete_trace_abce {
//     setup
//     eventually {
//         stateA
//         eventually { 
//             stateB
//             eventually {
//                 stateC
//                 eventually { stateE }}}}}
//             

/** Compose various systems as needed */
pred someTrace {
    // Start in an initial election state
    // all steps either take an election transition or stutter on election variables
    electionSystemTrace 
    
    // Start in an initial log state
    // all steps either take a log transition or stutter on log variables
    //logSystemTrace

    // TODO: check disjointness of guards for these two systems' transitions
}

-- Use a native SAT solver (MacOS)
-- Roughly 4 seconds translation, 4 seconds solving at up to 10 Message at trace length 5
-- (Could a partial instance be useful for anything here?)
//option solver Glucose 
option solver MiniSatProver
option core_minimization rce
option coregranularity 1
option logtranslation 1
option verbose 5
option max_tracelength 14
-- 4 startElection, 16 voteFor, 4 winElection

test expect {

    /** First, a very concrete version of these traces. Here, we describe the traces in low-level detail, 
        starting from a prefix where some operations have already been performed. */
    
    //fig8_concrete_trace_abcd_sat: { fig8_concrete_trace_abcd } for exactly 5 Server is sat
    //fig8_concrete_trace_abce_sat: { fig8_concrete_trace_abce } is sat

    /** Now, we confirm that our combined system model can indeed generate these traces. */
    fig8_concrete_trace_abcd_consistent: { someTrace and fig8_concrete_trace_abcd } 
      -- Give the translator help (24 messages could be divided any way between the 4 message types)
     
        for exactly 4 RequestVote, exactly 16 RequestVoteReply,
         exactly 0 AppendEntries, exactly 0 AppendEntriesReply
     is sat

    // TODO: concern about number of message atoms needed here. may exceed scale in the current model. 
    //  With 5 servers, every candidate will send 4 vote requests in each election, so to swap leader 3 times,
    //  we need 3*(4*2) = 24 messages minimum, including replies. Then, each of those requests is received 
    //  in a separate transition (even if replies are received at once), making the trace length longer. 


    //fig8_concrete_trace_abce_consistent: { someTrace and fig8_concrete_trace_abce }
    //  for exactly 5 Server, exactly 4 Entry, 10 Message is sat


    /** Now, let's check our definition of when an entry is considered committed. 
        We should see E4 committed in abcd, but */
    // TODO (raft_3_logs.frg)
    
}