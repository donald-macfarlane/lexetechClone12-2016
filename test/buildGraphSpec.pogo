buildGraph = require '../buildGraph'
dotGraph = require '../dotGraph'

describe 'buildGraph'
  graphNumber = 1

  renderLexemes(lexemes) =
    graph = dotGraph()
    buildGraph(lexemes, graph)
    
    fs.writeFile ("graph#(graphNumber).dot")
    console.log(graph.toString())
    

  it 'builds a graph'
    lexemes = [
      {
        id = 1
        name = 'q one'
        predicants = []

        responses = [
          {
            id = 1
            response = 'r one'
            predicants = []

            action = {
              name = 'none'
              arguments = []
            }
          }
        ]
      }
    ]

    graph = dotGraph()
    buildGraph(lexemes, graph)
    
    console.log(graph.toString())
