#lang forge/temporal 

open "messages.frg"
open "rpc.frg"
open "raft_3.frg"
open "raft_3_logs.frg"

test expect {
    log_system_sat: {logSystemTrace} is sat
}

