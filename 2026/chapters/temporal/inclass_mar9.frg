#lang forge/temporal

one sig Truth {}
one sig World {
    var stopped: lone Truth, // if populated, true
    var green: lone Truth
}
pred G { some World.green }
pred S { some World.stopped }

// Stopped until green

pred p1 { S until G }
pred p2 { always { S until G }}

option max_tracelength 10
option min_tracelength 10

run {}
