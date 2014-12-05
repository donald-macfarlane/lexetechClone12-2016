$ = require 'jquery'

exports.firstQuery()! =
  body = $.get '/queries/first/graph'!

  forEachQuery @(query) inQueryGraph (body.query)
    for each @(response) in (query.responses)
      response._query = response.query
      response.query()! =
        self._query

  body

forEachQuery inQueryGraph (query, block) =
  queries = [
     r <- query.responses
     r.query
     r.query
  ]

  block(query)

  [
    q <- queries
    forEachQuery inQueryGraph (q, block)
  ]
