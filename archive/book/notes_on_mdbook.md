# Notes on working with mdbook

## Code blocks, formatting them, and running them

"Hidden lines" collapse out portions we may not want to show the fullness of. But this won't 
  work if the 'editable' attribute is present. Still, useful for showing only part of the full model 
  at every stage while still being able to run the full thing (and show the full thing if requested). 

However, that would require being able to _run_; the `runnable` attribute only works for `rust`-annotated blocks by default. This PR from 2 years ago exists;
https://github.com/rust-lang/mdBook/pull/1759
and was referenced in Jan 2024 by this guide PR:
https://github.com/rust-lang/mdBook/pull/2286



