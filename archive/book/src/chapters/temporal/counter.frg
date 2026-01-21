#lang forge/temporal 

-- ONLY EVER GET LASSO TRACES

option max_tracelength 10

one sig Counter {
    var counter: one Int 
}

run {
  -- RIGHT NOW, the counter = 0
  -- "right now" = first state, here
  -- initial state constraint:
  Counter.counter = 0
  -- transition constraint: 
  always { Counter.counter' = add[Counter.counter, 1]}
} for 3 Int 