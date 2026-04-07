"""
CEGIS Demo: Synthesizing programs from a menu of operations with Z3. 

Design choices:
  * The programs are single-static-assignment: each line assigns a value, and 
    the last value is returned. This avoids the complexity of using the 
    theory of datatypes, or making our own relational structure. It also 
    avoids loop synthesis, which would complicate things even more.
  * We're using integers here rather than bit-vectors. This keeps specs simpler,
    but a real production synthesizer (for fixed-length int languages) would 
    use the theory of bit-vectors instead.
  * The space of potential programs is finite: there are only so many 
    lines of code allowed. This helps avoid ForAll in the model.

This was created by Tim in collaboration with Claude Code (Opus 4.6).

Note on types:
  I like static types, but Z3 doesn't always play nicely with Python type checking. 
  As a result, I've done some "type gymnastics" here. You can probably ignore them.

"""

from z3 import Solver, Int, IntVal, sat, ArithRef, ExprRef, BoolRef, IntNumRef
import inspect
from z3 import If as _If, And as _And
from typing import overload

#####################################################################
# Type gymnastics (keep scrolling)
#####################################################################

@overload
def If(a: ExprRef, b: ArithRef, c: ArithRef) -> ArithRef: ...
@overload
def If(a: ExprRef, b: int, c: int) -> ArithRef: ...
def If(a, b, c): 
      """
      Z3 doesn't always play nicely with Python's type inspection. In particular,
      Python won't infer that the two branches having type T means the IF has type T itself.
      """
      return _If(a, b, c) # type: ignore

def And(*args: BoolRef) -> BoolRef:
      """Z3's And is typed to return BoolRef | Probe | Unknown. We only use the BoolRef case."""
      return _And(*args) # type: ignore

def Z3_MULTIPLY(x: ArithRef, y: ArithRef) -> ArithRef:
    return x * y # type: ignore

def TO_LONG(x) -> int:
    assert isinstance(x, IntNumRef), f"Expected IntNumRef, got {type(x)}"
    return x.as_long()

#####################################################################
# Setup: available operations, bounds on integers considered, etc.
#####################################################################

# --- Operation menu ---
# These are the "instructions" our synthesized program can use.
# We've made the design choice to have all operators be binary in the model,
# hence ZERO ignoring both arguments and NEG ignoring the 2nd argument.
OP_ADD   = 0   # result = arg1 + arg2
OP_SUB   = 1   # result = arg1 - arg2
OP_NEG   = 2   # result = -arg1       (arg2 ignored)
OP_MAX   = 3   # result = max(arg1, arg2)
OP_MIN   = 4   # result = min(arg1, arg2)
OP_BIT0  = 5   # result = arg1 % 2    (lowest bit; arg2 ignored)
OP_SHR1  = 6   # result = arg1 / 2    (right-shift by 1; arg2 ignored)
OP_ONE   = 7   # result = 1           (both args ignored)
OP_ZERO  = 8   # result = 0           (both args ignored)
NUM_OPS  = 9
OP_NAMES = ["ADD", "SUB", "NEG", "MAX", "MIN", "BIT0", "SHR1", "ONE", "ZERO"]

# Bound on input range for the verifier. The CEGIS idea works the same
# regardless, but we want to keep the demo small.
INPUT_LO = -10000
INPUT_HI = 10000

#####################################################################
# Specifications: a few example programs we want to synthesize.
#####################################################################

# Each spec is just a Python function that takes a number of Z3 expressions (the inputs)
# and returns a Z3 expression (the expected output). The CEGIS procedure infers the 
# number of inputs from the spec's signature.

def abs_spec(x: ArithRef) -> ExprRef: 
    """abs(x): absolute value of the argument"""
    return If(x >= 0, x, -x)

def max3_spec(x: ArithRef, y: ArithRef, z: ArithRef) -> ArithRef:
    """max(x, y, z): maximum of the _three_ arguments"""
    cond: BoolRef = And(x >= y, x >= z)
    return If(cond,
              x,
              If(y>=z, y, z))

def clamp_spec(x: ArithRef, lo: ArithRef, hi: ArithRef) -> ArithRef:
    """clamp(x, lo, hi): x "clamped" to [lo, hi].
    Only meaningful when lo <= hi. Behavior is undefined otherwise."""
    return If(x < lo, lo, If(x > hi, hi, x))

def mul_spec(x: ArithRef, y: ArithRef) -> ArithRef:
    """mul(x, y): multiplication. This should be impossible to synthesize
    with the available operations."""
    return Z3_MULTIPLY(x, y)

