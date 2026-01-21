# D3FX Helpers

**This page is outdated, and will no longer work on versions of Forge after 2.7.0. If you're using an updated version of Forge, please see [the updated (and much improved) documentation](./d3fx_apr23.md).**

## The Stage and Visual Objects

The `Stage` object is the top-level container for every visual object that gets displayed. You can add further structure to your visual containment using other containers like grids or conjoined objects, but the stage must always be the top-level graphic organizer. You must make exactly one stage, and a stage cannot store other stages. 

Visual objects comprise all other objects to display using the helper library. These may be containers for other objects, or atomic objects like text boxes or shapes. You can add new visual objects to a `Stage` using the `.add` method. 

## Primitive Objects

### Textbox

Textboxes render text to the screen at a given location. To instantiate one, use:

```
new Textbox(<text>:string, <coords>:Coords, <color>:string, <textSize>:string)
```
where `Coords` is an object with `x` and `y` fields. 

```admonish example title="TextBox"
~~~
new TextBox('hello!', {x: 50, y: 50}, 'black', 12)
~~~
```

All parameters after `text` are optional, and can be edited afterwards with corresponding setter methods. 



###  Shapes

The following three objects (`Rectangle`, `Circle`, and `Polygon`) are all instances of `Shape`. In general, all `Shape` objects include the following properties, all of which have corresponding setters and are typically optional parameters in the construction of these shapes:
* `color: string` - This is the color of the interior of the shape.
* `borderWidth: number` - This is the width of the border around the exterior of the shape, in pixels. 
* `borderColor: string` - This is the color of the border of the shape. 
* `label: string` - This is text to be displayed on top of the shape. All shapes come with an internal `TextBox` object, which is rendered according to this text in the center of the shape. 
* `labelColor: string` - The color of the text that is displayed atop the shape. 
* `labelSize: number` - The size of the label’s font, in pixels. 

#### Rectangle

Rectangles work how one would expect them to. Along with the rest of the `Shape` variables, they also take in values of coordinates, height, and width. The coordinates will be in the typical form of the interface `{x:<x position>, y:<y position>}`. These coordinates will be the top left of the rectangle. The width and height parameters determine the size of the rectangle in the x and y direction, respectively.

#### Circle

Circles take in all the optional parameters associated with shapes, along with the additional parameters of `coords` and `radius`. The x and y values contained in the `coords` will determine the center of the circle, around which the `radius` will determine the rest. 

```
new Circle(
        radius: number,
        coords?: Coords,
        color?: string,
        borderWidth?: number,
        borderColor?: string,
        label?: string,
        labelColor?: string,
        labelSize?: number
    )
```

#### Polygon

Polygons are a bit more complicated, and serve as a very general tool. Along with the standard optional shape parameters, they also take in a `points` parameter. This is in the form of an array of coordinates. Each coordinate should be a point on the outside of the polygon, traversing the outside of the desired shape in order. 

~~~admonish example title="A simple triangle"
For example, a simple triangle could be rendered as follows:
```
let points = [
    {x: 100, y:100},
    {x:100, y:200},
    {x:200, y:100}
]

let poly = new Polygon(
    points, "red"
)
```
~~~

#### Line

`Line`s work similar to `Polygon`s, however without an interior. Their constructor takes in an array of coordinates called `points`, however these points will form a line, and will not reconnect at the end:

```
new Line(points: Coords[], color?: string, width?: number)
```

```admonish example title="Line"
~~~
new Line(points: [{x:50, y:50}, {x:100, y:100}], color: 'black', width: 5)
~~~
```

## Complex Objects

### Grids

A `Grid` provides a 2-dimensional array of cells that can store other visual objects. It is initialized by passing an object containing the following fields to its constructor:
* the location of the upper-left corner of the grid: `grid_location: {x: upper-left-x-coordinate, y: upper-left-y-coordinate}`;
* the size of each cell: `cell_size: {x_size: width-per-cell, y_size: height_per_cell}`; and 
* the number of rows and columns: `grid_dimensions: {x_size: number-of-columns, y_size: number-of-rows}`.

Add a visual object `obj` to a grid using its `.add` method:
* `grid.add({x:column-index,y:row-index},obj)`

```admonish example title="Cleaning Up the Array"
In the [custom viz basics](./custom-basics.md) chapter, we built a simple script that printed out the contents of an array (for a model that defined such). Let's create a grid that displays the array contents more readably. We'll get the contents of the array as before, but this time we'll create a new text box for every entry, and store each in the grid.

~~~
const stage = new Stage()
const theArray = instance.signature('IntArray').atoms()[0]
const elementsField = instance.field('elements')
const entries = theArray.join(elementsField)

const arrayGrid = new Grid({
    grid_location: {x: 50, y: 50},
    cell_size: {x_size: 80, y_size: 40},
    grid_dimensions: {x_size:1, y_size:10}})

entries.tuples().forEach( (entry,idx) => {
  arrayGrid.add({x: 0, y: idx}, 
           new TextBox(`${entry}`, {x:100, y:100},'black',16))
})

stage.add(arrayGrid)
stage.render(svg, document)
~~~
Note the call to `entries.tuples()`. The variable `entries` references a Forge expression---a piece of syntax that means something in the instance. To get that meaning into a list we can iterate over, we call the `tuples()` method.

There's one problem remaining: we are creating a grid that always has 10 rows in it, no matter how many entries there are in the array. To fix this, we'll use `entries.tuples().length` in the grid definition: `grid_dimensions: {x_size:1, y_size:entries.tuples().length}`. Now we'll see a grid without any extra rows.
```

```admonish todo title="Other container objects"
* graphs
* trees
  * edge objects with labels (new feature)
* conjoined objects
```
