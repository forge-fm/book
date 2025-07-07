from z3 import Solver, Bool, Bools, Ints, ForAll, Reals, Real, Function, IntSort, And, Or, Implies, Not, sat, unsat

def demoBool():
    # Create a new solver
    s = Solver()
    # declare some boolean *solver* variables
    p, q = Bools('p q')         
    s.add(Or(p, q))
    if s.check() == sat:        
        print(s.model()) # "model" ~= "instance" here :/
    # (Think: how would we get a different instance?)
    # getting at pieces of a model for programmatic use
    print(s.model().evaluate(p)) # can pass a formula    




def demoUninterpreted():
    s = Solver()
    # ; Ints, UNINTERPRETED Functions (think of as like relations in Alloy)        
    a, b = Ints('a b')  
    f = Function('f', IntSort(), IntSort())
    s.add(And(b > a, f(b) < f(a)))        
    if s.check() == sat:        
        print(s.model()) 
        print(s.model().evaluate(f(a)))
        print(s.model().evaluate(f(b)))
        print(s.model().evaluate(f(1000000)))





 # Real numbers
def demoReals():
    s = Solver()
    # TN TODO: what's going on with Int
    x = Real('x') # contrast to: Int('x')  
    s.add(x*x > 4)
    s.add(x*x < 9)
    result = s.check()
    if result == sat:
        print(s.model())    
    else: 
        print(result)





def demoFactoringIntWithUniversal():
    s = Solver()

    # (x - 2)(x + 2) = x^2 - 4
    # Suppose we know the RHS and want to find an *equivalent formula* LHS. 
    # We will solve for the roots:
    # (x - ROOT1)(x + ROOT2) = x^2 - 4

    xi, r1i, r2i = Ints('x root1 root2') # int vars

    # Note: don't try to use xi ** 2; this isn't translated properly as of 2024.
    s.add(ForAll(xi, (xi + r1i) * (xi + r2i) == (xi * xi) - 4  ))
    result = s.check()
    if result == sat:
        print(s.model())    
    else: 
        print(result)

    s.reset()   

    # Try another one: 
    # (x + 123)(x - 321) = x^2 - 198x - 39483
    s.add(ForAll(xi, (xi + r1i) * (xi + r2i) 
                     == (xi * xi) + (198 * xi) - 39483))
    result = s.check()
    if result == sat:
        print(s.model())    
    else: 
        print(result)
    # Note how fast, even with numbers up to almost 40k. Power of theory solver.





def demoFactoringReals():
    s = Solver()
    x, r1, r2 = Reals('x root1 root2') # real number vars
    # ^ As before, solve for r1, r2 because they are unbound in outer constraints
    #   x is quantified over and therefore not a var to "solve" for

    # (x + ???)(x + ???) = x^2 - 198x - 39484         
    s.add(ForAll(x, (x + r1) * (x + r2) 
                     == (x * x) + (198 * x) - 39484))
    result = s.check()
    if result == sat:
        print(s.model())    
    else: 
        print(result)

def demoFactoringRealsUnsat():
    s = Solver()

    # Here's how to start using cores in Z3 if you want, but
    # see the docs -- it's a bit more annoying because you need to create 
    # new boolean variables etc.

    s.set(unsat_core=True) # there are so many options, at many different levels

    x, r1, r2 = Reals('x root1 root2') # real number vars

    # Note e.g., x^2 - 2x + 5 has no real roots (b^2 - 4ac negative)
    # To enable core extraction, we need to name every top-level constraint we want to blame
    s.assert_and_track(ForAll(x, (x + r1) * (x + r2) 
                             == (x * x) - (2 * x) + 5), 'constr1')

    result = s.check() 
    if result == sat:
        print(s.model())    
    else: 
        print(result)
        # Note: it's a method of the solver, not the result. 
        print(s.unsat_core())
        






def nQueens(numQ):
    s = Solver()
    # Model board as 2d list of booleans. Note the list is *Python*, booleans are *Solver*
    cells = [ [ Bool("cell_{i}{j}".format(i=i,j=j)) 
                for j in range(0, numQ)] 
                for i in range(0, numQ) ]
    #print(cells)
    
    # a queen on every row
    queenEveryRow = And([Or([cells[i][j] for j in range(0, numQ)]) for i in range(0, numQ)])
    #print(queenEveryRow) # for demo only
    s.add(queenEveryRow)

    # for every i,j, if queen present there, implies no queen at various other places
    # Recall: queens can move vertically, horizontally, and diagonally.
    # "Threaten" means that a queen could capture another in 1 move. 
    queenThreats = And([Implies(cells[i][j], # Prefix notation: (And x y) means "x and y".
                                And([Not(cells[i][k]) for k in range(0, numQ) if k != j] +
                                    [Not(cells[k][j]) for k in range(0, numQ) if k != i] +
                                    # Break up diagonals and don't try to be too smart about iteration
                                    [Not(cells[i+o][j+o]) for o in range(1, numQ) if (i+o < numQ and j+o < numQ) ] +
                                    [Not(cells[i-o][j-o]) for o in range(1, numQ) if (i-o >= 0 and j-o >= 0) ] +
                                    # flipped diagonals
                                    [Not(cells[i-o][j+o]) for o in range(1, numQ) if (i-o >= 0 and j+o < numQ) ] +
                                    [Not(cells[i+o][j-o]) for o in range(1, numQ) if (i+o < numQ and j-o >= 0) ]
                                    ))
                        for j in range(0, numQ)
                        for i in range(0, numQ)])
    #print(queenThreats) # for demo only
    s.add(queenThreats)
    
    # print(s)
    if s.check() == sat:
        for i in range(0, numQ):
            print(' '.join(["Q" if s.model().evaluate(cells[i][j]) else "_" for j in range(0, numQ) ]))
    else: 
        print("unsat")








if __name__ == "__main__":
    #demoBool()
    #demoUninterpreted()
    #demoReals()
    
    #demoFactoringIntWithUniversal()
    #demoFactoringReals()
    #demoFactoringRealsUnsat()
    
    nQueens(8)