def ones_spec(x: ArithRef) -> ArithRef:
    """Counts the number of 1-bits in the binary representation of x.
    Only meaningful for non-negative x. We also make a substantial 
    restriction to keep the demo small and performant: only the first 
    3 bits are considered (division is expensive). A real tool would
    use the theory of bit-vectors instead."""
    # Unroll the bit extraction for 3 bits: x%2 + (x/2)%2 + (x/4)%2
    return (x % 2) + ((x / 2) % 2) + ((x / 4) % 2)


#####################################################################
# Program semantics: what is the meaning of a program candidate?
#####################################################################

def slot_result(op, arg1, arg2):
    """What does one instruction compute, given its operation and two arguments?
    Returns a Z3 expression.

    Note: AND and SHR1 are defined arithmetically (not via BitVec), since
    the rest of our model uses Z3 integers. This works correctly for the
    non-negative inputs we'll use with these operations."""
    return If(op == OP_ADD, arg1 + arg2,
           If(op == OP_SUB, arg1 - arg2,
           If(op == OP_NEG, -arg1,
           If(op == OP_MAX, If(arg1 >= arg2, arg1, arg2),
           If(op == OP_MIN, If(arg1 <= arg2, arg1, arg2),
           If(op == OP_BIT0, arg1 % 2,
           If(op == OP_SHR1, arg1 / 2,
           If(op == OP_ONE, 1,
              0))))))))  # OP_ZERO

# As the program runs, each instruction produces a new variable:
#   x, y, ...   (the inputs)
#   t0           (output of instruction 0)
#   t1           (output of instruction 1)
#   ...
# When an instruction picks its operands, it chooses which prior
# variable to read from — an input, or a prior instruction's output.

def pick_variable(selector, variables):
    """Choose a value from the available variables based on a selector index.
       (Don't refer to a variable that is only assigned later in the program.)"""
    result = variables[0]
    for i in range(1, len(variables)):
        result = If(selector == i, variables[i], result)
    return result

def run_program(ops: list, arg1s: list, arg2s: list, inputs: list,
                num_slots: int) -> ArithRef:
    """Evaluate a program on a list of inputs. ops/arg1s/arg2s can be Z3
    variables (during synthesis) or concrete Python ints (during verification).
    Either way, the return value is always a Z3 expression (ArithRef),
    because slot_result wraps everything in If(...)."""
    variables = list(inputs)  # start with the input variables
    for i in range(num_slots):
        a1 = pick_variable(arg1s[i], variables)
        a2 = pick_variable(arg2s[i], variables)
        variables.append(slot_result(ops[i], a1, a2))
    return variables[-1]  # output = last instruction's result

#####################################################################
# Pretty-printing
#####################################################################

INPUT_NAMES = ["x", "y", "z", "w"]  # names for up to 4 inputs

def var_name(idx: int, num_inputs: int) -> str:
    """Pretty-print a variable index. First num_inputs are input names,
    the rest are t0, t1, ..."""
    if idx < num_inputs:
        return INPUT_NAMES[idx]
    return f"t{idx - num_inputs}"

def print_program(model, ops, arg1s, arg2s, num_slots: int,
                  num_inputs: int) -> None:
    """Print the synthesized program in human-readable form."""
    for i in range(num_slots):
        op  = model.evaluate(ops[i]).as_long()
        a1  = model.evaluate(arg1s[i]).as_long()
        a2  = model.evaluate(arg2s[i]).as_long()
        name = OP_NAMES[op]
        out  = var_name(num_inputs + i, num_inputs)
        if op in (OP_NEG, OP_BIT0, OP_SHR1):
            print(f"  {out} = {name}({var_name(a1, num_inputs)})")
        elif op == OP_ZERO:
            print(f"  {out} = 0")
        elif op == OP_ONE:
            print(f"  {out} = 1")
        else:
            print(f"  {out} = {name}({var_name(a1, num_inputs)}, {var_name(a2, num_inputs)})")
    print(f"  output: {var_name(num_inputs + num_slots - 1, num_inputs)}")


#####################################################################
# Core CEGIS loop
#####################################################################

