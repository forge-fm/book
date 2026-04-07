"""
Comparison: CEGIS vs. monolithic ForAll for program synthesis.

Shows why CEGIS exists — the ForAll version asks Z3 to handle quantifier
elimination over the full input space in one shot, which is often much slower
(or times out) compared to the incremental CEGIS approach.
"""

from z3 import Solver, Int, sat, unsat, ForAll
from z3 import If as _If, And as _And
import time, inspect

from z3_cegis_demo import (
    And, TO_LONG, NUM_OPS,
    INPUT_LO, INPUT_HI, INPUT_NAMES,
    abs_spec, max3_spec, clamp_spec, ones_spec,
    cegis, run_program, print_program,
)


#####################################################################
# Monolithic ForAll approach
#####################################################################

def monolithic(spec, num_slots: int, precondition=None,
               timeout_ms: int = 30000, use_input_bounds=True) -> dict:
    """Single solver call: exists program, forall inputs, program matches spec.
    Uses Z3's standard solver (MBQI-based)."""
    num_inputs = len(inspect.signature(spec).parameters)
    input_names = INPUT_NAMES[:num_inputs]

    ops   = [Int(f"op_{i}")   for i in range(num_slots)]
    arg1s = [Int(f"arg1_{i}") for i in range(num_slots)]
    arg2s = [Int(f"arg2_{i}") for i in range(num_slots)]

    s = Solver()
    s.set("timeout", timeout_ms)

    # Program structure bounds (existential)
    for i in range(num_slots):
        s.add(And(ops[i] >= 0, ops[i] < NUM_OPS))
        num_available = num_inputs + i
        s.add(And(arg1s[i] >= 0, arg1s[i] < num_available))
        s.add(And(arg2s[i] >= 0, arg2s[i] < num_available))

    # Universal quantification over inputs
    symbolic_inputs = [Int(f"_forall_{name}") for name in input_names]
    input_bounds = And(*[And(inp >= INPUT_LO, inp <= INPUT_HI)
                         for inp in symbolic_inputs])

    pre = precondition(*symbolic_inputs) if precondition else True

    program_output = run_program(ops, arg1s, arg2s, symbolic_inputs, num_slots)
    spec_output = spec(*symbolic_inputs)

    # ForAll inputs: if in bounds and precondition holds, program == spec
    antecedent = _And(input_bounds, pre) if use_input_bounds else pre   # type: ignore
    correctness = ForAll(symbolic_inputs,
                         _If(antecedent,
                             program_output == spec_output,
                             True))
    s.add(correctness)

    label = f"input bounds={use_input_bounds}"
    print(f"=== Monolithic ({label}): {spec.__name__}({', '.join(input_names)}) ===")
    print(f"  {num_slots} slots, timeout {timeout_ms}ms")

    t0 = time.time()
    result = s.check()
    elapsed = time.time() - t0

    if result == sat:
        print(f"  SOLVED in {elapsed:.3f}s")
        print_program(s.model(), ops, arg1s, arg2s, num_slots, num_inputs)
        return {"status": "SOLVED", "time": elapsed}
    elif result == unsat:
        print(f"  UNSAT (no program exists) in {elapsed:.3f}s")
        return {"status": "UNSAT", "time": elapsed}
    else:
        print(f"  UNKNOWN / TIMEOUT after {elapsed:.3f}s")
        reason = s.reason_unknown()
        print(f"  Reason: {reason}")
        return {"status": "TIMEOUT", "time": elapsed}


#####################################################################
# Run the comparison
#####################################################################

if __name__ == "__main__":
    benchmarks = [
        ("abs",   abs_spec,   2, None),
        ("max3",  max3_spec,  2, None),
        ("clamp", clamp_spec, 3, lambda x, lo, hi: lo <= hi),
        ("ones",  ones_spec,  8, lambda x: And(x >= 0, x <= 7)),
    ]

    rows = []  # (benchmark, slots, method, status, time)

    for name, spec, slots, pre in benchmarks:
        print(f"\n{'='*60}")
        print(f" Benchmark: {name} ({slots} slots)")
        print(f"{'='*60}")

        print(f"\n--- CEGIS ---")
        r = cegis(spec, slots, precondition=pre)
        rows.append((name, slots, "CEGIS (bounded)", r["status"], r["time"]))
        r = cegis(spec, slots, precondition=pre, use_input_bounds=False)
        rows.append((name, slots, "CEGIS (unbounded)", r["status"], r["time"]))

        print(f"\n--- Monolithic ---")
        r = monolithic(spec, slots, precondition=pre,timeout_ms=60000)
        rows.append((name, slots, "Monolithic (bounded)", r["status"], r["time"]))
        r = monolithic(spec, slots, precondition=pre,timeout_ms=60000, use_input_bounds=False)
        rows.append((name, slots, "Monolithic (unbounded)", r["status"], r["time"]))

    # Write markdown summary
    out_path = "z3_cegis_vs_forall_results.md"
    with open(out_path, "w") as f:
        f.write("# CEGIS vs. Monolithic ForAll: Results\n\n")
        f.write(f"Input range for bounded variants: [{INPUT_LO}, {INPUT_HI}]\n\n")
        f.write("| Benchmark | Slots | Method | Result | Time (s) |\n")
        f.write("|-----------|------:|--------|--------|----------|\n")
        for name, slots, method, status, elapsed in rows:
            f.write(f"| {name} | {slots} | {method} | {status} | {elapsed:.3f} |\n")
    print(f"\nResults written to {out_path}")
