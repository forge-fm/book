#lang forge/bsl 
-- TODO: rename language (TN)

/*
  Modeling binary search trees: attempt 2
*/

option run_sterling "./bst.js"
-- TODO: resolve this outside dev mode (TN)
-- TODO: persist theming (TN)

sig Node {
  key: one Int,     -- every node has some key 
  left: lone Node,  -- every node has at most one left-child
  right: lone Node  -- every node has at most one right-child
}

pred isRoot[n: Node] {
  -- a node is a root if it has no ancestor
  no n2: Node | n = n2.left or n = n2.right
}

pred wellformed {
  -- no cycles: no node can reach itself via a succession of left and right fields
  all n: Node | not reachable[n, n, left, right] 
  
  ----------------------------------
  -- *** CHANGED IN THIS VERSION ***
  ----------------------------------
  -- for _any_ pair of nodes, there is some ancestor node, such that...
  all disj n1, n2: Node | {
    some anc: Node | { 
      -- either n1 is the ancestor itself, or the ancestor reaches n1...
      ((n1 = anc) or reachable[n1, anc, left, right])
      -- ...and either n2 is the ancestor itself, or the ancestor reaches n2
      ((n2 = anc) or reachable[n2, anc, left, right]) 
    } }
  ----------------------------------
  -- *** END CHANGES ***
  ----------------------------------

  -- nodes have a unique parent (if any)
  all disj n1, n2, n3: Node | 
    not ((n1.left = n3 or n1.right = n3) and (n2.left = n3 or n2.right = n3))
}

----------------------------------
-- *** ADDED IN THIS VERSION ***
----------------------------------
-- View a tree or two
run {wellformed} for exactly 8 Node

