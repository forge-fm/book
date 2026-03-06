#lang forge/bsl 

-- Let's start from a fragment of the intro-modeling homework...
sig Person {
    spouse: lone Person, 
    parent1: lone Person,
    parent2: lone Person
}

-- Our sole purpose here is to _understand the reachable built-in predicate_
-- We won't write or use a well-formedness predicate, etc. because we aren't 
-- actually doing the homework! 

-- In practice, you might write the same style of some of these tests before 
-- writing an implementation, and then use Toadus to see if you're on the right track. 

-- Finally, we'll focus on assertions and satisfiability-tests here, not examples.


-----------------------------------
-- What ought to be true of `reachable`? Let's try some examples.
-- "If B is A's father, then B is reachable from A using all the family fields"
--  (Note we said _nothing else_ about any other part of the instance!)
pred a_fatherof_b[a, b: Person] { a.parent1 = b}
--pred BAD_a_fatherof_b[a, b: Person] { a.parent1 = b and a.parent1 !=b}
assert all a, b: Person | a_fatherof_b[a, b] is sufficient for 
                          reachable[b,a,spouse,parent1,parent2]

pred notReachable[x: Person, y: Person] { 
    not reachable[x, y, spouse, parent1, parent2]
}
assert all a, b: Person | a_fatherof_b[a, b] is sufficient for 
                          notReachable[a,b]

-- test that a_fatherof_b is satisfiable 
test expect { 

    a_fatherof_b_SAT: {
        some a, b: Person | a_fatherof_b[a,b]
        -- wellformed -- this would check CONSISTENCY 
        --   between a father existing and wellformed

    } 
      is sat
}

-- Note that, if we had misunderstood the directionality of arguments, and written...
// assert all a, b: Person | 
//   a_fatherof_b[a, b] is sufficient for 
//   reachable[a,b,spouse,parent1,parent2]
-- This fails!




