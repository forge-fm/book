#lang forge
-- ^ relational forge

-- Built in class Feb 21, Feb 23. 

-- Let's think about syntax... 

/*
  if( x() && (y() || !z())) {
    doSomething()
  }
  x && (y || !z) <-- what is this?
*/

-- Maps every Var to either true or false
sig Valuation {
  trueVars: set Var 
}

abstract sig Formula {
  satisfiedBy: set Valuation
} 
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


pred semantics { 
  -- set of valuations in which v is true?
  all v: Var | { -- set containment
    v.satisfiedBy = {i: Valuation | v in i.trueVars} } 
  all n: Not | { -- set subtraction
    n.satisfiedBy = Valuation - n.child.satisfiedBy} 
  all a: And | { -- intersection ("and")
    a.satisfiedBy = a.a_left.satisfiedBy & a.a_right.satisfiedBy} 
  all o: Or | { -- union ("or")
    o.satisfiedBy = o.o_left.satisfiedBy + o.o_right.satisfiedBy} 

}

-- This must hold, or else it's not good syntax!
pred wellformed {
    all f: Formula | not subFormulaOf[f, f]
    semantics
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

--run {wellformed} for 8 Formula for onlyOneAnd 

-- We'll pick this up on Friday! 

---------------------------------------------


run {
  wellformed 
  semantics
  some o: Or | {
    o.o_left in And 
    o.o_right in Var
  }
} for 8 Formula

-- 
/*
  sig Person { parent1: lone Person }
  one sig Nim extends Person {} 

  Nim.parent 
  parent1.Nim 
*/

pred equivalent[f1, f2: Formula] {
  -- logical equivalence (within the instance considered)
  f1.satisfiedBy = f2.satisfiedBy
}
pred isDoubleNegationWF[f: Formula] {
  wellformed -- added semantics here
  f in Not 
  f.child in Not 
}
assert all f: Formula | 
  isDoubleNegationWF[f] is sufficient for equivalent[f, f.child.child]

