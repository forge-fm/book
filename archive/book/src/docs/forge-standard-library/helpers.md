# Helpers

Forge and Frglet provide a number of built-in helpers to ease your work in the language.

## Sequences

A sequence is a field `f` of the form `f: pfunc Int -> A` (where `A` can be any `sig`) such that:

- `f` is a partial function (i.e., each `Int` has at most one corresponding entry);
- no index `Int` is less than zero; and
- indexes are contiguous (e.g., if there are entries at index `1` and index `3`, there must be one at index `2`).

You can think of sequences as roughly analogous to fixed-size arrays in a language like Java. To tell Forge that a partial-function field `f` is a sequence, use the `isSeqOf` predicate.

Hint: make sure that you use `isSeqOf` in any test or run that you want to enforce that `f` is a sequence. The `isSeqOf` predicate is just another constraint: it's not a persistent declaration like `pfunc` is.

#### isSeqOf

- `isSeqOf[f, A]`: a predicate that holds if and only if `f` is a sequence of values in `A`.

### Sequence Helpers

The following helpers are also available, but should only be used when `f` is a sequence:

#### Sequence Helper Functions:

- `seqFirst[f]`: returns the first element of `f`, i.e. `f[0]`.
- `seqLast[f]`: returns the last element of `f`.
- `indsOf[f, e]`: returns all the indices of `e` in `f`.
- `idxOf[f, e]`: returns the first index of `e` in `f`.
- `lastIdxOf[f, e]`: returns the last index of `e` in `f`.
- `elems[f]`: returns all the elements of `f`.
- `inds[f]`: returns all the indices of `f`.

#### Sequence Helper Predicates:

- `isEmpty[f]`: true if and only if sequence `f` is empty.
- `hasDups[f]`: true if and only if sequence `f` has duplicates (i.e., there are at least two indices that point to the same value).

## Reachability

Forge provides a convenient way to speak of an object being reachable via fields of other objects.

- `reachable[a, b, f]`: object `a` is reachable from `b` through recursively applying field `f`. This predicate only works if `a.f` is well-defined.
- `reachable[a, b, f1, f2, ...]`: an extended version of `reachable` which supports using more than one field to reach `a` from `b`.

The extended version of reachable is useful if you wish to model, e.g., binary trees where nodes have a `left` and `right` field. In such a model, if you want to quantify over all descendents of a `parent` node, you might write `all n: Node | reachable[n, parent, left, right]`.

~~~admonish title="Order matters!"
Beware: the order of arguments in `reachable` matters! The first argument is the object _to be reached_, and the second argument is the _starting object_. Getting these reversed is a common source of errors.
~~~

~~~admonish title="The value `none` is reachable from anything"
Beware: if you pass something that might be `none` as the first argument of `reachable`, in such cases `reachable` will evaluate to true. E.g., `reachable[p.spouse, p, father]` will evaluate to true if `p` happens to be unmarried.
~~~