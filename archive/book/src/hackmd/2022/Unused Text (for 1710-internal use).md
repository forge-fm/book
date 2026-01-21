# Unused Text (for 1710-internal use)

## From PBT Lecture

We'll finish up with a few examples. For each of these, ask yourself:


@itemlist[#:style 'ordered
          @item{Is it easy or hard to write an input generator?}
          @item{Is it easy or hard to write an @tt{is_valid} function?}
          @item{If the @tt{is_valid} function is expensive to compute, can we still get something useful out of PBT?}
          @item{Is it easy or hard to write down a mathematical, but not programmatic, equivalent to @tt{is_valid} for this problem?}]

@incercise{Integer factorization. Input: an integer. Output: a list of integers (possibly with repeats, to avoid exponentiation).}

@incercise{Sudoku puzzle solver. Input: a Sudoku puzzle. Output: a completed Sudoku puzzle. Recall that legitimate Sudoku puzzles must have a unique solution. }