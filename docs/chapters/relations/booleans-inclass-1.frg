#lang forge/bsl 
-- Built in class Feb 21, Feb 23. 

-- Let's think about syntax... 

/*
  if( x() && (y() || !z())) {
    doSomething()
  }
  x && (y || !z) <-- what is this?
*/

abstract sig Formula {} 
sig Var extends Formula {} 
sig Not extends Formula {child: one Formula} 
sig And extends Formula {a_left, a_right: one Formula} 
sig Or extends Formula {o_left, o_right: one Formula} 

-- NOTE WELL! IF YOU ADD NEW FORMULA TYPES, MAKE SURE
--   THEIR FIELDS ARE REPRESENTED HERE!!!!!!!
pred subFormulaOf[anc: Formula, des: Formula] { 
    -- Dec. is reachable from anc.
    reachable[des, anc, a_left, a_right, 
                        o_left, o_right, 
                        child]
}

-- This must hold, or else it's not good syntax!
pred wellformed {
    all f: Formula | not subFormulaOf[f, f]
}
pred notWellformed { not wellformed }

pred trivialLeftCycle { 
    -- some And who is their own left child 
    -- _generalizes_ an example
    some a: And | a.a_left = a 
}
assert trivialLeftCycle is sufficient for notWellformed

inst onlyOneAnd {
  And = `And0
  Var = `Var0 + `Var1
  Formula = And + Var -- _no_ other atoms
} -- like an example, but partial and reusable

run {wellformed} for 8 Formula for onlyOneAnd 

-- We'll pick this up on Friday! 