def cegis(spec, num_slots: int, precondition=None, verbose=False) -> None:
    # Infer the number of inputs from the spec's signature.
    num_inputs = len(inspect.signature(spec).parameters)
    input_names = INPUT_NAMES[:num_inputs]

    # We have num_slots lines of code to work with.
    # Each line ("instruction slot") has an operation and two operand expressions.
    ops   = [Int(f"op_{i}")   for i in range(num_slots)]
    arg1s = [Int(f"arg1_{i}") for i in range(num_slots)]
    arg2s = [Int(f"arg2_{i}") for i in range(num_slots)]

    # Z3 Int variables range over ALL integers by default. Without these
    # bounds, the solver could pick op_0 = 7 or op_0 = -3, which don't
    # correspond to any operation. Similarly, arg selectors must index
    # into variables that actually exist at that point in the program.
    # At slot i, variables 0..(num_inputs + i - 1) are available.
    prog_bounds = []
    for i in range(num_slots):
        prog_bounds.append(And(ops[i] >= 0, ops[i] < NUM_OPS))
        num_available = num_inputs + i  # inputs + prior instruction outputs
        prog_bounds.append(And(arg1s[i] >= 0, arg1s[i] < num_available))
        prog_bounds.append(And(arg2s[i] >= 0, arg2s[i] < num_available))

    print(f"=== CEGIS: Synthesizing {spec.__name__}({', '.join(input_names)}) ===")
    print(f"Program template: {num_slots} instruction slots")
    print(f"Available operations: {', '.join(OP_NAMES)}")
    print(f"Allowed input-value range: [{INPUT_LO}, {INPUT_HI}]")
    print()

    concrete_inputs: list[tuple] = []
    iteration = 0

    # === SYNTHESIZE ===
    # The synthesizer accumulates constraints: each counterexample adds one.
    # We initialize the solver once and incrementally add to it.
    synth = Solver()
    synth.add(prog_bounds)

    while True:
        iteration += 1
        print(f"--- Iteration {iteration} for {spec.__name__} ---")
        print(f"Concrete inputs: {concrete_inputs}")
        # If we have a new counterexample, add a constraint for it.
        if concrete_inputs:
            input_tuple = concrete_inputs[-1] # Already added the rest.
            # We wrap values in IntVal so Z3 treats them as integer-sorted
            # expressions (plain Python ints can cause sort mismatches with
            # operations like / that would produce Python floats).
            concrete_vals = [IntVal(v) for v in input_tuple]
            output = run_program(ops, arg1s, arg2s, concrete_vals, num_slots)
            synth.add(output == spec(*concrete_vals))

        if verbose:
            print(f"{len(synth.assertions())} Constraints: {synth.assertions()}")

        if synth.check() != sat:
            print("No program of this size satisfies all constraints!")
            return

        model = synth.model()
        print("Candidate program:")
        print_program(model, ops, arg1s, arg2s, num_slots, num_inputs)

        # Extract concrete program for the verifier.
        concrete_ops   = [TO_LONG(model.evaluate(ops[i]))   for i in range(num_slots)]
        concrete_arg1s = [TO_LONG(model.evaluate(arg1s[i])) for i in range(num_slots)]
        concrete_arg2s = [TO_LONG(model.evaluate(arg2s[i])) for i in range(num_slots)]

        # === VERIFY ===
        # Check: does this candidate work for ALL inputs in the bounded range?
        # We ask Z3 to find inputs where the candidate disagrees with the spec.
        verif = Solver()
        symbolic_inputs = [Int(name) for name in input_names]
        for inp in symbolic_inputs:
            verif.add(And(inp >= INPUT_LO, inp <= INPUT_HI))
        if precondition is not None:
            verif.add(precondition(*symbolic_inputs))
        candidate_output = run_program(
            concrete_ops, concrete_arg1s, concrete_arg2s,
            symbolic_inputs, num_slots)
        verif.add(candidate_output != spec(*symbolic_inputs))

        if verif.check() != sat:
            print()
            print("=== Verified! No counterexample found. ===")
            print("Final program:")
            print_program(model, ops, arg1s, arg2s, num_slots, num_inputs)
            return

        # There are inputs where the candidate fails. Add them and try again.
        cex_model = verif.model()
        cex_tuple = tuple(TO_LONG(cex_model.evaluate(inp)) for inp in symbolic_inputs)
        cex_str = ", ".join(f"{name} = {val}" for name, val in zip(input_names, cex_tuple))
        print(f"Counterexample: {cex_str}")
        print()
        concrete_inputs.append(cex_tuple)

if __name__ == "__main__":
    # 2 operations should suffice.
    cegis(abs_spec, num_slots=2)
    print("\n" + "="*50 + "\n")

    # If we only had 2 numbers, 1 op would suffice since we have MAX.
    # Given 3 numbers, we need at least 2 MAX operations.
    cegis(max3_spec, num_slots=2)
    print("\n" + "="*50 + "\n")

    # 3 operations should suffice, here.
    cegis(clamp_spec, num_slots=3, #2,
          precondition=lambda x, lo, hi: lo <= hi)
    print("\n" + "="*50 + "\n")

    # Count the number of 1-bits.
    # Inputs are constrained to be small for this example (see the spec docstring).

    cegis(ones_spec, num_slots=8,
          precondition=lambda x: And(x >= 0, x <= 7))
    # print("\n" + "="*50 + "\n")

    # We can't synthesize multiplication when both parameters are 
    # unknown, at least when using only the operators declared above. 
    # CEGIS will accumulate >= 1 counterexample before concluding failure.
    #cegis(mul_spec, num_slots=4, verbose=False)
    cegis(mul_spec, num_slots=5, verbose=False)
