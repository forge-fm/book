# Field Multiplicity

While types define what kinds of data can fit into a specific field, _multiplicities_ define how that data can be arranged. For example, multiplicities will say whether or not a field can be empty.


## Singleton fields 

If you're declaring a field that is meant to hold a single value, and not something like a function, there are two possible multiplicities: `one` (which means that a value must always be present) and `lone` (which means that a value _may_ be present). 

- `one`: a singleton value (this field always contains a single object); and
- `lone`: either a singleton value or no value (this field contains 0 or 1 object).

~~~admonish example title="Examples"
This definition of a `Student` sig enforces that every student has an advisor, but not every student has a concentration.
```
sig Student {
    advisor: one Faculty, 
    concentration: lone Concentration
}
```
If we later write constraints about students, it is possible for a student's concentration to evaluate to `none`. 
~~~


## Set fields (Relational and Temporal Forge only)

If you're declaring a field that holds a set of atoms, use the `set` multiplicity.

~~~admonish example title="Examples"
Let's add a field for the friends a student has at Brown:
```
sig Student {
    advisor: one Faculty, 
    concentration: lone Concentration,
    friends: set Student -- in reality, perhaps not only students!
}
```

A student's friends may evaluate to `none`, just as in the `lone` multiplicity. But it might also evaluate to set of more than one student.
~~~

~~~admonish warning title="No sets in Froglet!" 
Froglet does not support the `set` multiplicity, because sets add a layer of complexity to the language. If you _really_ need to model sets in Froglet, you an approximate them using boolean-valued functions (see below).
~~~

## Function Fields 

If you want a field that is a function or partial function, use the `func` or `pfunc` multiplicities. (If you view singleton fields as functions that take no arguments, `func` and `pfunc` are analogous to `one` and `lone`.) These multiplicities only work if the field's type involves more than one sig. Suppose we are defining a function field meant to map elements of $A \times B \times ... \times Y$ to elements of $Z$. Then:

- `func A -> B -> ... -> Y -> Z`: denotes a total function with the above domain and co-domain. Because it is a _total_ function, every possible input must have exactly one output value.
- `pfunc A -> B -> ... -> Y -> Z`: denotes a partial function with the above domain and co-domain. Because the function may be partial, every possible input has either one output value or is not mapped by the function.

~~~admonish example title="Examples"
Let's add a function that says what grade a student got in a given class. Because students don't take every course available, we might use a partial function for this:
```
sig Student {
    advisor: one Faculty, 
    concentration: lone Concentration,
    grades: pfunc Course -> Grade
}
```
If we later write constraints about students, it is possible for a student's grade in a particilar class to evaluate to `none`.
~~~

~~~admonish note title="Intuition" 
Fields declared as `pfunc` are analogous to maps or dictionaries in an object-oriented programming language: some keys may not map to values, but if a key is mapped it is mapped to exactly one value. 

Keep in mind that, unlike in (say) Java, the functions themselves are not objects on a heap, but rather just tables of values being mapped to other values.
~~~

## Relation Fields (Relational and Temporal Forge only)

If you want a field to represent an arbitrary _relation_ that may or may not be a function, use the `set` multiplicity instead of `pfunc` or `func`.

~~~admonish example title="Examples"
Perhaps we want to keep track of the set of project partners a student had during a particular course:
```
sig Student {
    advisor: one Faculty, 
    concentration: lone Concentration,
    partnersIn: set Course -> Student
}
```
Now, for a given student, `partnersIn` might map to more than one student for a given class. Neither `func` nor `pfunc` would allow this.
~~~


~~~admonish warning title="No sets in Froglet!" 
Froglet does not support the `set` multiplicity, because sets add a layer of complexity to the language. If you _really_ need to model sets in Froglet, you an approximate them using boolean-valued functions (see below).
~~~

~~~admonish tip title="Approximating sets and relations in Froglet"
If you really need something like sets, but are working in Froglet, you can use the following trick.

```
abstract sig Boolean {}
one sig True, False extends Boolean {}
sig Student {
    advisor: one Faculty, 
    concentration: lone Concentration,
    partnersIn: func (Course -> Student) -> Boolean
}
```

Alternatively, you can represent booleans _slightly_ more efficiently as the presence (or non-presence) of a mapping in a partial function:

```
one sig Yes {}
sig Student {
    advisor: one Faculty, 
    concentration: lone Concentration,
    partnersIn: pfunc (Course -> Student) -> Yes
}
```
~~~