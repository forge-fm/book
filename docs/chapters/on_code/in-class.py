def f(x: int, y: int): # path: true; map: {x: INIT_X, y: INIT_Y}
    if x > y: # (INIT_X > INIT_Y) is evaluated HERE
        # path: (x > y); map: {x: INIT_X, y: INIT_Y}
        tmp = x # path: (INIT_X > INIT_Y); map: {x: INIT_X, y: INIT_Y, tmp: INIT_X} 
        x = y   # path: (INIT_X > INIT_Y); map: {x: INIT_Y, y: INIT_Y, tmp: INIT_X}
        # *******************
        # NOTE WELL: don't write "x > y" in the path formula. Write them in terms of 
        # symbolic values, not program variables! If you use program variables, you
        # add a layer of indirection, which can lead to confusion. (Try it here.)
        # *******************
        y = tmp # path: (INIT_X > INIT_Y); map: {x: INIT_Y, y: INIT_X, tmp: INIT_X}
        if x > 0 and y > 0 and (x-y) > 0:
            # path: (INIT_X > INIT_Y) and (INIT_Y > 0) and
            #       (INIT_X > 0) and (INIT_Y - INIT_X) > 0
            # map: {x: INIT_Y, y: INIT_X, tmp: INIT_X}
            raise Exception() # Can this be reached? (No! Unsat path condition)
    # path: true; 
    # map: {x: IF(INIT_X > INIT_Y,INIT_Y,INIT_X), 
    #       y: IF(INIT_X > INIT_Y,INIT_X,INIT_Y), 
    #     tmp: >.> PYTHON NO} 
    # **********************
    # Joking aside, I am removing tmp from the mapping because it should be 
    # out of scope. (If you haven't seen what I'm referring to, try running 
    # the program and referring to tmp here.)
    # **********************
    z = x * 128  
    # map: {x: IF(INIT_X > INIT_Y,INIT_Y,INIT_X), 
    #       y: IF(INIT_X > INIT_Y,INIT_X,INIT_Y),
    #       z: IF(INIT_X > INIT_Y,INIT_Y,INIT_X) * 128 }
    w = x % 256   
    # map: {x: IF(INIT_X > INIT_Y,INIT_Y,INIT_X), 
    #       y: IF(INIT_X > INIT_Y,INIT_X,INIT_Y),
    #       z: IF(INIT_X > INIT_Y,INIT_Y,INIT_X) * 128,
    #       w: IF(INIT_X > INIT_Y,INIT_Y,INIT_X) % 256 }
    if w == 0:    
        # path: true and (IF(INIT_X > INIT_Y,INIT_Y,INIT_X) % 256 == 0)
        # (SATISFIABLE!)
        # **********************
        # QUESTION: do we have to worry about overflow? 
        # Answer: depends on the language and datatypes. SMT is cool, it will 
        # let us pick bit-vector *or* mathematical ints as we wish. 
        # **********************
        raise Exception() # Can this be reached? (x=256, any y >= 256)
