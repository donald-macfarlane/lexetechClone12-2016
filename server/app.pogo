express = require 'express'
app = express()
buildGraph = require './buildGraph'
internalGraph = require './internalGraph'

app.get '/' @(req, res)
  res.send {}

app.get '/query/:id/graph' @(req, res)
  db = app.get 'db'
  graph = internalGraph()

  maxDepth = Math.min(10, req.param 'depth') @or 3

  buildGraph!(db, graph, maxDepth = maxDepth)
  res.send (graph.toJSON())

module.exports = app
