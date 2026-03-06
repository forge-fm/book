
<!-- This will be ignored by the mdbook parser -->
<!-- # Logic for Systems: Lightweight Formal Methods for the Practical Engineer -->
# Summary 
[How to Read this book](./welcome.md)
<!-- [TEMP: todos index](./todo.md) -->
<!-- "prefix chapters"; cannot be nested -->

# Preamble: Beyond Testing
- [What good is this book?](./chapters/manifesto/job.md) 
- [Logic for Systems](./chapters/manifesto/manifesto.md)
- [From Tests to Properties](./chapters/properties/pbt.md)

# Modeling Static Scenarios
- [Tic-Tac-Toe](./chapters/ttt/ttt.md)             
- [Binary Search Trees](./chapters/bst/bst.md)     
- [Ripple-Carry Adder](./chapters/adder/rca.md)   
- [Q&A: Static Modeling](./chapters/qna/static.md) 

# Discrete Event Systems
- [Transitions, Traces, and Verification](./chapters/ttt/ttt_games.md)
- [Counterexamples to Induction](./chapters/inductive/bsearch.md)
- [BSTs: Recursive Descent](./chapters/bst/descent.md)
- [Validating Models](./chapters/validation/validating_events.md) 
- [Q&A: Event Systems](./chapters/qna/events.md) 

# Modeling Relationships 
- [Relational Forge, Modeling Logic](./chapters/relations/modeling-booleans-1.md)
- [Transitive Closure](./chapters/relations/reachability.md)
- [Modeling Mutual Exclusion](./chapters/relations/sets-induction-mutex.md)
- [Going Beyond Assertions](./chapters/relations/sets-beyond-assertions.md)
<!-- - [Reference-Counting Memory Management (FILL; low priority)]() -->
- [How does Forge Work?](./chapters/solvers/bounds_booleans_how_forge_works.md)
- [Q&A: Relations](./chapters/qna/relations.md) 

# Temporal Specification
- [Liveness and Lassos](./chapters/temporal/liveness_and_lassos.md)
- [Temporal Forge](./chapters/temporal/temporal_operators.md)
- [Linear Temporal Logic](./chapters/temporal/temporal_operators_2.md)
- [Obligations and the Past](./chapters/temporal/obligations_past.md)
- [Mutual Exclusion, Revisited](./chapters/temporal/fixing_lock_temporal.md)
- [Testing Temporally](./chapters/temporal/testing_temporal.md)
<!-- - [Q&A: Temporal Logic (FILL; any not covered before?)]()  -->

<!--  
## Tomorrow and Tomorrow and Tomorrow (Temporal Forge)

  - Relational: Mutual exclusion: "Lock 1" from 1760 (raising flags)
      - Back to induction: mutual-exclusion preserved
      - But non-starvation is more subtle, calls for more language power!

  - Temporal: basic model (counter, lights puzzle) LTL, liveness, and lassos
      - eventually, always, next state
      - until
      - past-time operators

  - Temporal: Lock1: Deadlock vs. Livelock
      - Modeling "Oops" for Lock1

  - Temporal: "Lock 2" from 1760 (polite processes)
      - Modeling "Oops" for Lock2: The importance of a good domain model

  - Temporal: Peterson's lock (combining Lock1 + Lock2)
      - Fairness: precondition or property?

  - Validation (part 3): temporal pitfalls
  -->

<!-- ## Case Studies: Applications and Demos

  - Policy / firewall analysis, control
    - Reading: Zelkova, Azure
    - Demo: ABAC language

  - Crypto
    - Reading: CPSA, ProVerif, (+ the one with pictures we cited)
    - Demo: Needham-Schr. Language

  - Synthesis
    - Reading: SSA bit-vector function synthesis, SyGuS
    - Demo: Resistor / novelty clock language

  - …many more…

  - Model-based testing (“stateful testing”) 
     - Hypothesis
     - (Need a good MBT example to use Forge for test generation. Another DSL input?) -->


  
<!-- ## Forge documentation (living document)

- Docs and book should be combined. -->

<!-- ## Modeling Tips

- Guide to debugging models
  - the evaluator 
  - cores 
- tips and tricks
- modeling pitfalls (a la Jackson) – higher-order quant, bounds, etc.  
 -->
# Boolean Solver Algorithms
  - [Boolean SAT (DPLL)](./chapters/solvers/dpll.md)
  - [Witnessing Unsat: Propositional resolution](./chapters/solvers/resolution.md)

<!-- 
  - SMT: eager vs. lazy, boolean skeletons
  - SMT: example theory solver: integer inequalities

  - CEGIS

  - Decidability, completeness, and incompleteness -->

# Beyond SAT
- [Satisfiability Modulo Theories (SMT)](./chapters/solvers/smt.md) 
- [Learning with Solvers: CEGIS](./chapters/solvers/cegis.md)

# Case Studies and Further Reading
- [Modeling Raft in Anger]()
<!-- (./chapters/raft/raft.md) -->
- [Forge: Comparing Prim's and Dijkstra's Algorithms]()
<!-- - [Model-Based ("Stateful") Testing]() -->
<!-- - [Industry: Concolic Execution (DEMO: KLEE)]()  -->
<!-- - [Forge+Industry: Policy and Network Analysis (e.g., Margrave, Zelkova)]() -->
<!-- - [Forge+Industry: Crypto Protocol Analysis (crypto lang, CPSA)]() -->
<!-- - [Program Synthesis (SSA synth, Sygus)]()  -->
<!-- - [Further Reading]() -->
<!-- (./further_reading.md) -->


<!-- ## Exercises

Python:
  - PBT
Froglet:
  - ABAC + Intro Froglet (family trees)
  - Physical keys and locks
  - Curiosity Modeling (hard to put into a textbook, but can frame it)
Relational Forge:
  - Memory management
Temporal Forge:
  - River crossing, correspond. between puzzles
  - Tortoise and Hare algorithm
  - Elevators
Algorithms:
  - SAT + PBT
  - SAT + Resolution + PBT
SMT:
  - Pythagorean triples
  - Kenken
  - Synthesis

-->
