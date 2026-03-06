# Z3py N-Queens solver
# TN

import sys

from z3 import *
from math import *
import time

#######################################
## REPLACE THIS WITH Z3 LIB/so LOCATION
#######################################
init('/Users/tim/git/z3/build/')

# N-queens using boolean variables

n = int(input("Enter n: "))

t0 = time.time()

s = Solver()
#s.set("unsat_core", True)


# One boolean variable for each square: is there a queen there or not?
board = [[ Bool('q%i_%i' % (i,j)) for j in range(n)] for i in range(n) ]

# Exactly one queen per row
for row in range(n):
	# >= 1
	s.add(Or([ board[row][j-1] for j in range(n)]))
	# < 2: if true in one column, not true in all others
	for col in range(n):
		for col2 in range(col, n):
			if col != col2:
				s.add(Or([ Not(board[row][col]), Not(board[row][col2]) ]))

print(len(s.assertions()), "clauses after row constraints")

# Exactly one queen per column
for col in range(n):
	# >= 1
	s.add(Or([ board[j-1][col] for j in range(n)]))
	# < 2: if true in one row, not true in all others
	for row in range(n):
		for row2 in range(row, n):
			if row != row2:
				s.add(Or([ Not(board[row][col]), Not(board[row2][col]) ]))

print(len(s.assertions()), "clauses after column constraints")

# At most one queen per diagonal; expressed as series of 2-literal clauses (quadratic in N)
# But each will be an easy unit-propagation! Remember that \/ is symmetric.
for row in range(n):
	for col in range(n):
		# All \ (down) excluded if true (row+, col+)		
		for offset in range(1, n-max(row, col)):     # No +1 here since n is already 1-based; Python range is [a,b) interval
			s.add(Or( Not(board[row][col]), Not(board[row+offset][col+offset])))
		# All / (down) excluded if true (row+, col-)
		for offset in range(1, min(n-row-1, col)+1): # +1 because no 1-based n to start from			
			s.add(Or( Not(board[row][col]), Not(board[row+offset][col-offset])))

print(len(s.assertions()), "clauses total")

t1 = time.time()

if s.check() == sat:
	soln = s.model()
	print(['q%i_%i' % (i,j) for i in range(n) for j in range(n) if soln.eval(board[i-1][j-1])])
else:
	# Z3py's core support will only say which /assumptions/, not which clauses
	# (even with unsat-core parameter turned on, it seems)
	print("unsat")


t2 = time.time()

print("Setup time: ", floor((t1-t0) * 1000), "ms.")
print("Solving time: ", floor((t2-t1) * 1000), "ms.")

#print(s.help())