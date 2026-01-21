
This document is current as of **Forge 3.5.1**.


<!-- Searching the Spring 2024 for relational operators wouldn't work, because the search was alphanumeric. But there is an advanced option -- e.g., `#[doc(alias = "x")]` -- will this work?

## A header on relational transpose

<!-- #[doc(alias = "~")] -->

relational transpose `~` blah blah

 A hidden annotation works for directing a search for `foobarbaz`

```forge
~ #[doc(alias = "foobarbaz")]
example using ~
...
...

```

But unfortunately, not for `~` itself:

```forge
~ #[doc(alias = "~")]
example using ~
...
...

``` -->