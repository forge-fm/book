require('d3')
d3.selectAll("svg > *").remove();

function printValue(row, col, yoffset, value) {
  d3.select(svg)
    .append("text")
    .style("fill", "black")
    .attr("x", row*10)
    .attr("y", col*16 + yoffset)
    .text(value);
}

function findAtom(v) {
  switch(v) {
    case 1: return A; 
    case 2: return B; 
    default: return C; 
  }
}

function printBoard(boardAtom, yoffset) {
  for (r = 1; r <= 3; r++) {
    for (c = 1; c <= 3; c++) {
      printValue(r, c, yoffset,
                 boardAtom.places[findAtom(r)][findAtom(c)]
                 .toString().substring(0,1))  
    }
  }
  
  d3.select(svg)
    .append('rect')
    .attr('x', 5)
    .attr('y', yoffset+2)
    .attr('width', 40)
    .attr('height', 50)
    .attr('stroke-width', 2)
    .attr('stroke', 'black')
    .attr('fill', 'transparent');
}

var offset = 0
for(b = 0; b <= 9; b++) {  
  if(Board.atom("Board"+b) != null)
    printBoard(Board.atom("Board"+b), offset)  
  offset = offset + 60
}