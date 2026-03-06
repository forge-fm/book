# Guide to Unsat Cores in Alloy

This guide is written with Alloy in mind; expand to Forge later.

## What is an Unsat Core?

## Why should I care about Unsat Cores?

Some of these are from Emina's list

### (Verification) The property is too weak

### (Verification) The model is too strong

### The model is over-constrained

### The bounds given are insufficient

Are these different? "things you might do to get a core" vs. "insights gained?" what the cause is vs how to REALIZE that's the cause?

### An expected instance isn't being produced

One option is to run without constraints and use the evaluator. But this doesn't give insight into which PARTS of the instance are problematic, just which constraints are failing (at least at first, without a lot of delving recursively)

Instead, encode a characteristic fmla for the instance. 
Needs to be in simple form (so each literal = a potential highlight)

## How should I interpret an Unsat Core?

## What should I do if my Unsat Core is very large?

## What are the limitations of Unsat Cores?

- it's got to be unsat! so not all overconstraints, etc.

- 

