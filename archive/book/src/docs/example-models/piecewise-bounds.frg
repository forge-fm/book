#lang froglet

sig Person {
    gradeIn: pfunc Course -> Grade
}
sig Course {}
sig Grade {}

inst sig_binds {
    Person = `Person0 + `Person1 + `Person2
    Course = `Course0 + `Course1 + `Course2
    Grade = `A + `B + `C 
}

inst all_at_once {
    sig_binds -- include contents of another `inst`
    gradeIn = (`Person0, `Course0) -> `A + 
              (`Person0, `Course1) -> `B + 
              (`Person1, `Course2) -> `C
    -- ^ Using a complete, all-at-once bound, `Person2 is disallowed from having taken courses.
}

inst per_person { 
    sig_binds -- include contents of another `inst`
    `Person0.gradeIn = `Course0 -> `A + 
                       `Course1 -> `B

    `Person1.gradeIn = `Course2 -> `C
    no `Person2.gradeIn 
    -- ^ Using piecewise bounds, we need to explicitly say `Person2 is disallowed from having taken courses.
}

-- Notice that we can't refer to A, B, or C in these tests, because we only defined them as _atoms_,
-- not sigs that constraints can refer to.
test expect {
    complete_example: {
        #Person = 3 
        some p: Person | some disj c1, c2: Course | some p.gradeIn[c1] and some p.gradeIn[c2]
    } for all_at_once is checked
    piecewise_example: {
        #Person = 3
        some p: Person | some disj c1, c2: Course | some p.gradeIn[c1] and some p.gradeIn[c2]
    } for per_person is checked
}