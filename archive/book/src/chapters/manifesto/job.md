
## Our Value Proposition

Everybody has endless demands on their time. If you're a student, you might be deciding which classes to take. There's never enough time to take them all, so you need to prioritize based on expected value. If you're a professional, you're deciding how to best use your limited "free" time to learn new skills and stay current. Either way, you're probably wondering: **What good is this book?** (And if you aren't asking that, you ought to be.)

You need many different skills for a successful career. This book won't teach you how to work with other people, or manage your tasks, or give and receive feedback. It won't teach you to program either; there are plenty of other books for that. Instead, this book will teach you:
* how to think more richly about what matters about a system; 
* how to better express what you want from it;
* how to more thoroughly evaluate what a system actually does give you; and
* how to use constraints and constraint solvers in your work (because we'll use them as tools to help us out).
It will also give you a set of baseline skills that will aid you in using any further formal-methods techniques you might encounter in your work, such as [advanced type systems](https://rust-book.cs.brown.edu), [program verification](https://dafny.org), [theorem proving](https://lean-lang.org), and more. 

### Modeling: What really matters?

There's a useful maxim by George Box: **"All models are wrong, but some are useful"**. The only completely accurate model of a system is that system itself, including all of its real external context. This is impractical; instead, a modeler needs to make choices about what really matters to them: what do you keep, and what do you disregard? Done well, a model gets at the essence of a system. Done poorly, a model yields nothing useful or, worse, gives a false sense of security. 

~~~admonish note title="George Box (1978)"
I suspect that people were saying "All models are wrong" long before Box did! But it's worth reading [this quote of his from 1978](https://doi.org/10.1016%2FB978-0-12-438150-6.50018-2), and thinking about the implications.

> Now it would be very remarkable if any system existing in the real world could be exactly represented by any simple model. However, cunningly chosen parsimonious models often do provide remarkably useful approximations. For example, the law $PV = nRT$ relating pressure $P$, volume $V$ and temperature $T$ of an "ideal" gas via a constant $R$ is not exactly true for any real gas, but it frequently provides a useful approximation and furthermore its structure is informative since it springs from a physical view of the behavior of gas molecules. For such a model there is no need to ask the question "Is the model true?". If "truth" is to be the "whole truth" the answer must be "No". **The only question of interest is "Is the model illuminating and useful?".** 

(Bolding mine. The text is taken from pages 2 through 3 of the original paper.) 
~~~

<!-- https://archive.org/details/DTIC_ADA070213/page/n7/mode/2up -->

If you want to do software (or hardware) engineering, some amount of modeling is unavoidable. Here are two basic examples of many.

#### Data Models Everywhere

You might already have benefitted from a good model (or suffered from a poor one) in your programming work. Whenever you write data definitions or class declarations in a program, [you're modeling](https://en.wikipedia.org/wiki/Data_model). The ground truth of the data is rarely identical to its representation. You decide on a particular way that it should be stored, transformed, and accessed. You say how one piece of data relates to another. 

Your data-modeling choices affect more than just execution speed: if a pizza order can't have a delivery address that is separate from the user's billing address, important user needs will be neglected. On the other hand, it is probably OK to leave the choice of cardboard box out of the user-facing order. An order has a delivery time, which probably comes with a time zone. You could model the time zone as an integer offset from UTC, but this is a [very bad idea](https://en.wikipedia.org/wiki/Time_zone). And, since there are 24 hours in a day, the real world imposes range limits: a timezone that's a million hours ahead of UTC is probably a buggy value, even though the value `1000000` is much smaller than even a signed 32-bit `int` can represent. 

#### Data vs. Its Representation 

The _level_ of abstraction matters, too. Suppose that your app scans handwritten orders. Then handwriting becomes pixels, which are converted into an instance of your data model, which is implemented as bytes, which are stored in hardware flip-flops and so on. You probably don't need, or want, to keep all those perspectives in mind simultaneously. Languages are valuable in part because of the abstractions they foster, even if those abstractions are incomplete&mdash;they can be usefully incomplete! What matters is whether the abstraction level suits your needs, and your users'.  

~~~admonish tip title="Memory Management" 
I learned to program in the 1990s, when practitioners were at odds over automated vs. manual memory management. It was often claimed that a programmer needed to _really understand_ what was happening at the hardware level, and manually control memory allocation and deallocation for the sake of performance. Most of us don't think that anymore, _unless we need to_! Sometimes we do; often we don't. Focus your attention on what matters for the task at hand. 
~~~

The examples don't stop: In security, a _threat model_ says what powers an attacker has. In robotics and AI, reinforcement learning works over a probabilistic model of real space. And so on. The key is: **what matters for your needs?** Box had something to say about that, too ([in 1976](http://www-sop.inria.fr/members/Ian.Jermyn/philosophy/writings/Boxonmaths.pdf)):

> Since all models are wrong the scientist must be alert to what is importantly wrong. It is inappropriate to be concerned about safety from mice when there are tigers abroad.  

### Specification: What do you want?

Suppose that I want to store date-and-time values in a computer program. That's easy enough to say, right? But the devil is in the details: What is the layout of the data? Which fields will be stored, and which will be omitted? Which values are valid, and which are out of bounds? Is the format efficiently serializable? How far backward in time should the format extend, and [how far into the future should it reach](https://en.wikipedia.org/wiki/Year_2000_problem)?

And which calendar are we using, anyway? 

~~~admonish note title="Yes, that's a real question."
If our programs are meant to work with dates prior to the 1600's, only their historical context can say whether they should be interpreted with the [Gregorian calendar](https://en.wikipedia.org/wiki/Gregorian_calendar) or the [Julian calendar](https://en.wikipedia.org/wiki/Julian_calendar). And that's just two (Eurocentric) possibilities!
~~~

If you're just building a food delivery app, you probably only need to think about some of these aspects of dates and times. If you're defining [an international standard](https://en.wikipedia.org/wiki/ISO_8601), you need to think about them all.

Either way, being able to think carefully about your specification can separate quiet success from famous failure.

### Validation and Verification: Did you get what you wanted?

Whether you're working out an algorithm on paper or checking a finished implementation, you need some means of judging correctness. Here, too, precision (and a little bit of adversarial thinking) matters in industry:
  * When ordinary testing isn't good enough, techniques like fuzzing, [property-based testing](../properties/pbt.md), and others give you new evaluative power. 
  * When you're updating, refactoring, or optimizing a system, a model of its ideal behavior can be leveraged for validation. [Here's an example from 2014](https://news.ycombinator.com/item?id=34726919)&mdash;click through the header of the linked article to read the original blog post.)
  * A model of the system's behavior is also useful for test-case generation, and [enable tools to generate test suites](https://hypothesis.readthedocs.io/en/latest/stateful.html) that have a higher coverage of the potential state space. 

And all that's even before we consider more heavyweight methods, like model checking and program verification.

### Formalism Isn't Absolute

The word "formal" has accumulated some unfortunate connotations: pedantry, stuffiness, ivory-tower snootiness, being an [architecture astronaut](https://en.wikipedia.org/wiki/Architecture_astronaut), etc. The truth is that formalism is a sliding scale. *We can take what we need and leave the rest.* What really matters is the ability to precisely express your goals, and the ability to take advantage of that precision. 

In fact, formalism powers many _software tools_ that help us to reason about the systems we create. In the next section, we'll start sketching what that means for us as engineers and humans.

<!-- You might not be used to thinking of programming as a "formal" activity, but it is. A programming language is a formal artifact: it has a precise meaning, usually defined in a detailed specification that few people need to read fully. Some factors are often left unspecified, and thus "implementation dependent", which is one reason why the difference between specification and implementation is more fluid than you might think.  -->




