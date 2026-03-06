#lang forge/bsl 

/* Generating images for the book by running insts corresponding to each inst

   REMEMBER TO CHANGE THESE, IF THE EXAMPLES IN bst.test.frg CHANGE! 
   (We could use `inst` from the beginning, but that complicates the story for new users.)
*/ 

-- Import the base model we want to test. 
open "bst2.frg"

-------------------------------------------------------------------------------
-- Positive insts 
-------------------------------------------------------------------------------

-- A binary tree with no nodes should be considered well-formed.
inst p_no_nodes {
  no Node  -- there are no nodes in the tree; it is empty
}

-- A binary tree with a single node should be considered well-formed. 
inst p_one_node {
  Node = `Node0 -- there is exactly one node in the tree, named "Node0".
  no left       -- there are no left-children
  no right      -- there are no right-children
}

-- A binary tree with more than one rank should be considered well-formed. 
inst p_multi_rank {
  Node = `Node0 +                               -- rank 0
         `Node1 + `Node2 +                      -- rank 1
         `Node3 + `Node4 + `Node5 + `Node6      -- rank 2
  
  -- Define the child relationships (and lack thereof, for leaves)
  -- This is a bit verbose; we'll learn more concise syntax for this soon!
  `Node0.left = `Node1 
  `Node0.right = `Node2
  `Node1.left = `Node3
  `Node1.right = `Node4
  `Node2.left = `Node5
  `Node2.right = `Node6
  no `Node3.left  no `Node3.right 
  no `Node4.left  no `Node4.right 
  no `Node5.left  no `Node5.right 
  no `Node6.left  no `Node6.right 
}

-- An unbalanced binary tree is still well-formed.
inst p_unbalanced_chain {
  Node = `Node0 + `Node1 + `Node2 + `Node3
  
  -- Form a long chain; it is still a binary tree.
  `Node0.left = `Node1 
  no `Node0.right 
  `Node1.left = `Node2
  no `Node1.right
  `Node2.left = `Node3
  no `Node2.right 
  
  no `Node3.left  no `Node3.right 
}

-------------------------------------------------------------------------------
-- Negative insts
-------------------------------------------------------------------------------

-- A single node that is its own left-child is not well-formed. 
inst n_own_left {
  Node = `Node0 
  `Node0.left = `Node0
  no `Node0.right
}

-- A single node that is its own right-child is not well-formed. 
inst n_own_right {
  Node = `Node0 
  no `Node0.left
  `Node0.right = `Node0
}

-- A single node that's reachable via a longer cycle using both left- and right-children is not well-formed. 
inst n_mixed_cycle {
  Node = `Node0 + `Node1 + `Node2
  
  `Node0.left = `Node1 
  no `Node0.right 
  no `Node1.left
  `Node1.right = `Node2
  
  `Node2.left = `Node0
  no `Node2.right 
}

-- A "forest" of multiple, disconnected trees is not well-formed. 
inst n_forest {
  Node = `Node0 + `Node1
  no `Node0.left
  no `Node0.right 
  no `Node1.left 
  no `Node1.right 
}
-- ^ This inst fails when run; we're missing a constraint.

-- Run each, for screenshot purposes 

--run {} for p_no_nodes
--run {} for p_one_node
--run {} for p_multi_rank 
--run {} for p_unbalanced_chain 

--run {} for n_own_left 
--run {} for n_own_right 
--run {} for n_mixed_cycle
--run {} for n_forest
