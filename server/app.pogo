express = require 'express'
morgan = require 'morgan'
bodyParser = require 'body-parser'

app = express()
app.use(morgan('combined'))
app.use(bodyParser.json {limit = '1mb'})

buildGraph = require './buildGraph'
queryGraph = require './queryGraph'

app.post '/queries' @(req, res)
  db = app.get 'db'
  db.setQueries(req.body)!
  res.status(201).send({ status = 'success' })

app.get '/queries/first/graph' @(req, res)
  loadGraph(nil, req, res)

app.get '/queries/:id/graph' @(req, res)
  loadGraph(req.param 'id', req, res)

loadGraph (queryId, req, res) =
  db = app.get 'db'
  graph = queryGraph()

  maxDepth = Math.min(10, req.param 'depth') @or 3

  startContext =
    if (req.param 'context')
      JSON.parse(req.param 'context')

  buildGraph!(db, graph, queryId, startContext = startContext, maxDepth = maxDepth)
  res.send (graph.toJSON())

app.use(express.static(__dirname + '/public'))

module.exports = app
