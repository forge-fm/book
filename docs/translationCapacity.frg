#lang forge

option verbosity 2
sig Interface {}
sig IP {}
sig ForwardingTable {
  posture: set Interface -> IP -> IP -> Interface
}
-- Too large:
run {} for 1 Interface, 1 IP, 1 ForwardingTable, 7 Int
-- OK:
-- run {} for 1 Interface, 1 IP, 1 ForwardingTable, 1 Int


