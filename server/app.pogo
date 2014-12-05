express = require 'express'
app = express()
buildGraph = require './buildGraph'
queryGraph = require './queryGraph'

app.get '/' @(req, res)
  res.send {}

handleErrors (res, block) =
  try
    block()!
  catch (e)
    res.status 500.send {error = e}

app.get '/queries/:id/graph' @(req, res)
    db = app.get 'db'
    graph = queryGraph()

    maxDepth = Math.min(10, req.param 'depth') @or 3

    startContext =
      if (req.param 'context')
        JSON.parse(req.param 'context')

    buildGraph!(db, graph, req.param 'id', startContext = startContext, maxDepth = maxDepth)
    res.send (graph.toJSON())

module.exports = app
