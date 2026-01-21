# Relational Join

(Ported content:)
**Relational Join**

Relational join ("dot join") combines two relations by seeking common values in the rightmost column and leftmost column of its arguments. More precisely, if $A$ is arity $N$ and $B$ is arity $M$, then the join of $A$ with $B$ is the $N+M-2$-ary relation:

$${(a_1, ..., a_{N-1}, b_2, ..., b_M) | \;\exists x\; | (a_1, ..., a_{N-1}, x) \in A \text{ and } (x, b_2, ..., b_M) \in B}$$
