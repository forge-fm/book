#lang forge/temporal

/*
  Model of binary search trees, basic definitions
  Tim, 2024

  Note assumptions: 
    (1) This model doesn't take duplicate entries into account; we use 
        (< or >), not (< and =>) or (<= and >)
    (2) We restrict the available keys to a subset of what the bitwidth allows. 
        This makes it more convenient to compute distances in a simple way.
*/

option solver Glucose  

sig Node {
  key: one Int,     -- every node has some key 
  left: lone Node,  -- every node has at most one left-child
  right: lone Node  -- every node has at most one right-child
}
fun descendantsOf[ancestor: Node]: set Node {
  ancestor.^(left + right) -- nodes reachable via transitive closure
}
pred binary_tree {
  -- no cycles
  all n: Node | n not in descendantsOf[n] 
  -- connected via finite chain of left, right, and inverses
  all disj n1, n2: Node | n1 in n2.^(left + right + ~left + ~right)
  -- left+right differ (unless both are empty)
  all n: Node | some n.left => n.left != n.right 
  -- nodes have a unique parent (if any)
  all n: Node | lone parent: Node | n in parent.(left+right)
}

pred bst_invariant[n: Node] {
  -- "Every node's left-descendants..." via reflexive transitive closure
  all d: n.left.*(left+right)  | d.key < n.key
  -- "Every node's left-descendants..." via reflexive transitive closure
  all d: n.right.*(left+right) | d.key > n.key
}

/** Note that `option no_overflow true` won't prevent this, because the solver might still
    give a target/current configuration where (current-target) must overflow to exist. E.g.:
      target = -1, Node.key = {-1, 7}. The distance from 7 to the target overflows to -8, 
         leading to it becoming the "minimal" distance, which is incorrect. */ 
pred restriction[i: Int] {
    // E.g., default bitwidth of 4 -> [-8. 7]. This enforces [-3, 3].
    i <= divide[max[Int], 2]
    i >  divide[min[Int], 2]
}

pred binary_search_tree {
  binary_tree  -- a binary tree, with an added invariant
  all n: Node | bst_invariant[n]  

  -- restriction for our modeling convenience 
  all n: Node | restriction[n.key]
}

run {binary_search_tree} for exactly 3 Node