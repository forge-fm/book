# Produce N-queens problem as DIMACS file, then invoke glucose on it.

from math import *
import time
import os

# N-queens using boolean variables

n = int(input("Enter n: "))


# One boolean variable for each square: is there a queen there or not?
numvars = n*n

t0 = time.time() # start time

problemClauses = [] # build a list of clauses

# 0-based input, 1-based output
def getv(row, col):
	return n*row + col + 1

# secondary variables for symmetry-breaking predicate
def getsbv(bit):
	return numvars + bit

# Exactly one queen per row
for row in range(n):
	# >= 1
	problemClauses.append([ getv(row, j) for j in range(n)])
	# < 2: if true in one column, not true in all others
	for col in range(n):
		for col2 in range(col+1, n):			
			problemClauses.append([ -getv(row,col), -getv(row,col2) ])

print len(problemClauses), "clauses after row constraints"

# Exactly one queen per column
for col in range(n):
	# >= 1
	problemClauses.append([getv(j, col) for j in range(n)])
	# < 2: if true in one row, not true in all others
	for row in range(n):
		for row2 in range(row+1, n):			
				problemClauses.append([ -getv(row,col), -getv(row2,col)])

print len(problemClauses), "clauses after column constraints"

# At most one queen per diagonal; expressed as series of 2-literal clauses (quadratic in N)
# But each will be an easy unit-propagation! Remember that \/ is symmetric.
for row in range(n):
	for col in range(n):
		# All \ (down) excluded if true (row+, col+)		
		for offset in range(1, n-max(row, col)):     # No +1 here since n is already 1-based; Python range is [a,b) interval
			problemClauses.append([-getv(row,col), -getv(row+offset,col+offset)])
		# All / (down) excluded if true (row+, col-)
		for offset in range(1, min(n-row-1, col)+1): # +1 because no 1-based n to start from			
			problemClauses.append([-getv(row,col), -getv(row+offset,col-offset)])

print len(problemClauses), "clauses total"

t1 = time.time()
print "Setup time: ", floor((t1-t0) * 1000), "ms."
#print problemClauses

verbose = True

########################################################
def run(numVars, myClauses):
	t1 = time.time()
	filename = 'nq%i.cnf' % n
	outf = open(filename, "w")
	outf.write('c DIMACS for %i queens\n' % n)
	outf.write('c \n')
	outf.write('p cnf %i %i\n' % (numVars, len(myClauses)))
	for c in myClauses:
		for lit in c:
			outf.write(str(lit))		
			outf.write(' ')
		outf.write('0\n') # don't forget the terminating zero!
	outf.close()

	# Solve!
	#status = os.system("~/Downloads/glucose-syrup-4.1/simp/glucose_static -model %s | grep \"^v.*\" > nqout.txt" % filename)
	#status = os.system("~/glucose-syrup-4.1/simp/glucose -model %s | grep \"^v.*\" > nqout.txt" % filename)
	status = os.system("~/glucose-syrup-4.1/simp/glucose -model %s > nqout.txt" % filename)
	if status == 256 :
		print "SAT solver exited with status 256"
		exit()

	t2 = time.time()
	if verbose:
		print "Solving time (Glucose): ", floor((t2-t1) * 1000), "ms."

	inf = open('nqout.txt', "r")
	lines = inf.readlines()
	inf.close()
	#print lines
	# sat or unsat?
	for line in lines:
		if line.startswith("s UNSATISFIABLE"):
			return [] # unsat proxy
		elif line.startswith("v "):
			return handleModel(line)
	return []

def handleModel(line):
	lst = line.split()
	lst = lst[1:] # starts with v
	lst = map(lambda x: int(x), lst) # convert to int
	lst = filter(lambda x: x <= numbits, lst) # keep only primaries
	lst = filter(lambda x: x>0, lst) # keep only true variables
	lst = map(lambda x: ((x-1) / n, (x-1) % n), lst) # convert to locations on board (0-indexed)
	# Note in above, in n=4, var 12 is (2, 3) in 0-indexed, hence the -1 
	if verbose:
		print "Solution: ",lst
	if len(lst) != n:
		print line
		print "error converting model to solution!"
		exit()
	return lst

soln = run(numbits, problemClauses)

# just produce a clause that is the negation OF THE PRIMARIES
def buildRestrictionClause(soln):
	restrictionClause = []
	truths = map(lambda (r,c): getv(r,c), soln)
	#print truths
	for bit in range(1, numbits+1):
		if bit not in truths:
			restrictionClause.append(bit)
		else:
			restrictionClause.append(-bit)
	#print "restrict:", restrictionClause
	return restrictionClause

