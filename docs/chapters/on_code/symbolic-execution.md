# Symbolic Execution 

<!-- 
Plan:
  - Monday: conceptual intro to SE (symbolic values), KLEE demo, IF(P,N,M). path explosion.
  - Wednesday (recorded; QUESTIONS THREAD): CEGIS.
  - Friday (recorded OR in-person): More CEGIS, or extra SE based on questions  -->

---

These notes are adapted from [Alexa VanHattum's](https://cs.wellesley.edu/%7Eavh/) _Modeling for Computer Systems_ course at Wellesley. 

---

Symbolic execution is a technique (often solver-based) that works over actual program code, rather than relying on a simplified abstract model. The core idea is to run programs on "symbolic" inputs rather than concrete values. At each operation and program branch, we update the symbolic state to formulas that represent possible concrete values along that program path.

## An Example and Fuzzy Description

Here's a sample program. For now, I'm using a Python-ish pseudocode syntax, but we'll get to real C code soon.

```
def f(x: int, y: int):
    if x > y:
        tmp = x
        x = y
        y = tmp
        if x > 0 && y > 0 && (x-y) > 0:
            ERROR()
    z = x * 128   # These may look strange, but they approximate what the 
    w = x % 256   # real C code will do later on. The only major difference
    if w == 0:    # is that Python ints don't overflow.
      ERROR()
```

Is it possible for `f` to throw an error? If so, how? If not, why?

??? note "Think, then click!"
    Yes! The first `ERROR()` is unreachable, but the second is: consider `f(0,0)`. The initial `if` is skipped, `z` is set to `0`, and then so is `w`. Here's the informal logic we might follow:
    ```
    def f(x: int, y: int): # let X and Y be new variables
        if x > y:
            tmp = x  # save old value of x
            x = y    # update x := y
            y = tmp  # replace y with old x (in effect, swap!)
            if x > 0 && y > 0 && (x-y) > 0: # x > y before swap, so now y cannot be greater than x
                ERROR() # unreachable
        z = x * 128 
        w = x % 256 
        if w == 0:  # any time (initial-value-of-x * 128) % 256 == 0; y isn't involved
            ERROR() # e.g., x:=0 to start with
    ```

Reflect on how you approached this problem. You might have tried a few concrete examples, in which case you either got lucky or informed those choices by looking over the code. You might also have  walked through step-by-step, like I did, without considering concrete examples until the very end. 

Symbolic execution looks a lot like this stepping-through process. In contract to concrete execution, which works with concrete values, symbolic execution binds variables to _symbolic values_ instead. A symbolic-execution engine won't try `f(0,0)`; it will try `f({x | x in Int}, {y | y in Int})`, and continuously refine the known domains of `x` and `y` at every line. 

## Some brief history

Symbolic execution really took root in the 1970s (see [this 2025 retrospective](https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=10886972) by Lori Clarke, one of the first researchers to work on these ideas). But symbolic reasoning is computationally expensive, so compute was a limiting factor at the time.

With computation getting faster in the decades sense (see [Moore's Law](https://en.wikipedia.org/wiki/Moore%27s_law)), symbolic reasoning tools could solve bigger and bigger problems (see ["A Billion SMT Queries A Day", AWS](https://www.amazon.science/blog/a-billion-smt-queries-a-day)). This has made symbolic execution more practical and applicable to more use cases.

## Demo: KLEE

If you'd like to see a symbolic-execution engine at work, I suggest trying out [KLEE](https://klee-se.org/), which has previously [found bugs in the GNU coreutils library](https://www.usenix.org/legacy/events/osdi08/tech/full_papers/cadar/cadar.pdf). KLEE can both search for bugs with symbolic execution _and_ produce high-coverage (but partial!) test suites. The demo is best done via Docker.

Add the C version of the above example as a file in an `examples` sub-folder. This can be called whatever you'd like, but the commands below assume that's where the source is. There's a bit of boilerplate that KLEE needs added: we'll say what libraries to import, and annotate the input variables to let KLEE see them. We also need to tell KLEE that we don't want to hit those `exit(-1)` lines.

```
#include <klee/klee.h>
#include <assert.h>
#include <stdlib.h>

void f (int x, int y) {
  if (x > y) {
    int tmp = x;
    x = y;
    y = tmp;
    if (x > 0 && y > 0 && x - y > 0) {
       klee_assert(0); // was: exit(-1);
    }
  }
  int z = x << 7;
  int w = x & 0xFF;
  if (!w) {
    klee_assert(0); // was: exit(-1);
  }
} 

int main() {
  int x, y;
  klee_make_symbolic(&x, sizeof(x), "x");
  klee_make_symbolic(&y, sizeof(y), "y");
  f(x, y);
  return 0;
}
```

* Then run the Docker container with the `examples` subfolder mounted: `docker run -it -v $(pwd)/examples:/home/klee/examples --platform linux/amd64 --rm klee/klee`. If you want to specify an architecture, provide a different `--platform` argument.
* Compile the example C file: `clang -emit-llvm -c -g -O0 -Xclang -disable-O0-optnone examples/example.c -o examples/example.bc`
* Run KLEE on the compiled file: `klee examples/example.bc`. 

You should see an error like: 
```KLEE: ERROR: examples/example.c:17: ASSERTION FAIL: 0```

KLEE's engine categorizes code paths into _tests_. So we'll see a file with a name like `examples/klee-last/test000001.assert.err`. It contains some low level, not-very-helpful (to us, right now) data:
```
Error: ASSERTION FAIL: 0
File: examples/example.c
Line: 17
assembly.ll line: 69
State: 3
Stack: 
        #000000069 in f(x=symbolic, y=symbolic) at examples/example.c:17
        #100000095 in main() at examples/example.c:25
```
Instead, let's look at the test itself. 

```
$ ktest-tool examples/klee-last/test000001.ktest

ktest file : 'examples/klee-last/test000001.ktest'
args       : ['examples/example.bc']
num objects: 2
object 0: name: 'x'
object 0: size: 4
object 0: data: b'\x00\x00\x00\x00'
object 0: hex : 0x00000000
object 0: int : 0
object 0: uint: 0
object 0: text: ....
object 1: name: 'y'
object 1: size: 4
object 1: data: b'\x00\x00\x00\x00'
object 1: hex : 0x00000000
object 1: int : 0
object 1: uint: 0
object 1: text: ....
```

What do you notice? 

??? note "Think, then click." 
    The test describes two concrete values for two symbolic ones: `x` and `y`. The extra fields have to do with low-level data formatting&mdash;how much space is being used for the values, and so on. In this case, KLEE found the example example I did: `x=0, y=0`. 

But this isn't the only "test" that KLEE generated. I see 4, which are (after I remove all the extra information in those files): 
* `x=16, y=-2147483647`; 
* `x=1, y=2147483647`; and
* `x=2, y=1`.

Why these 4? 

??? note "Think, then click"
    They correspond to code paths in the example program. 
    * The assertion failure, with `x=0, y=0`, skips the first `if` statement but enters the third one. 
    * The input (`x=1, y=2147483647`) skips all `if` statements. 
    * The input (`x=16, y=-2147483647`) enters the first `if` statement but skips the second and third ones. 
    * The input (`x=2, y=1`) enters the first `if` statement but skips the second and third ones. But this is _different_ from the prior concrete example, because it skips the third `if` statement for a different reason. 

<!-- Path coverage vs branch coverage -->

## Symbolic execution with SMT solvers

KLEE works by using a SAT/SMT solver to reason about program paths. It extracts concrete inputs ("tests") corresponding to execution paths and reports which fail to meet some specification. Analysis is done automatically, via the underlying solver. That sounds great, but we should expect there to be downsides, right? We must sacrifice one of the 4 parameters in the [Triangle of Existential Despair](../solvers/undecidability.md). 

Symbolic execution often can't analyze _all_ execution paths. but why?

??? note "Think, then click!"
    If a program has a loop that is not statically bounded (for example, a server always waiting for connections), it wouldn't always be possible for symbolic execution to reason about _every_ possible path. 

But we shouldn't let this limitation get on our way. Any tools we can use to find bugs, the better&mdash;and symbolic execution has a long history of finding real bugs. So let's make progress! 

We can model `if` statements with `and`: to get inside _both_, both conditions need to be true. (Reassignment to values is the only complication, here.) Symbolic execution is based on that idea. At each program point, we track two data structures: 
* (1) a mapping of variables to symbolic values; and 
* (2) the path conditions to get to that program point.

If we treat points in the above program as nodes in a graph, we can draw the path conditions as edges and the symbolic values as annotations on each node. Let's step through the C version now, in more detail.

```
// M and N are "fresh" variables to represent the starting values of x and y.
void f (int x, int y) {  # path: true. mapping: {x: M, y: N}.
```

```
// if statements add their condition to the path, replacing variables with 
// their current values from the mapping. We also use the symbolic version 
// of the operator (for the Z3 Python bindings, > looks the same).
void f (int x, int y) {  # path: true. mapping: {x: M, y: N}.
  if (x > y) {
    # path: M > N, mapping: {x: M, y: N}
  }
} 
```

```
// if statements add their condition to the path, replacing variables with 
// their current values from the mapping. We also use the symbolic version 
// of the operator (for the Z3 Python bindings, > looks the same).
void f (int x, int y) {  # path: true. mapping: {x: M, y: N}.
  if (x > y) {
    # path: M > N, mapping: {x: M, y: N}
  }
} 
```


```
Variable initialization adds to the mapping. For the right side of the =,
we again look up variables in the mapping and use symbolic operators.
void f (int x, int y) {  # path: true. mapping: {x: M, y: N}.
  if (x > y) {
    # path: M > N, mapping: {x: M, y: N}
    int tmp = x; # path: M > N, mapping: {x: M, y: N, tmp=M}
  }
} 
```

```
// Assignment to existing variables updates the mapping.
// Note: formally, might add an "and true" to the path formula 
// for both of these, but we're omitting them from the comments here.
void f (int x, int y) {  # path: true. mapping: {x: M, y: N}.
  if (x > y) {
    # path: M > N, mapping: {x: M, y: N}
    int tmp = x; # path: M > N, mapping: {x: M, y: N, tmp=M}
    x = y; # path: M > N, mapping: {x: N, y: N, tmp = M}
    y = tmp; # path: M > N, mapping: {x: N, y: M, tmp = M}
  }
} 
```

```
// Entering the 2nd if-statement adds to the path condition.
// Then, on hitting the assertion, we ask the solver: is this path
// condition satisfiable? The answer is no: if M > N, then N - M
// can't ever be positive. 
void f (int x, int y) {  # path: true. mapping: {x: M, y: N}.
  if (x > y) {
    # path: M > N, mapping: {x: M, y: N}
    int tmp = x; # path: M > N, mapping: {x: M, y: N, tmp=M}
    x = y; # path: M > N, mapping: {x: N, y: N, tmp = M}
    y = tmp; # path: M > N, mapping: {x: N, y: M, tmp = M}
    if (x > 0 && y > 0 && x - y > 0) {
       # path: (M > N and N > 0 and M > 0 and N - M = 0), mapping: {x: N, y: M, tmp = M}
       klee_assert(0); // was: exit(-1); # path condition is UNSAT
    }
  }
} 
```

At this point, control flow merges as we exit the outer `if`. There are now two possible ways to reach this point! Different symbolic execution engines use different strategies. For now, we'll say that after this point, the variable assignments are conditioned based on whether the branch was taken:

```
void f (int x, int y) {  # path: true. mapping: {x: M, y: N}.
  if (x > y) {
    # path: M > N, mapping: {x: M, y: N}
    int tmp = x; # path: M > N, mapping: {x: M, y: N, tmp=M}
    x = y; # path: M > N, mapping: {x: N, y: N, tmp = M}
    y = tmp; # path: M > N, mapping: {x: N, y: M, tmp = M}
    if (x > 0 && y > 0 && x - y > 0) {
       # path: (M > N and N > 0 and M > 0 and N - M = 0), mapping: {x: N, y: M, tmp = M}
       klee_assert(0); // was: exit(-1); # path condition is UNSAT
    }
  }
  # path: true. Mapping: {x: If(M>N, N, M) , y: If(M>N, M, N)}.
  int z = x << 7; # path: true. Mapping: {x: If(M>N, N, M) , y: If(M>N, M, N), z: If(M>N, N, M) << 7}.
} 
```

Notice how the current path condition backtracks, but symbolic values in the mapping must still reflect the history of how they might be assigned. When we encounter an if-then-else `if <condition>: <if-true> else: <if-false>` we always append `<condition>` to the path condition in the "yes" branch and `not <condition>` in the "no" branch. 

Keep following this process for yourself. Then, what happens when you hit the other assertion failure? 

??? note "Think, then click?"
    We ask the solver if the path, which simplifies to !((If(M>N, N, M) << 7) & 0xFF) != 0, and this time it is satisfiable. The solver also returns concrete values for M and N&mdash;the initial values of `x` and `y`&mdash;witnessing the error. 

## Wrapping Up

Notable points:

* We start with a path condition of just `True`.
* Most normal statements, like assignments (var = ...), do not modify the path condition.
* If statements do update the path condition, for both the if- and else- branches. The condition is added:
    * to the if- branch with an And(cond, ...); and 
    * to the else branch with an And((Not(cond)), ...).
* Assignments cause us to update our symbolic variable mapping. Our strategy here is to look up whatever variables are in the right hand side of the assignment in the symbolic map, and combine them (with constants as applicable) to build a new symbolic value for the variable.
* At each point that could indicate a potential error, the engine uses an SMT solver to check whether the path condition for that point is satisfiable. 
    * If these is some assignment of inputs such that the path is reachable, then we have an issue! 
    * If the SMT solver returns UNSAT, then the potential bug is unreachable, as desired.

!!! Further Reading
    Read more about symbolic execution [here](https://dl.acm.org/doi/10.1145/360248.360252).

<!-- https://hackmd.io/@avh/B12e2J-eC -->

