// Create the stage object to contain our scene
const stage = new Stage()
// Give ourselves enough vertical space. If visualization gets 
// truncated, change this! You can also adjust style.width.
document.getElementById('svg-container').style.height = '1100%'

/////////////////////////////////////////////////////////////////////
// Handle all states
/////////////////////////////////////////////////////////////////////

// Create a grid object that contains one cell per state
//    `instances` is an array that contains the states
const stateGridConfig = {
    grid_location :{
        x:10,
        y:10
    },
    cell_size:{
        x_size:400,
        y_size:300
    },
    grid_dimensions:{
        y_size: instances.length,
        x_size:2
    }
  }

const statesGrid = new Grid(stateGridConfig)

// For every instance, place a visualization in the proper grid location
instances.forEach( (inst, idx) => {    
    const lb = idx == loopBack ? " (loopback)" : ""
    statesGrid.add({x:0, y:idx}, new TextBox({text:`State:${idx}${lb}`,coords:{x:0,y:0},color:'black',fontSize:16}))
    statesGrid.add({x:1, y:idx}, visualizeStateAsText(inst, idx))    
})

/////////////////////////////////////////////////////////////////////
// Handle each individual state
/////////////////////////////////////////////////////////////////////

function visualizeStateAsText(inst, idx) {
    // The set of smiths present in this instance (which should, technically, never change)
    const theseServers = inst.signature('Server').atoms()

    const group = new Grid({
        grid_location :{
            x:10,
            y:10
        },
        cell_size:{
            x_size:120,
            y_size:40
        },
        grid_dimensions:{
            y_size: theseServers.length,
            x_size:3
        }
      })

    theseServers.forEach( (serv, serverIdx) => { 
        const roleStr = serv.join(inst.field('role'))
        const votedStr = serv.join(inst.field('votedFor'))
        group.add({x:0, y:serverIdx}, new TextBox({text:`${serv.id()}`,coords:{x:0,y:0},color:'black',fontSize:16}))
        group.add({x:1, y:serverIdx}, new TextBox({text:`role:${roleStr}`,coords:{x:0,y:0},color:'black',fontSize:16}))
        group.add({x:2, y:serverIdx}, new TextBox({text:`voted:${votedStr}`,coords:{x:0,y:0},color:'black',fontSize:16}))
    })    
    
    return group
}


// Finally, add the grid to the stage and render it:
stage.add(statesGrid)
stage.render(svg, document)