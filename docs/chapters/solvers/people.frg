#lang forge

sig Person {
  followers: set Person
}
one sig Alice, Bob, Charlie extends Person {}
test expect {
    {some followers} for 4 Person is sat 
}

pred myPred[p1, p2: Person] { p1 in p2.followers }
run {some p1, p2: Person | myPred[p1,p2]} 
  for exactly 3 Person
run {some followers} for exactly 3 Person
