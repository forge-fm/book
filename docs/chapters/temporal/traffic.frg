#lang forge/temporal
option max_tracelength 10

abstract sig Color {}
one sig Red, Yellow, Green extends Color {}
abstract sig Light {
    var color: one Color
}
one sig NS, EW extends Light {}

pred init { all l: Light | l.color = Red }
pred delta {
    some changed: Light | {
        changed.color = Red => changed.color' = Green
        changed.color = Yellow => changed.color' = Red 
        changed.color = Green => changed.color' = Yellow 
        all other: Light-changed | other.color = other.color' } }
run { init and always delta }

/* Some formulas we tried include:
  - eventually always {EW.color = Green}
  - EW.color'''' = NS.color'
  - next_state EW.color = NS.color

  - prev_state next_state EW.color = NS.color 
  - next_state EW.color = NS.color prev_state 
    ^ Note these last two did _not_ produce the same result! 

  - until (see notes)
*/