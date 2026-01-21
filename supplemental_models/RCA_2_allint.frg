#lang forge/bsl

/*
  Model of a ripple-carry adder circuit. Adapted from an Alloy model of the same by 
  Julianne Rudner. Although the carrying can be thought of as temporal, here we model 
  the entire process as one monolithic execution -- i.e., with no propagation delay.

  This version is the performance-optimized version to illustrate:
    - how to use an optimizer instance to help the engine work more efficiently; and 
    - an example of what "mathematical ints" from SMT make unnecessary.

  TODO: in-place inst (`for {...}`) doesn't allow + in Froglet, although `inst` does. Fix!
*/

/********************/
/* Data definitions */
/********************/

// Full adders, which will be chained together to form the ripple-carry adder
sig FA { 
  -- input and output bits 
  a, b: one Int,  
  -- input carry bit
  cin: one Int,
  -- output value
  s: one Int,
  -- output carry bit 
  cout: one Int
}

// The ripple carry adder, which chains together all the full adders
one sig RCA {
  -- the first full adder in the chain
  firstAdder: one FA,
  -- the next full adder in the chain (if any)
  nextAdder: pfunc FA -> FA
}

/******************/
/* Wellformedness */ 
/******************/

pred wellformed {
  -- there's some FA upstream from all other FAs
  all fa: FA | (fa != RCA.firstAdder) implies reachable[fa, RCA.firstAdder, RCA.nextAdder]
  -- there are no cycles 
  all fa: FA | not reachable[fa, fa, RCA.nextAdder]  
}

test expect {
    {wellformed} is sat
}

/**********************************************************************/
/* System predicates: define how each full adder behaves in isolation */ 
/**********************************************************************/

// What is the output bit for this full adder?
fun adder_S_RCA[f: one FA]: one Int  {
  let A = (f.a = 1), B = (f.b = 1), CIN = (f.cin = 1) |
	 ((A and B and CIN) or 
      (A and (not B) and (not CIN)) or 
      ((not A) and B and (not CIN)) or 
      ((not A) and (not B) and CIN))
	 	=> 1 else 0
} 

// What is the output carry bit for this full adder?
fun adder_cout_RCA[f: one FA]: one Int {
 let A = (f.a = 1), B = (f.b = 1), CIN = (f.cin = 1) |
     ((not A and B and CIN) or 
      (A and not B and CIN) or 
      (A and B and not CIN) or 
      (A and B and CIN)) 
	    => 1 else 0
} 

// Constrain each full adder to behave as expected
pred add_per_unit[f: FA] {
  f.s = adder_S_RCA[f]
  f.cout = adder_cout_RCA[f]
  -- NOTE: the parens are needed on the right-hand side here.
  (some RCA.nextAdder[f]) implies (RCA.nextAdder[f]).cin = f.cout 
}

/*****************************************************/
/* Top-level system specification: compose preds above
/*****************************************************/

pred rca {  
  wellformed
  all f: FA | add_per_unit[f] 
}


// Specific example: add together 2 6-bit values. 
// Note that the ordering of full adders starts with the *least* significant bit.
// 6'b100111+6'b100111
pred example1 {
    // Because these rely on the previous, each is a separate "let"
    let fa0 = RCA.firstAdder | 
    let fa1 = RCA.nextAdder[fa0] | 
    let fa2 = RCA.nextAdder[fa1] | 
    let fa3 = RCA.nextAdder[fa2] | 
    let fa4 = RCA.nextAdder[fa3] | 
    let fa5 = RCA.nextAdder[fa4] | {
        fa0.a=1
        fa0.b=1
        fa1.a=1
        fa1.b=1
        fa2.a=1
        fa2.b=1
        fa3.a=0
        fa3.b=0
        fa4.a=0
        fa4.b=0
        fa5.a=1
        fa5.b=1
    }
}

// Run example using 6 full adders (one for each bit of input)
-- run {rca example1} for 1 RCA, exactly 6 FA

/////////////////////////////////////////////////////////////////////

// To help ease verification, augment instances with place-values of each full adder
// which we can then use to compute the "true value" of an input or output. E.g., 
// the first full adder would have place-value 1, and its successors would have 
// place-value 2, then 4, etc. 
one sig Helper {
  place: func FA -> Int
}
-- The "places" value should agree with the "nextAdder" function.
pred assignPlaces {
  -- The least-significant bit is 2^0
  Helper.place[RCA.firstAdder] = 1
  -- Other bits are worth 2^(i+1), where the predecessor is worth 2^i.
  all fa: FA | some RCA.nextAdder[fa] => {    
    Helper.place[RCA.nextAdder[fa]] = multiply[Helper.place[fa], 2]
  }
}

fun trueValue[b: Int, placeValue: Int]: one Int {
  -- TODO: for efficiency, would it be better to just use 0/1, not Bool?
  (b = 1) => placeValue else 0
}

// Requirement: the adder is correct. We phrase this as: for every full adder, the true 
// value of its output is the sum of the true values of its inputs (where "true value" means 
// the value of the boolean, taking into account its position).
pred req_adderCorrect_wrong {
  (rca and assignPlaces) implies {
    all fa: FA | { 
        -- This will fail, because carrying needs to be considered, too. 
        -- Notice how even if the model (or system) is correct, sometimes the property is wrong!
        trueValue[fa.s, Helper.place[fa]] = add[trueValue[fa.a, Helper.place[fa]], 
                                                trueValue[fa.b, Helper.place[fa]]]
    }
  }
}
pred req_adderCorrect {
  (rca and assignPlaces) implies {
    all fa: FA | { 
        -- Include carrying, both for input and output. The _total_ output's true value is equal to
        -- the the sum of the total input's true value.

        -- output value bit + output carry bits; note carry value is *2 (and there may not be a "next adder")
        add[trueValue[fa.s, Helper.place[fa]], 
            multiply[trueValue[fa.cout, Helper.place[fa]], 2]] 
        = 
        -- input a bit + input b bit + input carry bit
        add[trueValue[fa.a, Helper.place[fa]],     
            trueValue[fa.b, Helper.place[fa]],    
            trueValue[fa.cin, Helper.place[fa]]]  
        -- Notice: I don't use trailing comments much on lines, because I want to be able to easily paste 
        -- these into the evaluator.
    }
  }
}

inst optimizer {
    FA = `FA0 + `FA1 + `FA2 + `FA3 + `FA4 + `FA5
    RCA = `RCA0
    `RCA0.firstAdder = `FA0
    `RCA0.nextAdder = `FA0 -> `FA1 + `FA1 -> `FA2 + `FA2 -> `FA3 + `FA3 -> `FA4 + `FA4 -> `FA5
    a in FA -> (0 + 1)
    b in FA -> (0 + 1)
    s in FA -> (0 + 1)
    cin in FA -> (0 + 1)
    cout in FA -> (0 + 1)
    -- Note: it's somewhat annoying to say "exclude negatives" manually here for places, 
    -- since we want to allow 1, 2, 4, 8, 16, 32, 64, 128, ...
} 
    
test expect {
  r_adderCorrect: {req_adderCorrect} for 6 FA, 1 RCA, 8 Int for optimizer is checked
}

/////////////////////////////////////////////////////////////////////
// TODO: validation

