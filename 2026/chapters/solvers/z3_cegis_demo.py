"""
CEGIS Demo: Synthesizing abs(x) from a menu of operations.

This demonstrates CounterExample Guided Inductive Synthesis (CEGIS) using Z3.
We ask the solver to *build a program* that computes abs(x), by choosing which
operations to use and how to wire them together. The solver doesn't just find
numbers — it constructs a small straight-line program.

The CEGIS loop works in two phases:
  1. SYNTHESIZE: find a candidate program that works on all concrete inputs seen so far.
  2. VERIFY: check whether the candidate works on *all* inputs (in a bounded range).
     If not, the counterexample becomes a new concrete input, and we repeat.

See cegis.md for the conceptual explanation.
"""

from z3 import Solver, Int, If, And, Or, sat

# --- Operation menu ---
# These are the "instructions" our synthesized program can use.
OP_ADD   = 0   # result = arg1 + arg2
OP_SUB   = 1   # result = arg1 - arg2
OP_NEG   = 2   # result = -arg1       (arg2 ignored)
OP_MAX   = 3   # result = max(arg1, arg2)
OP_ZERO  = 4   # result = 0           (both args ignored)
NUM_OPS  = 5
OP_NAMES = ["ADD", "SUB", "NEG", "MAX", "ZERO"]

# Program size: how many instruction slots the synthesizer gets to fill.
# 2 slots is enough for abs(x): e.g. t0 = NEG(x), t1 = MAX(x, t0).
NUM_SLOTS = 2

# Bound on input range for the verifier. We keep this finite so Z3 stays
# fast and doesn't produce astronomically large counterexamples. The CEGIS
# idea works the same way regardless of range.
INPUT_LO = -100
INPUT_HI = 100

# --- Semantics ---

def slot_result(op, arg1, arg2):
    """What does one instruction compute, given its operation and two arguments?
    Returns a Z3 expression (works with both symbolic and concrete values)."""
    return If(op == OP_ADD, arg1 + arg2,
           If(op == OP_SUB, arg1 - arg2,
           If(op == OP_NEG, -arg1,
           If(op == OP_MAX, If(arg1 >= arg2, arg1, arg2),
              0))))  # OP_ZERO

def pick_register(selector, registers):
    """Choose a value from the register file based on a selector index.
    Register 0 is the input x; registers 1.. are outputs of prior instructions."""
    result = registers[0]
    for i in range(1, len(registers)):
        result = If(selector == i, registers[i], result)
    return result

def run_program(ops, arg1s, arg2s, x):
    """Evaluate a program on input x. ops/arg1s/arg2s can be Z3 variables
    (during synthesis) or concrete Python ints (during verification).
    Returns the output of the last instruction slot."""
    registers = [x]  # register 0 = input
    for i in range(NUM_SLOTS):
        a1 = pick_register(arg1s[i], registers)
        a2 = pick_register(arg2s[i], registers)
        registers.append(slot_result(ops[i], a1, a2))
    return registers[-1]  # output = last instruction's result

# --- Pretty printing ---

def reg_name(idx):
    return "x" if idx == 0 else f"t{idx - 1}"

def print_program(model, ops, arg1s, arg2s):
    """Print the synthesized program in human-readable form."""
    for i in range(NUM_SLOTS):
        op  = model.evaluate(ops[i]).as_long()
        a1  = model.evaluate(arg1s[i]).as_long()
        a2  = model.evaluate(arg2s[i]).as_long()
        name = OP_NAMES[op]
        out  = reg_name(i + 1)
        if op == OP_NEG:
            print(f"  {out} = {name}({reg_name(a1)})")
        elif op == OP_ZERO:
            print(f"  {out} = 0")
        else:
            print(f"  {out} = {name}({reg_name(a1)}, {reg_name(a2)})")
    print(f"  output: {reg_name(NUM_SLOTS)}")

# --- The specification we want to synthesize ---

def abs_spec(x):
    """The target function: absolute value."""
    return If(x >= 0, x, -x)

# --- CEGIS loop ---

def cegis():
    # Program variables — these are what the synthesizer solves for.
    # Each instruction slot has an operation choice and two operand selectors.
    ops   = [Int(f"op_{i}")   for i in range(NUM_SLOTS)]
    arg1s = [Int(f"arg1_{i}") for i in range(NUM_SLOTS)]
    arg2s = [Int(f"arg2_{i}") for i in range(NUM_SLOTS)]

    # Bounds on program variables: ops in [0, NUM_OPS), operand selectors
    # in [0, number_of_registers_available_at_that_slot).
    # At slot i, registers 0..i are available (input + prior outputs).
    prog_bounds = []
    for i in range(NUM_SLOTS):
        prog_bounds.append(And(ops[i] >= 0, ops[i] < NUM_OPS))
        prog_bounds.append(And(arg1s[i] >= 0, arg1s[i] <= i))  # can use x and prior t's
        prog_bounds.append(And(arg2s[i] >= 0, arg2s[i] <= i))

    print("=== CEGIS: Synthesizing abs(x) ===")
    print(f"Program template: {NUM_SLOTS} instruction slots")
    print(f"Available operations: {', '.join(OP_NAMES)}")
    print(f"Verification range: x in [{INPUT_LO}, {INPUT_HI}]")
    print()

    concrete_inputs = []
    iteration = 0

    while True:
        iteration += 1
        print(f"--- Iteration {iteration} ---")
        print(f"Concrete inputs: {concrete_inputs}")

        # === SYNTHESIZE ===
        # Find program variables such that the program is correct on every
        # concrete input we've accumulated so far.
        synth = Solver()
        synth.add(prog_bounds)
        for val in concrete_inputs:
            # For this specific input value, the program must match the spec.
            output = run_program(ops, arg1s, arg2s, val)
            synth.add(output == abs_spec(val))

        if synth.check() != sat:
            print("No program of this size satisfies all constraints!")
            return

        model = synth.model()
        print("Candidate program:")
        print_program(model, ops, arg1s, arg2s)

        # Extract concrete program for the verifier.
        concrete_ops   = [model.evaluate(ops[i]).as_long()   for i in range(NUM_SLOTS)]
        concrete_arg1s = [model.evaluate(arg1s[i]).as_long() for i in range(NUM_SLOTS)]
        concrete_arg2s = [model.evaluate(arg2s[i]).as_long() for i in range(NUM_SLOTS)]

        # === VERIFY ===
        # Check: does this candidate work for ALL x in the bounded range?
        # We ask Z3 to find an x where the candidate disagrees with abs(x).
        verif = Solver()
        x = Int('x')
        verif.add(And(x >= INPUT_LO, x <= INPUT_HI))
        candidate_output = run_program(concrete_ops, concrete_arg1s, concrete_arg2s, x)
        verif.add(candidate_output != abs_spec(x))

        if verif.check() != sat:
            print()
            print("=== Verified! No counterexample found. ===")
            print("Final program:")
            print_program(model, ops, arg1s, arg2s)
            return

        # There's an input where the candidate fails. Add it and try again.
        cex = verif.model().evaluate(x).as_long()
        print(f"Counterexample: x = {cex}")
        print()
        concrete_inputs.append(cex)

if __name__ == "__main__":
    cegis()
