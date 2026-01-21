#lang forge/bsl
abstract sig Player {}
one sig X, O extends Player {}

sig Board {
  board: pfunc Int -> Int -> Player
}

-- a Board is well-formed if and only if:
pred wellformed[b: Board] {
  -- row and column numbers used are between 0 and 2, inclusive  
  all row, col: Int | {
    (row < 0 or row > 2 or col < 0 or col > 2) 
      implies no b.board[row][col]      
  }
}

-- Uncomment to run
-- run { some b: Board | wellformed[b]} 

-- Let's write two _tests_ for this predicate
pred all_wellformed { all b: Board | wellformed[b]}
example firstRowX_wellformed is {all_wellformed} for {
  Board = `Board0 
  X = `X      O = `O 
  Player = X + O
  `Board0.board = (0, 0) -> `X +
                  (0, 1) -> `X + 
                  (0, 2) -> `X 
}

example off_board_not_wellformed is {not all_wellformed} for {
  Board = `Board0 
  X = `X      O = `O 
  Player = X + O
  `Board0.board = (-1, 0) -> `X +
                  (0, 1) -> `X + 
                  (0, 2) -> `X 
}


pred starting[s: Board] {
  all row, col: Int | 
    no s.board[row][col]
}

pred XTurn[s: Board] {
  #{row, col: Int | s.board[row][col] = X} =
  #{row, col: Int | s.board[row][col] = O}
}

pred OTurn[s: Board] {
  #{row, col: Int | s.board[row][col] = X} =
  add[#{row, col: Int | s.board[row][col] = O}, 1]
}

pred winRow[s: Board, p: Player] {
  -- note we cannot use `all` here because there are more Ints  
  some row: Int | {
    s.board[row][0] = p
    s.board[row][1] = p
    s.board[row][2] = p
  }
}

pred winCol[s: Board, p: Player] {
  some column: Int | {
    s.board[0][column] = p
    s.board[1][column] = p
    s.board[2][column] = p
  }      
}

pred winner[s: Board, p: Player] {
  winRow[s, p]
  or
  winCol[s, p]
  or 
  {
    s.board[0][0] = p
    s.board[1][1] = p
    s.board[2][2] = p
  }
  or
  {
    s.board[0][2] = p
    s.board[1][1] = p
    s.board[2][0] = p
  }  
}


pred balanced[s: Board] {
  XTurn[s] or OTurn[s]
}
-- Uncomment to run
--run { some b: Board | wellformed[b] and balanced[b]} 


-- Uncomment to run
-- run { some b: Board | wellformed[b] and balanced[b]} for exactly 1 Board

-- Uncomment to run
run { all b: Board | wellformed[b] and balanced[b]} 