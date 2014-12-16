$ = require 'jquery'
_ = require 'underscore'
cache = require '../server/cache'
uritemplate = require 'uritemplate'
buildGraph = require '../server/buildGraph'

module.exports (http = $, db = db) = {
  firstQuery(depth = 4)! =
    query = buildGraph.buildGraph!(db, nil, startContext = nil, maxDepth = depth)
    query
}
