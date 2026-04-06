"""
CEGIS Demo: Synthesizing abs(x) from a menu of operations. Concretely, 
this program uses Z3 to synthesize a single-static-assignment program 
(i.e., each line assigns a value, the last value is returned).

This was created by Tim in collaboration with Claude Code (Opus 4.6). 
"""

from z3 import Solver, Int, If, And, Or, sat, ArithRef

# --- Operation menu ---
# These are the "instructions" our synthesized program can use.
# We've made the design choice to have all operators be binary in the model, 
# hence ZERO ignoring both arguments and NEG ignoring the 2nd argument.
OP_ADD   = 0   # result = arg1 + arg2
OP_SUB   = 1   # result = arg1 - arg2
OP_NEG   = 2   # result = -arg1       (arg2 ignored)
OP_MAX   = 3   # result = max(arg1, arg2)
OP_ZERO  = 4   # result = 0           (both args ignored)
NUM_OPS  = 5
OP_NAMES = ["ADD", "SUB", "NEG", "MAX", "ZERO"]

# Program size: how many operator applications (i.e., how many SSA lines) 
# are available? 2 slots is enough for abs(x): e.g. t0 = NEG(x), 
# t1 = MAX(x, t0). 
NUM_SLOTS = 2

# But suppose we didn't know that! Let's try 4 operations max.
# (Of course, this can now produce a program longer than it needs to be. :-)) 
# NUM_SLOTS = 4

# Bound on input range for the verifier. We keep this finite so Z3 stays
# fast and doesn't produce astronomically large counterexamples. The CEGIS
# idea works the same way regardless of range.
INPUT_LO = -10000
INPUT_HI = 10000

def spec(x):
    """The specification we want to synthesize."""
    return If(x >= 0, x, -x)

def slot_result(op, arg1, arg2):
    """What does one instruction compute, given its operation and two arguments?
    Returns a Z3 expression."""
    return If(op == OP_ADD, arg1 + arg2,
           If(op == OP_SUB, arg1 - arg2,
           If(op == OP_NEG, -arg1,
           If(op == OP_MAX, If(arg1 >= arg2, arg1, arg2),
              0))))  # OP_ZERO

# As the program runs, each instruction produces a new variable:
#   x       (the input)
#   t0      (output of instruction 0)
#   t1      (output of instruction 1)
#   ...
# When an instruction picks its operands, it chooses which prior
# variable to read from — the input x, or a prior instruction's output.

def pick_variable(selector, variables):
    """Choose a value from the available variables based on a selector index."""
    result = variables[0]
    for i in range(1, len(variables)):
        result = If(selector == i, variables[i], result)
    return result

def run_program(ops: list, arg1s: list, arg2s: list, x) -> ArithRef:
    """Evaluate a program on input x. ops/arg1s/arg2s can be Z3 variables
    (during synthesis) or concrete Python ints (during verification).
    Either way, the return value is always a Z3 expression (ArithRef),
    because slot_result wraps everything in If(...) which produces one."""
    variables = [x]  # start with just the input
    for i in range(NUM_SLOTS):
        a1 = pick_variable(arg1s[i], variables)
        a2 = pick_variable(arg2s[i], variables)
        variables.append(slot_result(ops[i], a1, a2))
    return variables[-1]  # output = last instruction's result

def reg_name(idx) -> str:
    """Pretty-print a register index"""
    return "x" if idx == 0 else f"t{idx - 1}"

def print_program(model, ops, arg1s, arg2s) -> None:
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


# --- CEGIS loop ---

def cegis() -> None:
    # We have NUM_SLOTS lines of code to work with. 
    # Each line ("instruction slot") has an operation and two operand expressions.
    ops   = [Int(f"op_{i}")   for i in range(NUM_SLOTS)]
    arg1s = [Int(f"arg1_{i}") for i in range(NUM_SLOTS)]
    arg2s = [Int(f"arg2_{i}") for i in range(NUM_SLOTS)]

    # Z3 Int variables range over ALL integers by default. Without these
    # bounds, the solver could pick op_0 = 7 or op_0 = -3, which don't
    # correspond to any operation. Similarly, arg selectors must index
    # into variables that actually exist at that point in the program.
    # At slot i, variables 0..i are available (the input x plus i prior outputs).
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
            synth.add(output == spec(val))

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
        verif.add(candidate_output != spec(x))

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
