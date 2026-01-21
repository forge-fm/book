#lang forge/temporal 

/*
  A simple model of message passing. To the extent possible, this model should be 
  domain-inspecific; it can be imported and its predicates called from the transitions
  of other models. 

  NOT MODELED: message replay, message alteration in transit
*/

abstract sig Message {}
one sig Network {
    var messages: set Message 
}

/** When the system starts, there are no messages "in flight". */
pred message_init { 
    no Network.messages
}

/** Add a message to the set of messages "in flight". This is a single-change predicate: if used, it will
    preclude other message activity within a transition. */ 
pred send[m: Message] {
    m not in Network.messages
    Network.messages' = Network.messages + m
}

/** A message can also be received if it's "in flight". This is a single-change predicate: if used, it will
    preclude other message activity within a transition. */
pred receive[m: Message] {
    m in Network.messages                    -- GUARD
    Network.messages' = Network.messages - m -- ACTION
}

/** A message might be dropped. On the surface, this is the same as `receive`. This is a single-change predicate: if used, it will
    preclude other message activity within a transition. */
pred drop[m: Message] {
    m in Network.messages
    Network.messages' = Network.messages - m
}

/** We might need to send/receive multiple messages. Note that the way this is written, if there is any message
    in both the to_send and to_receive sets, it will remain "in flight".  */
pred sendAndReceive[to_send: set Message, to_receive: set Message] {
    no to_send & Network.messages
    to_receive in Network.messages
    Network.messages' = (Network.messages - to_receive) + to_send
}