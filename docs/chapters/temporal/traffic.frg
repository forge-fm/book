#lang forge/temporal
option max_tracelength 10

/*
  Model of a traffic light. This version is not yet correct! (Why?)

  How would we express the property: 
    "STOPPED must stay true until GREEN"?
*/

abstract sig Color {}
one sig Red, Yellow, Green extends Color {}
abstract sig Light {
    var color: one Color
}
one sig NS, EW extends Light {}

sig Car {}
one sig Intersection {
    var stopped: set Car
}

pred init { all l: Light | l.color = Red }
pred delta {
    some changed: Light | {
        changed.color = Red => changed.color' = Green
        changed.color = Yellow => changed.color' = Red 
        changed.color = Green => changed.color' = Yellow 
        all other: Light-changed | other.color = other.color' } }
run { init and always delta }



