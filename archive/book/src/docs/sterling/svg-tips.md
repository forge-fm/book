# Working with SVG

## Expanding the SVG Region

If the default `svg` area is not the right size for your needs, you can change its dimensions. 

The `<svg>` element that scripts render to is contained within an element called `svg-container`, whose only child is the render area. Thus, the render area can be obtained with:
```
const renderArea = document.getElementById('svg-container').getElementsByTagName('svg')[0]
```
You can then set the `style.width` and `style.height` attributes of the rendering area. 

~~~admonish example title="Changing the rendering area size"
This code changes the available space in the `<svg>` element, giving us 5 times the original vertical space to work with: 
```
const svgContainer = document.getElementById('svg-container')
svgContainer.getElementsByTagName('svg')[0].style.height = '500%'
svgContainer.getElementsByTagName('svg')[0].style.width = '100%'
```
~~~

~~~admonish warning title="Resizing in the script"
If you're using the helper library, you may need to resize _after_ calling `stage.render`. 
~~~

### Alternative Method

You also have access to set the [`viewBox` attribute](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/viewBox) of the `<svg>` region. However, we don't suggest making this specific kind of low-level change if you're working only with D3FX.

~~~admonish example title="1000 by 1000 viewbox"
```
require('d3')
d3.select(svg).attr("viewBox", "0 0 1000 1000")
```
~~~

## Importing modules

Sterling uses the [`d3-require`](https://github.com/d3/d3-require) and [jsdelivr](https://www.jsdelivr.com/) systems to import external libraries. These should be given in the first lines of the script (before any comments!) and be enclosed in a single `require` form per library. E.g., to import the `d3-array` and `d3-format` libraries:
```
require("d3-array")
require("d3-format")
```
