# Produce N-queens problem as DIMACS file, then invoke glucose on it.

from math import floor
import time
import os


# Indexing can be annoying (0-based input, 1-based output), so make 
# a helper function to do the computation for us. But the function 
# depends on the dimensions of the board. We could make <n> another
# argument, but here's something else we can do:
def getv_builder(n): 
	return lambda row, col: n*row + col + 1

def setup(n: int) -> list[list[int]]: 
	problemClauses = [] # build up a list of clauses 
	getv = getv_builder(n)

	# Exactly one queen per row
	for row in range(n):
		# Some queen in each row 
		problemClauses.append([ getv(row, j) for j in range(n)])
		# Cannot have >1 queens in this row: either col1 is empty or col2 is.
		for col1 in range(n):
			for col2 in range(col1+1, n):			
				problemClauses.append([ -getv(row,col1), -getv(row,col2) ])

	print(f'{len(problemClauses)} clauses after row constraints')

	# Exactly one queen per column
	for col in range(n):
		# Some queen in each column
		problemClauses.append([getv(j, col) for j in range(n)])
		# Cannot have >1 queens in this column
		for row1 in range(n):
			for row2 in range(row1+1, n):			
					problemClauses.append([ -getv(row1,col), -getv(row2,col)])

	print(f'{len(problemClauses)} clauses after row and column constraints')

	# At most one queen per diagonal, expressed as series of 2-literal clauses.
	# The number of clauses is quadratic in N, but each will be an easy 
	# unit propagation! Remember that \/ is symmetric.
	for row in range(n):
		for col in range(n):
			# All \ (down) excluded if true (row+, col+)		
			for offset in range(1, n-max(row, col)): # No +1 here since n is already 1-based; Python range is [a,b) interval
				problemClauses.append([-getv(row,col), -getv(row+offset,col+offset)])
			# All / (down) excluded if true (row+, col-)
			for offset in range(1, min(n-row-1, col)+1): # +1 because no 1-based n to start from			
				problemClauses.append([-getv(row,col), -getv(row+offset,col-offset)])

	print(f'{len(problemClauses)} clauses total')
	print(f'Setup time: {floor((time.time()-t0) * 1000)} ms.')
	return problemClauses

########################################################
def run(n, numVars, myClauses):
	t1 = time.time()
	
	# Write a file containing the DIMACS-formatted CNF problem
	filename = f'nq{n}.cnf'
	outf = open(filename, "w")
	outf.write(f'c DIMACS for {n} queens\n')
	outf.write('c \n')
	outf.write(f'p cnf {numVars} {len(myClauses)}\n')
	for c in myClauses:
		for lit in c:
			outf.write(str(lit))		
			outf.write(' ')
		outf.write('0\n') # don't forget the terminating zero!
	outf.close()

	
	
	# I don't have glucose on my path, so I'll just give the relative location:
	solver_path = './glucose-4.2.1/parallel/glucose-syrup'

	# Solve: invoke a SAT solver (glucose in this case) on the file
	status = os.system(f'{solver_path} -model {filename} > nqout.txt')
	if status == 256 :
		print('SAT solver exited with status 256; some problem occurred')
		exit()

	t2 = time.time()
	print(f'Solving time (Glucose): {floor((t2-t1) * 1000)} ms.')
	
	# Open the output file that the solver produced
	inf = open('nqout.txt', "r")
	lines = inf.readlines()
	inf.close()

	# Was the result sat or unsat?
	for line in lines:
		if line.startswith("s UNSATISFIABLE"):
			return [] # unsat proxy
		elif line.startswith("v "):
			return handleModel(n, line)
	return []

def handleModel(n: int, line) -> list[tuple[int,int]]:
	lst = line.split()
	lst = lst[1:] # starts with v
	lst = map(lambda x: int(x), lst) # convert to int
	lst = filter(lambda x: x <= numvars, lst) # keep only primaries if more were added
	lst = filter(lambda x: x>0, lst) # keep only *true* variables for display
	sol = list(map(lambda x: (int((x-1) / n), (x-1) % n), lst)) # convert to locations on board (0-indexed)
	# Note in above, in n=4, var 12 is (2, 3) in 0-indexed, hence the -1 

	if len(sol) != n:
		print(line)
		print(f'error: the number of true variables should be ={n}. Got: {sol}!')
		exit()
	return sol

# Some Validation
def validateSolution(s):
	onePerRow = all(any((thisrow == thatrow) 
	                	for thatrow in map(lambda tup: tup[0], soln)) 
	            	for thisrow in range(n))
	if not onePerRow: print(f'Invalid solution: rows should have one queen each.')
	
	onePerCol = all(any((thiscol == thatcol) 
	                	for thatcol in map(lambda tup: tup[1], soln)) 
	            	for thiscol in range(n))
	if not onePerCol: print(f'Invalid solution: columns should have one queen each.')

	# Is there an offset where position is equal to the other plus the offset?
	multiPerDiag = any(any((offset != 0 and pos1[0] == pos2[0]+offset and pos1[1] == pos2[1]+offset)
	                   	for pos1 in s for pos2 in s)
	             	for offset in range(-n, n+1))
	if multiPerDiag: print(f'Invalid solution: queens found on same diagonal')

	nPieces = len(s) == n
	if not nPieces: print(f'Invalid solution: needed {n} queens.')
	
	if onePerRow and onePerCol and not multiPerDiag and nPieces:
		print(f'Solution validated.')

# N-queens using boolean variables
if __name__ == '__main__':
	n = int(input("Enter n: "))

	t0 = time.time() # start time
	# One boolean variable for each square: is there a queen there or not?
	numvars = n*n
	clauses = setup(n)
	soln = run(n, numvars, clauses)
	print(f'Solution:{soln}')
	validateSolution(soln)