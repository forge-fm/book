# Custom Visualization Basics

As seen in the [Sterling Visualizer](../running-models/sterling-visualizer.md) section, Forge uses an adapted version of the [Sterling](https://sterling-js.github.io/) visualization tool. One of the advantages of using Sterling is that users can create their own custom visualization scripts.

## Script View and Modes

When viewing an instance in Sterling, there are three options for viewing an instance: Graph, Table, and Script. To swap to script-view mode, click on Script. Most of the screen will be taken up by 3 new panes:
* the visualization canvas (blank by default); 
* the script editor; and 
* a list of available variables that are available for scripts to use.

Where the "Next" button was in the graph visualizer, there will now be 4 more buttons: 
* Run executes the visualization script when clicked.
* `<div>`, `<canvas>` and `<svg>` swap between visualization modes. The default is `<svg>`. 
This documentation focuses on the `<svg>` mode, because that is where most of the library support is. 

```admonish example title="A Basic Script" 
Try entering some visualization code in the script window and clicking "Run":
~~~
const stage = new Stage()
stage.add(new TextBox({
  text: 'Hello!', 
  coords: {x:100, y:100},
  color: 'black',
  fontSize: 16
}))
stage.render(svg, document)
~~~
This will create a `TextBox` in the visualization area that says "Hello!". 
```

Custom scripts are written in JavaScript. JavaScript constructs like looping, mapping over lists, etc. are all available for your use.

```admonish warning title="JavaScript"
At the moment (February 2023), the script editor works only with "vanilla" JavaScript; Sterling will not run (e.g.) a TypeScript compiler on the code. Moreover, importing external libraries is somewhat restricted.
```

## Working with an Instance

Sterling uses a number of JavaScript classes to represent an instance. [The `alloy-ts` library documentation](https://alloy-js.github.io/alloy-ts/) describes these in more detail, but you should be aware of the following:

### The Instance

The `instance` variable provides access to the current instance. If temporal mode is active, `instance` will refer to the current state; to get the entire list of states, use `instances` instead (which is only available in temporal mode). 

### Accessing Sigs and Fields

You can use the `.signature(name)` method of an instance to obtain an object representing a `sig` in the instance. Likewise, `.field(name)` will yield an object representing a particular field. 

```admonish example title="A Basic Script" 
If you're viewing an instance of the [binary search model](https://csci1710.github.io/2023/livecode/feb15_feb17_binarysearch.frg) from class, you can run this script directly. (If you use this model, uncomment the `run` at the bottom of the file!)
~~~
const stage = new Stage()
stage.add(new TextBox({
  text: `${instance.signature('IntArray')}`, 
  coords: {x:100, y:100},
  color: 'black',
  fontSize: 16
}))
stage.render(svg, document)
~~~
This will create a `TextBox` in the visualization area whose text is a string representation of the `Int` sig in whatever instance you're viewing. The string won't be very useful yet; it will be something like "[IntArray]". Next, change `instance.signature('IntArray')` to `instance.signature('IntArray').atoms()[0]`---the first (and in this case, only) `IntArray` object in the instance. You'll see the sig name become an object id like `[IntArray0]`.   

All `IntArray` objects have an `elements` field. We can get access to the field and print its contents by _joining_ the object to its field:
~~~
const stage = new Stage()
const theArray = instance.signature('IntArray').atoms()[0]
const elementsField = instance.field('elements')
stage.add(new TextBox({
  text: `${theArray.join(elementsField)}`, 
  coords: {x:100, y:100},
  color: 'black',
  fontSize: 16}))
stage.render(svg, document)
~~~
This should display something like "1, 7 2, 7 3, 7 4, 7 5, 7 6, 7 7, 7". Again, not very useful. Sterling is printing the contents of the array in `index,value` form, but separating elements with space. We can fix this, though!
```

---

## Built-in Library Shapes 

Scripts in `<svg>` mode use the [D3 visualization library](https://d3-graph-gallery.com/graph/shape.html) by default. However, D3 can be fairly complex to use, and so various [built-in helpers](./d3fx.md) are also available. We encourage using the helper library, although in more advanced cases you may wish to use D3 directly.

---

## Potential Pitfalls and Debugging

Sterling presents a "full Forge" view of instances, and one that's closer to the way the solver works. All sigs and fields are represented as _sets_ in the instance. Each set contains `AlloyTuple` objects, which themselves contain lists of `AlloyAtom`s. Because (at the moment) there is no support for types in the script editor, it can sometimes be troublesome to remember which kind of datum you're working with. The `alloy-ts` docs below provide much more detail, but in brief:
* if the object has an `.atoms()` method, it's an `AlloyTuple`;
* if the object has an `.id()` method, it's an `AlloyAtom`; and
* signatures, fields, tuples, and atoms are all `AlloySets` and provide a `.tuples()` method.

In order to do a Froglet-style field access, you should use the `.join` method. (E.g., in the example above, we wrote `theArray.join(elementsField)` rather than `theArray.elementsField` or `theArray.elements`.)

We suggest using `TextBox`es to visualize debugging information. As a fallback, you can also use `console.log(...)` as normally in JavaScript, but the web-developer console in Sterling can be somewhat congested. Printing raw `AlloySet` objects via `console.log` will also not be immediately useful, since Sterling uses a proxy to manage the difference between the set as _Forge syntax_ and the set as _a value in the instance_.

---

## Further Resources and Examples

Further chapters:
* [Visualization Helper Library](./d3fx_apr23.md) describes helpers (e.g., text boxes, grids, etc.) for visualization that don't require D3 knowledge.
* [Working with SVG and Imports](./svg-tips.md) explains how to (e.g.) increase the size of the rendering area.

External resources:
* [What is the SVG format?](https://www.w3schools.com/graphics/svg_intro.asp)
* [D3FX helpers design documentation](https://docs.google.com/document/d/10pqJuWVp6ap-6JoEE5nDqrCKFpYcuzN81oItnYO3yS4/edit#heading=h.4p6wkcmc113e)---**beware, this is actively being worked on and edited, and thus subject to change!**

Examples using D3:
* [Mia Santomauro's 2021 Guide](https://github.com/miasantomauro/lets-get-visual) for custom visualization in Forge is still useful, but was made before most of the helper functions and classes above existed. If you're interested in using D3 directly with Sterling, it's a great starting point.
* Tim's 2022 visualizer script examples also use D3 directly, rather than leveraging helpers, but may also be a useful reference:
  * [Sudoku Synthesizer](https://github.com/csci1710/public-examples/tree/main/2022/sudoku_opt_viz)
  * [Queue](https://github.com/csci1710/public-examples/tree/main/2022/queue)
  * [Lights Puzzle (temporal mode)](https://github.com/csci1710/public-examples/tree/main/2022/lights_puzzle) 
* Tim and Mia also wrote a ["visualizer" that plays musical scales](https://github.com/miasantomauro/mia-isp-spring-2021/tree/main/musical%20scales) generated by a model Tim wrote to understand music a bit better.

```admonish thanks title="Collaborators"
Work on custom visualization in Sterling is an ongoing collaborative effort. We are grateful to Tristan Dyer for working to expand Sterling for Forge. We are also grateful for contributions from (in alphabetic order):
* Ethan Bove
* Sidney LeVine
* Mia Santomauro
```