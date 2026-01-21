#lang forge/bsl

/*
  Model of a ripple-carry adder circuit. Adapted from an Alloy model of the same by 
  Julianne Rudner. Although the carrying can be thought of as temporal, here we model 
  the entire process as one monolithic execution -- i.e., with no propagation delay.
*/

/********************/
/* Data definitions */
/********************/

// Booleans
abstract sig Bool {}
one sig True, False extends Bool {}

// Full adders, which will be chained together to form the ripple-carry adder
sig FA { 
  -- input and output bits 
  a, b: one Bool,  
  -- input carry bit
  cin: one Bool,
  -- output value
  s: one Bool,
  -- output carry bit 
  cout: one Bool
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
fun adder_S_RCA[f: one FA]: one Bool  {
  // Note: because "True" and "False" are values in the model, we cannot use them directly as Forge formulas.
  let A = (f.a = True), B = (f.b = True), CIN = (f.cin = True) |
	 ((A and B and CIN) or 
      (A and (not B) and (not CIN)) or 
      ((not A) and B and (not CIN)) or 
      ((not A) and (not B) and CIN))
	 	=> True else False
} 

// What is the output carry bit for this full adder?
fun adder_cout_RCA[f: one FA]: one Bool {
 let A = (f.a = True), B = (f.b = True), CIN = (f.cin = True) |
     ((not A and B and CIN) or 
      (A and not B and CIN) or 
      (A and B and not CIN) or 
      (A and B and CIN)) 
	    => True else False
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
        fa0.a=True
        fa0.b=True
        fa1.a=True
        fa1.b=True
        fa2.a=True
        fa2.b=True
        fa3.a=False
        fa3.b=False
        fa4.a=False
        fa4.b=False
        fa5.a=True
        fa5.b=True
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

fun trueValue[b: Bool, placeValue: Int]: one Int {
  -- TODO: for efficiency, would it be better to just use 0/1, not Bool?
  (b = True) => placeValue else 0
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



test expect {
  -- Test with a bitwidth of 9, letting us count between [-256, 255].
  -- The maximum value we expect with *6* full adders is 111111 = 63, plus 
  -- a carry bit, giving us 1111111 = 127. We aren't using the negatives. 
  r_adderCorrect: {req_adderCorrect} for 6 FA, 1 RCA, 8 Int is checked
}

-- NOTE: very high #clauses: 645459; ~86 seconds to solve (quick translation)
--   remove boolean abstract?
--   eliminate negatives? (this is a case for actual integers, since we're talking of value)


/////////////////////////////////////////////////////////////////////
// TODO: validation

