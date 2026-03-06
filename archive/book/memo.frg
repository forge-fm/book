#lang forge 

/*
  

*/

abstract sig Word {}
one sig Green, Pink, Circle, Square extends Word {}

abstract sig Object {
    denotedBy: set Word
}
one sig PinkCircle, GreenCircle, GreenSquare extends Object {}

pred wellformed {
    PinkCircle.denotedBy = Pink + Circle 
    GreenCircle.denotedBy = Green + Circle 
    GreenSquare.denotedBy = Green + Square
}

one Scenario {
    ask: one Word, 
    picked: one Object
}

// If we just treat the request as a set of requirements, this is ambiguous. 

run {
    wellformed
    Scenario.ask = Green
}

// But what if we assume that the set of words given is _minimal_?



