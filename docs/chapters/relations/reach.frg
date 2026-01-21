#lang forge
sig Person {
    friends: set Person, 
    followers: set Person
}
one sig Nim, Tim extends Person {}

pred wellformed {
    -- friends is symmetric
    all disj p1, p2: Person | p1 in p2.friends implies p2 in p1.friends 
    -- cannot follow or friend yourself
    all p: Person | p not in p.friends and p not in p.followers
}
run {wellformed} for exactly 8 Person

-----------
-- Nim is reachable from Tim via followers
-- Tim.followers
-- reachable[Nim, Tim, followers]

-- Nim is reachable from Tim via the *inverse* of followers?
-- reachable[Nim, Tim, follows] -- follows doesn't exist!

-- Nim is reachable from Tim via followers, but NOT INCLUDING
--   Tim's immediate friends in the path
-- reachable[Nim, Tim, followers-Tim.friends] -- won't work!!