# Home

Forge is a lightweight modeling language, similar to [Alloy](https://alloytools.org), that has been designed for _teaching_ modeling and lightweight formal methods. It comprises three sublanguages or modes:

- **Froglet** (`#lang forge/bsl`), a language for modeling using only functions and partial functions;
- **Relational Forge** (`#lang forge`), an extension of Froglet to include relations and relational operators;
- **Temporal Forge** (`#lang forge/temporal`), an extension of Forge to include linear-temporal operators (akin to Alloy 6 or [Electrum](https://github.com/haslab/Electrum)).

Students can progress through this language hierarchy as new concepts are introduced in class; this lets the course avoid a steep language-learning curve and cover important practical material earlier than would otherwise be possible.

~~~admonish note title="If there are three languages, are there three versions of the documentation?"
**No!** In principle, we might ideally have three separate versions, but we are focusing (for now) on 
producing better documentation overall rather than taking on the subtle cross-language page-linking challenge. 

We will nevertheless try to maintain a reasonable separation. 
~~~

```admonish hint title="Table of Contents, Theme, and Search"
This page has three buttons for popping out the table of contents, changing the color theme, and searching. If you do not see them, please ensure that JavaScript is enabled.

<center>
If the table of contents isn't open, click this button:
<label id="sidebar-toggle-alternate" class="icon-button" for="sidebar-toggle-anchor" title="Toggle Table of Contents" aria-label="Toggle Table of Contents (Alternate Button)" aria-controls="sidebar">
                            <i class="fa fa-bars"></i>
                        </label>

The table of contents is expandable. Once it is open, cxlick the ❱ icons to expand individual sections and subsections to browse more easily! 

To change the color theme of the page, click this button:
<button id="theme-toggle" class="icon-button" type="button" title="Change theme" aria-label="Change theme (Alternate Button)" aria-haspopup="true" aria-expanded="false" aria-controls="theme-list">
                            <i class="fa fa-paint-brush"></i>
                        </button>

To search, click this button:
<button id="search-toggle" class="icon-button" type="button" title="Search. (Shortkey: s)" aria-label="Toggle Searchbar (Alternate Button)" aria-expanded="false" aria-keyshortcuts="S" aria-controls="searchbar">
                            <i class="fa fa-search"></i>
                        </button>
</center>
```
