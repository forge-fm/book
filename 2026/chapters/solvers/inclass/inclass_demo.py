"""
CEGIS Demo: Synthesizing programs from a menu of operations with Z3. 

The core idea of CEGIS is:
  - You have a "some x | forall y | P(x, y)" where the "forall y" won't scale.
  - You replace it with repeated calls:
    - The _synthesis_ step "some x | LEARNED(x)", where LEARNED grows over time.
    - The _verifier_ step: given an X, "some y | not P(X,y)". 
      - SAT: Counterexample y=Y values enhance LEARNED: we add that P(x, Y) must be true. 
      - UNSAT: success! 

Today, we'll use CEGIS for program synthesis, although it's good for other things too.
In that context, "x" is the program candidate, and "y" is a specific input.

We want to show CEGIS working at a classroom-demo level. 

Design choices:
- Sort: Int only.
- Constants available as operands: 0, 1.
- Operators (with arities):
    * negate (1)
    * abs    (1)
    * add    (2)
    * min    (2)
    * max    (2)
- Program form: SSA. Each line picks an operator and operand sources
  (program inputs, prior SSA lines, or the constants 0/1).
"""
# <CLAUDE>
from dataclasses import dataclass
from typing import List, Tuple
import z3

# Operator codes. Constants are 0-ary "operators".
OP_ZERO: int = 0
OP_ONE:  int = 1
OP_ABS:  int = 2
OP_NEG:  int = 3
OP_ADD:  int = 4
OP_MIN:  int = 5
OP_MAX:  int = 6
NUM_OPS: int = 7


@dataclass
class Line:
    """One SSA line: an operator code plus two operand indices into the value pool."""
    op: z3.ArithRef
    a:  z3.ArithRef
    b:  z3.ArithRef


@dataclass
class Program:
    num_inputs: int
    lines: List[Line]


def make_program(num_inputs: int, num_lines: int, name: str = "p") -> Program:
    """Allocate fresh Z3 Int variables for an SSA program skeleton."""
    lines = [
        Line(
            op=z3.Int(f"{name}_op_{i}"),
            a=z3.Int(f"{name}_a_{i}"),
            b=z3.Int(f"{name}_b_{i}"),
        )
        for i in range(num_lines)
    ]
    return Program(num_inputs=num_inputs, lines=lines)


def well_formed(prog: Program) -> List[z3.BoolRef]:
    """Constraints saying op codes are in range and operand indices reference
    only program inputs or strictly earlier SSA lines (enforces SSA + acyclicity)."""
    cs: List[z3.BoolRef] = []
    for i, line in enumerate(prog.lines):
        cs.append(z3.And(line.op >= 0, line.op < NUM_OPS))
        upper = prog.num_inputs + i  # inputs occupy 0..n-1, prior lines n..n+i-1
        cs.append(z3.And(line.a >= 0, line.a < upper))
        cs.append(z3.And(line.b >= 0, line.b < upper))
    return cs


def _select(pool: List[z3.ArithRef], idx: z3.ArithRef) -> z3.ArithRef:
    """Symbolic indexing into a fixed-size list of Z3 Ints."""
    expr: z3.ArithRef = pool[0]
    for j in range(1, len(pool)):
        expr = z3.If(idx == j, pool[j], expr)  # type: ignore[assignment]
    return expr


def eval_program(prog: Program, inputs: List[z3.ArithRef]) -> z3.ArithRef:
    """Symbolic evaluation: returns the Z3 expression for the program's output
    (the last SSA line) given concrete-or-symbolic input values."""
    assert len(inputs) == prog.num_inputs
    pool: List[z3.ArithRef] = list(inputs)
    for line in prog.lines:
        x = _select(pool, line.a)
        y = _select(pool, line.b)
        val = z3.If(line.op == OP_ZERO, z3.IntVal(0),
              z3.If(line.op == OP_ONE,  z3.IntVal(1),
              z3.If(line.op == OP_ABS,  z3.If(x >= 0, x, -x),
              z3.If(line.op == OP_NEG,  -x,
              z3.If(line.op == OP_ADD,  x + y,
              z3.If(line.op == OP_MIN,  z3.If(x <= y, x, y),
                                        z3.If(x >= y, x, y)))))))  # OP_MAX
              ## NOTE WELL: if adding more operators, need to expand this nested if.
        pool.append(val)  # type: ignore[arg-type]
    return pool[-1]


# ---------------------------------------------------------------------------
# Specifications for target programs.
#
# A Spec packages: how many inputs the target takes, a precondition over those
# inputs (the assumed input domain), and a postcondition relating inputs to the
# program's single output. CEGIS will then look for a program p such that
#   forall inputs. pre(inputs) -> post(inputs, eval_program(p, inputs))
# ---------------------------------------------------------------------------

from typing import Callable

Pre  = Callable[[List[z3.ArithRef]], z3.BoolRef]
Post = Callable[[List[z3.ArithRef], z3.ArithRef], z3.BoolRef]


@dataclass
class Spec:
    name: str
    num_inputs: int
    pre:  Pre
    post: Post


def _popcount_int(n: int) -> int:
    """Reference popcount for non-negative ints (Python-side oracle)."""
    assert n >= 0
    c = 0
    while n > 0:
        c += n & 1
        n >>= 1
    return c


