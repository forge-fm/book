## How To Read This Book 

Welcome to Logic for Systems! Here are some quick hints that will help you use this book effectively.

~~~admonish note title="This book is a draft!"
This book is a draft, and there are some sections that are currently being filled in. If you want to use these materials and need support (e.g., you want to use the Forge homeworks that go with it, or a specific section you need is incomplete), please contact `Tim_Nelson@brown.edu`. 

Especially during the Spring semester at Brown University, the deployed content of this book may be expanded and improved. 
* If you are a Brown University student taking CSCI 1710, expect the book to be edited as the semester proceeds.
* If you are using the book in your own course or for your own studies, and want a "frozen" version to ensure consistency, we'd be happy to assist you. Please reach out to `Tim_Nelson@brown.edu`. 


~~~

---

### Organization 

The book is organized into a series of short sections, each of which are grouped into chapters: 
* **Chapter 1 (Beyond Testing)** briefly motivates the content in this book and sets the stage with a new technique for testing your software. 
* **Chapter 2 (Modeling Static Scenarios)** provides an introduction to modeling systems in Forge by focusing on systems that don't change over time. 
* **Chapter 3 (Discrete Event Systems)** shows a common way to model the state of a system changing over time. 
* **Chapter 4 (Modeling Relationships)** enriches the modeling language to support arbitrary relations between objects in the world.
* **Chapter 5 (Temporal Specification)** covers temporal operators, which are commonly used in industrial modeling and specification, and how to use them. 
* **Chapter 6 (Case Studies)** touches on some larger applications of lightweight formal methods. Some of these will involve large models written in Forge, and others will lean more heavily on industrial systems.
* The **Forge Documentation**, which covers the syntax of the language more concisely and isn't focused on teaching. At the moment, this is in a [separate document](https://forge-fm.github.io/forge-documentation/) in order to make searching easier.

Each chapter contains a variety of examples: data structures, puzzles, algorithms, hardware concepts, etc. We hope that the diversity of domains covered means that everyone will see an example that resonates with them. Full language and tool documentation come _after_ the main body of the book. 

#### What does this book assume? What is its goal? 

This book does not assume *any* prior background with formal methods or even discrete math. It does assume the reader has written programs before at the level of an introductory college course. 

The goal of this chapter progression is to prepare the reader to formally model and reason about a domain *of their own choosing* in Forge (or perhaps in a related tool, such as an SMT solver). 

With that in mind...

#### Do More Than Read

This book is example driven, and the examples are almost always built up from the beginning. The flow of the examples is deliberate, and might even take a "wrong turn" that is meant to teach a specific lesson before changing direction. If you try to read the book passively, you're likely to be very disappointed. Worse, you may not actually be able to _do_ much with the material after reading.

Instead, **follow along**, pasting each snippet of code or Forge model into the appropriate tool, and try it! Better yet, try modifying it and see what happens. You'll get much more out of each section as a result. Forge especially is designed to aid experimentation. Let your motto be:

<center><strong>Let's find out!</strong></center>
<br/>

---

### Navigating the Book Site

With JavaScript enabled, the table of contents (to the left, by default) will allow you to select a specific section of this book. Likewise, the search bar (enabled via the "Toggle Searchbar" icon) should allow you to search for arbitrary alphanumeric phrases in the full text; unfortunately, non alphanumeric operators are not supported by search at present.

```admonish hint title="Table of Contents, Theme, and Search"
The three buttons for popping out the table of contents, changing the color theme, and searching are in the upper-left corner of this page, by default. If you do not see them, please ensure that JavaScript is enabled.

<center>
If the table of contents isn't open, click this button:
<label id="sidebar-toggle-alternate" class="icon-button" for="sidebar-toggle-anchor" title="Toggle Table of Contents" aria-label="Toggle Table of Contents (Alternate Button)" aria-controls="sidebar">
                            <i class="fa fa-bars"></i>
                        </label>

The table of contents for the Forge documentation is expandable. Once it is open, click the ❱ icons to expand individual sections and subsections to browse more easily! 

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

---

### Callout Boxes

Callout boxes can give valuable warnings, helpful hints, and other supplemental information. They are color- and symbol-coded depending on the type of information. For example:

~~~admonish tip title="This is a helpful tip."
Make sure to stay hydrated; it will help you learn.
~~~

~~~admonish warning title="This is a warning!"
Look both ways before you cross the street!
~~~

~~~admonish note title="This is a side note."
This book is written using the `mdbook` package. 
~~~

If you see a callout labeled "CSCI 1710", it means that it's specifically for students in Brown University's CSCI 1710 course, Logic for Systems.

---

### Exercises

Every now and then, you'll find question prompts, followed by a clickable header that looks like this: 

<details>
<summary>Think, then click!</summary>

**SPOILER TEXT**

</details> 

If you click the arrow, it will expand to show hidden text, often revealing an answer or some other piece of information that is meant to be read _after_ you've thought about the question. When you see these exercises, **don't skip past them**, and **don't just read the hidden text**. 

## Thanks To

The current draft has benefitted from the feedback of many people, including: 
Shriram Krishnamurthi, 
Emily Nelson, 
Hillel Wayne, 
...