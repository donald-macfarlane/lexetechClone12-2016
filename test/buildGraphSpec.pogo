buildGraph = require '../buildGraph'
dotGraph = require '../dotGraph'
fs = require 'fs-promise'
childProcess = require 'child_process'
handlebars = require 'handlebars'
_ = require 'underscore'
internalGraph = require '../internalGraph'
multiGraph = require '../multiGraph'
expect = require 'chai'.expect

describe 'buildGraph'
  graphs = []

  renderLexemes(lexemes) =
    dot = dotGraph()
    graph = internalGraph()
    buildGraph(lexemes, multiGraph(dot, graph))

    image = "graph#(graphs.length + 1).png"

    promise! @(result, error)
      dotProcess = childProcess.spawn('dot', ['-Tpng', "-o#(image)"], stdio = 'pipe')
      
      dotProcess.stdin.write(dot.toString(), 'utf-8', ^)!
      dotProcess.stdin.end()

      dotProcess.on 'close' (result)
      dotProcess.on 'error' (error)

    graphs.push {
      image = image
      lexemes = JSON.stringify(lexemes, nil, 2)
    }

    graph.toJSON()

  after
    html = handlebars.compile \
     '<html>
        <body>
          {{#graphs}}
            <img src="{{image}}" />
            <code><pre>{{lexemes}}</pre></code>
          {{/graphs}}
        </body>
      </html>'

    fs.writeFile('graphs.html', html(graphs = graphs))!

  queryId = 0

  query(q) =
    ++queryId
    _.extend {
      id = queryId
      level = 1
      block = 1

      predicants = []
    } (q)

  responseId = 0

  response(r) =
    ++responseId

    _.extend {
      id = responseId
      setLevel = 1

      predicants = []

      action = {
        name = 'none'
        arguments = []
      }
    } (r)

  it 'builds a graph'
    queries = renderLexemes! [
      query {
        name = 'q1'

        responses = [
          response {
            response = 'q1 r1'
            predicants = ['x']
          }
          response {
            response = 'q1 r2'
            predicants = ['y']
          }
        ]
      }
      query {
        name = 'q2'

        responses = [
          response {
            response = 'q2 r1'
          }
        ]
      }
      query {
        name = 'q3'

        responses = [
          response {
            response = 'q3 r1'
          }
        ]
      }
      query {
        name = 'q4'
        predicants = ['x']

        responses = [
          response {
            response = 'q4 r1'
          }
        ]
      }
      query {
        name = 'q5'

        responses = [
          response {
            response = 'q5 r1'
          }
        ]
      }
      query {
        name = 'q6'

        responses = [
          response {
            response = 'q6 r1'
          }
        ]
      }
    ]

    q3 = queries.2
    expect(q3.name).to.eql 'q3'
    expect(q3.responses.0.queries).to.eql [4, 5]
