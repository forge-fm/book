
# Pseudocode for testing cheapest-path (Dijkstra's, etc.)
#
# def is_valid_cheapest_path(input, output) -> bool:
#   returns true IFF:
#     (1) cost(output) is cost(trustedImplementation(input)) and 
#     (2) every vertex in output is in input's graph and 
#     (3) every step in output is an edge in input and 
# ... and so on ... 

# Now let's do something more concrete, for `median`, in Hypothesis:

################################################

from hypothesis import given, settings
from hypothesis.strategies import integers, lists
from statistics import median

# Tell Hypothesis: inputs for the following function are non-empty lists of integers
# @given(lists(integers(), min_size=1)) 
@given(lists(integers(min_value=-1000,max_value=1000), min_size=1))
# Tell Hypothesis: run up to 500 random inputs
@settings(max_examples=50000)
#@settings(max_examples=500)

# Last version, given in the book/notes

def test_python_median(input_list):
    output_median = median(input_list)
    #print(f'{input_list} -> {output_median}')
    if len(input_list) % 2 == 1:
        assert output_median in input_list
    
    # Question 1: Python's `median` function fails this test! What's going on? 
    lower_or_eq =  [val for val in input_list if val <= output_median]
    higher_or_eq = [val for val in input_list if val >= output_median]
    assert len(lower_or_eq) >= len(input_list) // 2    # // ~ floor
    assert len(higher_or_eq) >= len(input_list) // 2   # // ~ floor
    
    # Question 2: Is this enough? Can we stop here? :-)



# Because of how Python's imports work, this if statement is needed to prevent 
# the test function from running whenever a module imports this one. This is a 
# common feature in Python modules that are meant to be run as scripts. 
if __name__ == "__main__": # ...if this is the main module, then...
    test_python_median()
