#lang forge/temporal

open "bst_defs.frg"
option max_tracelength 7 -- allow "falling off the tree" for linear 6 nodes

/*
  Model of binary search trees (focusing on nearest-neighbor search)
  Tim, 2024

  Note assumption: this model doesn't take duplicate entries into account.
*/

----------------------------------------------------------------------------------

-- Since a BST descent doesn't need to backtrack, the state can be fairly simple.
one sig SearchState {
    target: one Int,        -- fixed: the target of the search
    var current: lone Node  -- variable: the node currently being visited
}

-- Initial-state predicate for the search
pred init {    
    -- Start at the root of the tree.
    -- This formulation relies on uniqueness of the root, enforced elsewhere
    SearchState.current = 
      {n: Node | all other: Node-n | other in n.^(left+right)}
    -- No constraints on the target value
}

-- Transition predicates: descend from the current node into one of its children.
pred descendLeft {
  -- GUARD 
  SearchState.target < SearchState.current.key
  some SearchState.current.left
  -- ACTION
  SearchState.current' = SearchState.current.left
}
pred descendRight {
  -- GUARD 
  SearchState.target > SearchState.current.key
  some SearchState.current.right
  -- ACTION
  SearchState.current' = SearchState.current.right
}

-- Transition predicate: found target or a leaf; either way the search is over.
pred stop {
  -- GUARD 
  SearchState.target = SearchState.current.key or 
  (SearchState.target > SearchState.current.key and no SearchState.current.right) or 
  (SearchState.target < SearchState.current.key and no SearchState.current.left)
  -- ACTION (frame: do nothing)
  SearchState.current' = SearchState.current
}

----------------------------------------------------------------------------------
-- VALIDATION OF TRANSITION PREDICATES (SMALL EXAMPLE)
----------------------------------------------------------------------------------
test expect {
    -- let's check that these 3 transitions are mutually-exclusive
    r_l_together: {eventually {descendLeft and descendRight}} for 7 Node is unsat
    l_stop_together: {eventually {descendLeft and stop}} for 7 Node is unsat
    r_stop_together: {eventually {descendRight and stop}} for 7 Node is unsat

    -- let's check that these 3 transitions are possible to execute
    r_sat: {eventually descendRight} for 7 Node is sat
    l_sat: {eventually descendLeft} for 7 Node is sat
    stop_sat: {eventually stop} for 7 Node is sat
}

----------------------------------------------------------------------------------
-- OVERALL TRACE PREDICATE
----------------------------------------------------------------------------------

pred searchTrace {
  -- We're working with a BST
  binary_search_tree 
  -- Restrict integer range available for our modeling convenience (see bst_defs.frg)
  restriction[SearchState.target]
  -- Start in an initial state
  init
  -- Progress as follows:
  always {descendLeft or descendRight or stop}
}

/** Validation: confirm that searchTrace can be satisfied. If it can't be, then 
    when we write something like "searchTrace implies thingIWant" it will be true 
    without regard to what the thing I want is. */
assert searchTrace is sat

----------------------------------------------------------------------------------
-- REQUIREMENTS (CORRECTNESS PROPERTIES)
--   CHECKING UP TO 6 NODES
----------------------------------------------------------------------------------

/** If a node contains the search target, eventually the search will visit that node. */
pred bst_correct_for_searching {
    all n: Node | {
        n.key = SearchState.target => 
          eventually SearchState.current = n
    }
}
assert searchTrace is sufficient for bst_correct_for_searching for 6 Node

/** A less-discussed property: a nearest neighbor to the target is always present
  in one of the nodes visited. (The above property shows this for the simplest case,
  where the distance from the "nearest neighbor" is zero.) */
fun dist[x1, x2: one Int]: one Int {
    abs[subtract[x1, x2]]
}
pred bst_correct_for_nearest {
  let distances = {i: Int | some n: Node | i = dist[n.key, SearchState.target]} | 
  let nearestNeighbors = {n: Node | dist[n.key, SearchState.target] = min[distances]} | {
    {some nearestNeighbors} implies 
        eventually { 
            some SearchState.current 
            SearchState.current in nearestNeighbors
        }
  }
}
assert searchTrace is sufficient for bst_correct_for_nearest for 6 Node