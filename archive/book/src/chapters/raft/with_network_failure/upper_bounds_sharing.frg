#lang forge/temporal 

/*
  This is a regression test, and the bad behavior happened in Temporal Forge. 
*/

sig A {}
sig C1 extends A {}
sig C2 extends A {}

one sig Singleton {}

sig Thing {}
one sig Thing1, Thing2, Thing3 extends Thing {}

test expect {
    // Giving a higher bound on a "one" sig should be an error. 
    --{} for exactly 2 Singleton is forge_error 
    // Giving a too-small bound on the parent of one sigs should be an error.
    --{} for exactly 2 Thing is forge_error
    

    -- Sure, and the problem is mitigated by the disjointness constraints. But why is this happening?
    -- No scope for C2 or a parent. I agree with this being unsat, but look at the bounds!
    {#C2 > 1} for exactly 3 C1 is unsat // UB(C2) = UB(C1); LB(C2) = none. 
}