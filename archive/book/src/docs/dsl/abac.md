# Attribute-Based Access Control 

The Attribute-Based Access Control (ABAC) language can be enabled via `#lang forge/domains/abac` on the first line of a file. The syntax of the language is totally distinct from Froglet, Relational Forge, and Temporal forge. 


## Purpose

ABAC policies describe whether _requests_ should be permitted or denied. Requests comprise three _variables_:
- `s`: the subject (i.e., the individual or program making the request);
- `a`: the action (i.e., the type of access being requested); and
- `r`: the resource (i.e., the file or other object being acted upon by the request).

```admonish example name="ABAC Policy"
~~~
policy original
  // Administrators can read and write anything
  permit if: s is admin, a is read.
  permit if: s is admin, a is write.
  // Files being audited can't be changed by customers
  deny   if: a is write, r is file, r is under-audit.
  // Customers have full access to files they own
  permit if: s is customer, a is read, r is owned-by s.
  permit if: s is customer, a is write, r is owned-by s.
end;
~~~
```

## Policy Syntax

A policy declaration comprises a name and a set of a rules. The form is:
```
policy <NAME>
  <RULE1>
  <RULE2>
  ...
end;
```

## Rule Syntax

A rule contains a decision and a sequence of conditions, terminated by a period. 

```
<DECISION> if: <CONDITION1>, <CONDITION2>, ... .
```

Decisions may be either:
- `permit`; or 
- `deny`. 

## Condition Syntax

Finally, a condition expresses a requirement involving one of the three request variables. If the condition involves only one variable, it takes the form `<var> is <attribute>`. If the condition involves two variables, it takes the form `<var 2> is <attribute> <var 2>`.

For the moment, the ABAC language is built for a specific assignment. Thus, the vocabulary of the language is restricted to the following attributes: 
- for subjects: `admin`, `accountant`, and `customer`;
- for actions: `read` and `write`;
- for resources: `file`. 
- for combinations of subject and resource: `owner-of` and `under-audit`.

## Analysis Commands 

For the purposes of this assignment, only one command should be necessary:

### Comparing Policies

The `compare` command uses Forge to run a "semantic diff" on two policies. It will produce a single scenario that describes a request where the two policies differ in their decisions, along with which rule applied to cause the difference. 

Like policies, commands must be terminated with a semicolon. 

~~~admonish example title="Comparing two policies"
To compare two policies named `original` and `modified`:
```
compare original modified;
```
In this case, the output might resemble:
```
Comparing policies original and modified...

-----------------------------------
Found example request involving...
a subject <s> that is:  Accountant, Employee
an action <a> that is:  Read
a resource <r> that is: File
Also,
  <r> is Audit

This rule applied in the second policy:
    permit if: s is accountant, a is read, r is under-audit.
Decisions: modified permitted; original denied
```
This indicates that the two policies aren't equivalent. Furthermore, a request
from an accountant to read a file that is under audit will be handled differently
by the two policies---demonstrating the inequivalence.
~~~

### Other Commands 

- `info` prints the names of policies currently defined. 
- `query` can query the behavior of a single policy given a condition. 

~~~admonish example title="An example query"
To ask for scenarios where the `original` policy permits a request
involving someone who is not an administrator:
```
query original yields permit where s is not admin;
```
~~~

## Implementation Notes

At the moment, there is no way to get _another_ example from `compare` or `query`; in practice it would be implemented the same way that Forge's "next" button is. 