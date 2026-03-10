
# (Example borrowed from Aaron Bradley)
# Is the property "y >= 1" always true in the loop? I.e., is "y >= 1" an invariant? 
#    Yes. It's a trivial example.
# Real systems are more complex, and the idea goes way beyond Forge. 
# So let's use this as practice with using the inductive method.

def f1():
    x = 1          # Initial State (part 1)
    y = 1          # Initial State (part 2)
    while True:
        assert(y >= 1) # the invariant
        print(f'x: {x}, y: {y}')
        # Transition (one line so both run based on last loop's values)
        x, y = x + 1, y + x  
f1()

# Base case (called "initiation" in some textbooks)

# FILL: (initial state condition) implies (property goal)
# FILL: (Does this implication hold? If not, why not?)



# Inductive case (called "consecution" in some textbooks)
#   Suggestion: 2 states involved, so use x_pre, x_post, y_pre, y_post.
# FILL: (P holds of prestate) and (transition taken) implies (P holds of poststate)
# FILL: (Does this implication hold? If not, why not?)

## Given: P holds of prestate: y_pre >= 1 
## Given: take a transition:  
##    - x_post = x_pre + 1 
##    - y_post = y_pre + x_post
## Do these 3 taken together imply y_post >= 1? No!

## But we can enrich the invariant. We know that x_pre can never be negative, 
## and the invariant doesn't express this yet. So let's add it:
# "y >= 1 and x >= 0"
# This will pass now.
# We say that "the original property is inductive _relative to_ x >= 0"
