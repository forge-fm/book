#lang forge/temporal 

open "messages.frg"
open "rpc.frg"

pred logs_init {
    all s: Server | {
        no s.log -- logs begin empty

    }
}

pred processClientRequest {
    -- GUARD: this can happen at any time, provided there is a Leader. We use "some" to allow 
    -- multiple leaders to exist, but only one will receive this message.
    some s: Server | {
        s.role = Leader 
    
        -- ACTION: the leader updates its log and sends AppendEntries RPC requests to all Followers.
        -- TODO
    }
}

/** Guardless no-op */
pred log_doNothing {
    -- ACTION: no change
    log' = log

    -- Frame the network state explicitly
    --sendAndReceive[none & Message, none & Message]
    -- ^ this would prohibit election messages :/
    -- TODO: factor out message management from election system if possible
}

pred logSystemTrace {
    logs_init 
    always { 
        log_doNothing
        or
        processClientRequest // placeholder, allows log to vary
    }
}

/** Is <e> considered committed from the perspective of leader <l>? */
pred is_committed[e: Entry, l: Server] {
    // TODO
}