def runall(numVars, myClauses):
	# note: NOT YET incremental; fresh solver invocation per soln
	# TODO: crashes or runs forever :-) 
	solns = []
	restrictionClauses = []
	soln = run(numVars, myClauses)
	while len(soln) > 0:
		validateSolution(soln)
		solns.append(soln)
		restrictionClauses += [buildRestrictionClause(soln)]
		#print "restrictions: ", restrictionClauses
		soln = run(numVars, myClauses + restrictionClauses)
	return solns





# Some Validation
def validateSolution(s):
	onePerRow = all(any((thisrow == thatrow) 
	                	for thatrow in map(lambda tup: tup[0], soln)) 
	            	for thisrow in range(n))
	#print "onePerRow", onePerRow
	onePerCol = all(any((thiscol == thatcol) 
	                	for thatcol in map(lambda tup: tup[1], soln)) 
	            	for thiscol in range(n))
	#print "onePerCol", onePerCol

	# lst.append((2, 5)) #for n=10, should yield false (+). 
	# lst.append((0, 3)) #for n=10, should yield false (-). 

	# Is there an offset where position is equal to the other plus the offset?
	multiPerDiag = any(any((offset != 0 and pos1[0] == pos2[0]+offset and pos1[1] == pos2[1]+offset)
	                   	for pos1 in s for pos2 in s)
	             	for offset in range(-n, n+1))
	#print "onePerDiag", not(multiPerDiag)

	nPieces = len(s) == n
	#print "eightPieces", eightPieces
	if(not onePerRow or not onePerCol or multiPerDiag or not nPieces):
		print "Invalid solution!"
		exit()

validateSolution(soln)	

###################################################

print "\n\n\n"

# Version with symmetry-breaking
# Break only vertical symmetry at first

vsym = {}
for row in range(n):
	for col in range(n):
		srow = n - row - 1		
		vsym[getv(row,col)] = getv(srow, col)
#print "vertical symmetry mapping: ", vsym

# add the lex-leader symmetry breaking predicate, up to k bits

# full symmetry-breaking pred would be n^2 bits.
# This shouldn't matter for you --- see note below --- you may be able
# to get away without adding fresh variables yourself (let Z3 do it).
sblength = n 

sbClauses = []

# add definition of symmetry-breaking helpers for this one symmetry
for bit in range(1, sblength+1):
	# b /\ sym(b) -> helper
	sbClauses.append([-bit, -vsym[bit], getsbv(bit)])
	# ~b /\ ~sym(b) -> helper
	sbClauses.append([bit, vsym[bit], getsbv(bit)])
	# helper /\ b -> sym(b)
	sbClauses.append([-getsbv(bit), -bit, vsym[bit]])
	# helper /\ sym(b) -> b
	sbClauses.append([-getsbv(bit), -vsym[bit], bit])


## this elaborate approach isn't necessary in Z3,
# if we're willing to let Z3 do its own CNF conversion. The solver
# I'm using here can't do that itself. Try adding each high-level
# constraint and see what happens? E.g.,
# 1 <-> 13 and 2 <-> 14 and 3 => 15

priorbits = []
# make sure to start at bit 1 (bit 0 isn't defined)
for bit in range(1, sblength+1):		
	# start with prior-bit equalities in antecedent
	thisclause = [ -getsbv(pb) for pb in priorbits ]
	# bit -> vsym(bit)	
	thisclause += [-bit, vsym[bit] ]
	sbClauses.append(thisclause)
	#print "adding symmetry-breaking clause: ",thisclause
	priorbits.append(bit)

########################################



#print clauses

#print len(sbClauses), "clauses from vertical SB"
#random.shuffle(sbClauses)

 # double for full SB of this one symmetry
#soln2 = run(numbits + sblength, problemClauses+sbClauses)
#validateSolution(soln)

#print "\n\n======= RUNNING FOR ALL =======\n\n"

#t0 = time.time()
#allSolutions = runall(numbits, problemClauses)
#t1 = time.time()
#allSolutionsSB = runall(numbits+sblength, problemClauses + sbClauses)
#t2 = time.time()
#print "there were",len(allSolutions),"solutions overall; obtained in",(t1-t0)
#print "there were",len(allSolutionsSB),"solutions overall; obtained in",(t2-t1)
