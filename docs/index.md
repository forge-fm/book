## How To Read This Book 

Welcome to Logic for Systems! Here are some quick hints that will help you use this book effectively.

!!! warning "Book versioning: This is the 2026 edition!" 
    This is the 2026 edition of the book, which is being refined somewhat ahead of the Spring 2026 offering of Logic for Systems at Brown. The notes are improved and more complete, but [the 2025 version](https://forge-fm.github.io/book/2025/) is preserved for those who wish to use it and/or have access to chapters that haven't been revised.

---

!!! note "This book is a draft!"
    This book is a draft, and there are some sections that are currently being filled in. If you want to use these materials and need support (e.g., you want to use the Forge homeworks that go with it, or a specific section you need is incomplete), please contact `Tim_Nelson@brown.edu`. 

    Especially during the Spring semester at Brown University, the deployed content of this book may be expanded and improved.

    * If you are a Brown University student taking CSCI 1710, expect the book to be edited as the semester proceeds.
    * If you are using the book in your own course or for your own studies, and want a "frozen" version to ensure consistency, we'd be happy to assist you. Please reach out to `Tim_Nelson@brown.edu`.


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

The table of contents (to the left, by default) allows you to select a specific section of this book. Use the search icon to search for text in the book.

!!! hint "Searching for special characters"
    Some characters have special meaning in search. To search for operators like `+`, escape them with a double backslash: `\\+`.


---

### Callout Boxes

Callout boxes can give valuable warnings, helpful hints, and other supplemental information. They are color- and symbol-coded depending on the type of information. For example:

!!! tip "This is a helpful tip."
    Make sure to stay hydrated; it will help you learn.


!!! warning "This is a warning!"
    Look both ways before you cross the street!


!!! note "This is a side note."
    This book is written using `mkdocs` with the Material theme.


If you see a callout labeled "CSCI 1710", it means that it's specifically for students in Brown University's CSCI 1710 course, Logic for Systems.

---

### Exercises

Every now and then, you'll find question prompts, followed by a clickable header that looks like this: 

??? note "Think, then click!"
    **SPOILER TEXT**
 

If you click the arrow, it will expand to show hidden text, often revealing an answer or some other piece of information that is meant to be read _after_ you've thought about the question. When you see these exercises, **don't skip past them**, and **don't just read the hidden text**. 

## Thanks To

The current draft has benefitted from the feedback of many people, including: 
Shriram Krishnamurthi, 
Emily Nelson, 
Hillel Wayne, 
Siddhartha Prasad,
...
and the many CSCI 1710 students and TAs at Brown who have kindly given their thoughts.

## AI Use 

Some manual labor involved in hosting and maintaining this book was performed with the help of generative AI, chiefly Claude Code. For example, migrating from `mdbook` to `mkdocs` and debugging various issues. **None of the text, images, or any other content was AI generated.** I think by writing, and this book is an extension of my lecture notes for CSCI 1710 at Brown. I don't dare delegate that thinking to AI.
