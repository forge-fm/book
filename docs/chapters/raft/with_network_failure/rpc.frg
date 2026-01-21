#lang forge/temporal 

/*
    Modeling (a subset of) Raft's RPC messages.
    
    We've moved the Role and Server definitions here.
*/

open "messages.frg"

abstract sig Role {}
one sig Follower, Candidate, Leader extends Role {}

sig Server {
    var role: one Role,
    var votedFor: lone Server, 
    var currentTerm: one Int,
    var log: pfunc Int -> Entry
}

/** Now we need a notion of intended sender and receiver. */
sig RaftMessage extends Message {
    from, to: one Server
}

/** "each entry contains command for state machine, 
     and term when entry was received by leader" 
     
  We'll abstract out state-machine commands for the moment. 
  
  TODO: concern: what if termReceived differs across servers?
  */
sig Entry {
  termReceived: one Int
}

/**
  From figure 2:
  Arguments: 
    term  (candidate’s term)
    candidateID (candidate requesting vote)
    lastLogIndex (index of candidate’s last log entry)
    lastLogTerm (index of candidate’s last log term)
  Results:
    term: currentTerm, for candidate to update itself
    voteGranted: true means candidate received vote

Receiver implementation:
  1. Reply false if term < currentTerm (§5.1)
  2. If votedFor is null or candidateId, and candidate’s log is at
     least as up-to-date as receiver’s log, grant vote (§5.2, §5.4)
*/
sig RequestVote extends RaftMessage {
    requestVoteTerm: one Int, 
    candidateID: one Server, 
    lastLogIndex: one Int,
    lastLogTerm: one Int
}
sig RequestVoteReply extends RaftMessage {
    replyRequestVoteTerm: one Int, 
    voteGranted: lone Server -- represent true boolean as non-empty
}

/**
  From figure 2:

  Arguments:
    term (leader’s term)
    leaderId (so follower can redirect clients)
    prevLogIndex (index of log entry immediately preceding new ones)
    prevLogTerm (term of prevLogIndex entry)
    entries[] (log entries to store (empty for heartbeat; may send more than one for efficiency))
    leaderCommit (leader’s commitIndex)
Results:
    term (currentTerm, for leader to update itself)
    success (true if follower contained entry matching prevLogIndex and prevLogTerm)

Receiver implementation:
  1. Reply false if term < currentTerm (§5.1)
  2. Reply false if log doesn’t contain an entry at prevLogIndex
     whose term matches prevLogTerm (§5.3)
  3. If an existing entry conflicts with a new one (same index
     but different terms), delete the existing entry and all that
     follow it (§5.3)
  4. Append any new entries not already in the log
  5. If leaderCommit > commitIndex, set commitIndex = min(leaderCommit, index of last new entry)
*/
sig AppendEntries extends RaftMessage {
    appendEntriesTerm: one Int, 
    leaderID: one Server, 
    prevLogIndex: one Int, 
    prevLogTerm: one Int, 
    entries: set Entry,
    leaderCommit: one Int
}
sig AppendEntriesReply extends RaftMessage {
    appendEntriesReplyTerm: one Int, 
    success: lone Server -- represent true boolean as non-empty
}


/** A message might be duplicated. This asserts that another Message atom exists (in flight), having 
    the same content as the other. */
pred duplicate[m1: Message] {
    m1 in Network.messages
    // m2 must be un-used currently
    some m2: Message - Network.messages | { 
        // *** THEY MUST BE THE SAME KIND OF MESSAGE, AND HAVE SAME FIELD VALUES ***
        message_extensional_equality[m1, m2]
        Network.messages' = Network.messages + m2
    }
}

/** Helper to keep a server's state constant. Useful in composition. */
pred frame_server[s: Server] {
  s.role' = s.role
  s.votedFor' = s.votedFor
  s.currentTerm' = s.currentTerm
}

/** Helper to judge field-equality. 
    NOTE WELL: this must be expanded if more messages are added or fields are changed. 
*/ 
pred message_extensional_equality[m1, m2: Message] { 
  m1 in RaftMessage => {
    m2 in RaftMessage
    m1.from = m2.from
    m1.to = m2.to
  }
  m1 in RequestVote => {
    m2 in RequestVote
    m1.requestVoteTerm = m2.requestVoteTerm
    m1.candidateID = m2.candidateID
    m1.lastLogIndex = m2.lastLogIndex
    m1.lastLogTerm = m2.lastLogTerm
  }
  m1 in RequestVoteReply => {
    m2 in RequestVoteReply
    m1.replyRequestVoteTerm = m2.replyRequestVoteTerm
    m1.voteGranted = m2.voteGranted
  }
  m1 in AppendEntries => {
    m2 in AppendEntries
    m1.appendEntriesTerm = m2.appendEntriesTerm
    m1.leaderID = m2.leaderID
    m1.prevLogIndex = m2.prevLogIndex
    m1.prevLogTerm = m2.prevLogTerm
    m1.entries = m2.entries
    m1.leaderCommit = m2.leaderCommit
  }
  m1 in AppendEntriesReply => {
    m2 in AppendEntriesReply
    m1.appendEntriesReplyTerm = m2.appendEntriesReplyTerm
    m1.success = m2.success
  }
}

/** Transition predicate: the network performs some error behavior. */
pred network_error { 
  // One of the various flavors of error occurs
  (some m: Network.messages | drop[m])
  or 
  (some m: Network.messages | duplicate[m])

  // Server state remains the same 
  all s: Server | frame_server[s]
}