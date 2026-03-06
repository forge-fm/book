# Inheritance

Sigs may inherit from other sigs via the `extends` keyword:

```clike
sig <name> extends <parent sig name> {
    <additional fields> ...
}
```

Sigs may only have _at most one parent sig_. Moreover, much like how no object can be belong to multiple top-level sigs, no object can belong to more than one immediate child of any sig. That is, any two sigs `A` and `B` will never contain an object in common unless one is a descendent of the other. 

~~~admonish example title="Different kinds of cat"

```clike
sig Cat {
    favoriteFood: one Food
}
sig ActorCat extends Cat {
    playName: one Play
}
sig ProgrammerCat extends Cat {}
```

This means that any `ProgrammerCat` object is also a `Cat` object, and so will have a `favoriteFood` field. But only `ActorCat`s have the `playName` field. Moreover, any cat may be either an `ActorCat`, `ProgrammerCat`, or neither---but not both.
~~~

~~~admonish warning title="Inheritance and Bounds"

Forge must have bounds for _every_ sig, including child sigs. The default of 0-to-4 objects is applied to every top-level sig. Forge can often infer consistent bounds for child sigs, but it cannot always do so and will require you to provide them. This is most often the case in the presence of complex hierarchies involving `abstract` and `one` sigs. 

More importantly, `example` and `inst` syntax require the contents of parent sigs to be defined once the contents of a single child are set. To see why, consider this example:

```clike
example workingCats is {myPredicate} for {
    ActorCat = `ActorCat0 + `ActorCat1
    ProgrammerCat = `ProgrammerCat0 + `ProgrammerCat1
}
```
This produces an error: 
> run: Please specify an upper bound for ancestors of ActorCat.

This error occurs because Forge knows only that there are 2 specific actors and 2 specific programmers, and can't infer whether any _other_ cats exist. To fix the error, provide bounds for the parent sig:

```clike
example workingCats is {myPredicate} for {    
    ActorCat = `ActorCat0 + `ActorCat1
    ProgrammerCat = `ProgrammerCat0 + `ProgrammerCat1
    Cat = `ActorCat0 + `ActorCat1 + `ProgrammerCat0 + `ProgrammerCat1
}
```

~~~