def popcount_spec(bit_width: int) -> Spec:
    """Spec: count the 1-bits of a non-negative integer < 2**bit_width.

    Since LIA can't express popcount directly, we encode the postcondition as
    a finite disjunction over the bounded input domain. Keep bit_width small
    in classroom demos -- the encoding is O(2**bit_width)."""
    assert bit_width >= 1
    domain: int = 1 << bit_width

    def pre(inputs: List[z3.ArithRef]) -> z3.BoolRef:
        x = inputs[0]
        return z3.And(x >= 0, x < domain)

    def post(inputs: List[z3.ArithRef], out: z3.ArithRef) -> z3.BoolRef:
        x = inputs[0]
        cases: List[z3.BoolRef] = [
            z3.And(x == n, out == _popcount_int(n)) for n in range(domain)
        ]
        return z3.Or(*cases)

    return Spec(name=f"popcount_{bit_width}", num_inputs=1, pre=pre, post=post)


# ---------------------------------------------------------------------------
# CEGIS loop.
# ---------------------------------------------------------------------------

from typing import Optional

_OP_NAMES = {
    OP_ZERO: "0", OP_ONE: "1", OP_ABS: "abs", OP_NEG: "neg",
    OP_ADD: "add", OP_MIN: "min", OP_MAX: "max",
}
_ARITY = {OP_ZERO: 0, OP_ONE: 0, OP_ABS: 1, OP_NEG: 1,
          OP_ADD: 2, OP_MIN: 2, OP_MAX: 2}


@dataclass
class CegisResult:
    status: str            # "synthesized" | "unrealizable" | "unknown"
    program: Optional["Program"]
    iterations: int
    counterexamples: List[List[int]]


def _materialize(prog: Program, model: z3.ModelRef) -> Program:
    """Replace each line's symbolic op/a/b with the concrete IntVal from a model."""
    lines: List[Line] = []
    for line in prog.lines:
        op_v = model.eval(line.op, model_completion=True).as_long()  # type: ignore[attr-defined]
        a_v  = model.eval(line.a,  model_completion=True).as_long()  # type: ignore[attr-defined]
        b_v  = model.eval(line.b,  model_completion=True).as_long()  # type: ignore[attr-defined]
        lines.append(Line(op=z3.IntVal(op_v), a=z3.IntVal(a_v), b=z3.IntVal(b_v)))
    return Program(num_inputs=prog.num_inputs, lines=lines)


def pretty_program(prog: Program) -> str:
    """Render a concrete (materialized) program as readable SSA."""
    out: List[str] = []
    n = prog.num_inputs
    for i, line in enumerate(prog.lines):
        op_v = line.op.as_long()  # type: ignore[attr-defined]
        a_v  = line.a.as_long()   # type: ignore[attr-defined]
        b_v  = line.b.as_long()   # type: ignore[attr-defined]
        def ref(idx: int) -> str:
            return f"in{idx}" if idx < n else f"v{idx - n}"
        name = _OP_NAMES[op_v]
        arity = _ARITY[op_v]
        if arity == 0:
            rhs = name
        elif arity == 1:
            rhs = f"{name}({ref(a_v)})"
        else:
            rhs = f"{name}({ref(a_v)}, {ref(b_v)})"
        out.append(f"  v{i} = {rhs}")
    out.append(f"  return v{len(prog.lines) - 1}")
    return "\n".join(out)


def cegis(spec: Spec, num_lines: int, max_iters: int = 200,
          verbose: bool = True) -> CegisResult:
    """Run CEGIS to synthesize an SSA program of length `num_lines` for `spec`."""
    sketch = make_program(spec.num_inputs, num_lines, name="p")

    synth = z3.Solver()
    for c in well_formed(sketch):
        synth.add(c)

    cexs: List[List[int]] = []

    for iteration in range(1, max_iters + 1):
        if verbose:
            print(f"[iter {iteration}] synth (|cex|={len(cexs)}) ...", end=" ", flush=True)

        if synth.check() != z3.sat:
            if verbose:
                print("UNSAT -> spec is UNREALIZABLE with this op menu / length.")
            return CegisResult("unrealizable", None, iteration, cexs)

        candidate = _materialize(sketch, synth.model())
        if verbose:
            print("got candidate:")
            print(pretty_program(candidate))

        # Verifier: does some legal input falsify the candidate?
        verifier = z3.Solver()
        v_inputs: List[z3.ArithRef] = [
            z3.Int(f"v_in_{i}") for i in range(spec.num_inputs)
        ]
        verifier.add(spec.pre(v_inputs))
        cand_out = eval_program(candidate, v_inputs)
        verifier.add(z3.Not(spec.post(v_inputs, cand_out)))

        if verifier.check() == z3.unsat:
            if verbose:
                print(f"  verifier UNSAT -> SYNTHESIZED in {iteration} iter(s).")
            return CegisResult("synthesized", candidate, iteration, cexs)

        v_model = verifier.model()
        cex = [v_model.eval(v, model_completion=True).as_long()  # type: ignore[attr-defined]
               for v in v_inputs]
        if verbose:
            print(f"  counterexample: inputs={cex}")
        cexs.append(cex)

        # Strengthen synth: this concrete input must be handled correctly.
        cex_vals: List[z3.ArithRef] = [z3.IntVal(c) for c in cex]  # type: ignore[misc]
        sketch_out = eval_program(sketch, cex_vals)
        synth.add(z3.Implies(spec.pre(cex_vals), spec.post(cex_vals, sketch_out)))

    return CegisResult("unknown", None, max_iters, cexs)


if __name__ == "__main__":
    spec = popcount_spec(bit_width=2)
    print(f"=== CEGIS demo: {spec.name} ===")
    result = cegis(spec, num_lines=4, max_iters=200, verbose=True)
    print()
    print(f"status     : {result.status}")
    print(f"iterations : {result.iterations}")
    print(f"|cex|      : {len(result.counterexamples)}")
    if result.program is not None:
        print("program:")
        print(pretty_program(result.program))
# </CLAUDE>