buildGraph = require '../server/buildGraph'
dotGraph = require '../server/dotGraph'
fs = require 'fs-promise'
childProcess = require 'child_process'
handlebars = require 'handlebars'
internalGraph = require '../server/internalGraph'
multiGraph = require '../server/multiGraph'
expect = require 'chai'.expect
lexiconBuilder = require './lexiconBuilder'

describe 'buildGraph'
  graphs = []
  lexicon = nil

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

  beforeEach
    lexicon := lexiconBuilder()

  it 'builds a graph'
    queries = renderLexemes! [
      lexicon.query {
        name = 'q1'

        responses = [
          lexicon.response {
            response = 'q1 r1'
            predicants = ['x']
          }
          lexicon.response {
            response = 'q1 r2'
            predicants = ['y']
          }
        ]
      }
      lexicon.query {
        name = 'q2'

        responses = [
          lexicon.response {
            response = 'q2 r1'
          }
        ]
      }
      lexicon.query {
        name = 'q3'

        responses = [
          lexicon.response {
            response = 'q3 r1'
          }
        ]
      }
      lexicon.query {
        name = 'q4'
        predicants = ['x']

        responses = [
          lexicon.response {
            response = 'q4 r1'
          }
        ]
      }
      lexicon.query {
        name = 'q5'

        responses = [
          lexicon.response {
            response = 'q5 r1'
          }
        ]
      }
      lexicon.query {
        name = 'q6'

        responses = [
          lexicon.response {
            response = 'q6 r1'
          }
        ]
      }
    ]

    q3 = queries.2
    expect(q3.name).to.eql 'q3'
    expect(q3.responses.0.queries).to.eql [4, 5]
