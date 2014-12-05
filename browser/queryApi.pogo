$ = require 'jquery'

exports.firstQuery () ! =
  body = $.get('/queries/first/graph') ^!

  forEachQuery @(query) inQueryGraph (body.query)
    console.log(query)

  body

forEachQuery inQueryGraph (query, block) =
  block(query)

  [
    r <- query.responses
    r.query
    forEachQuery inQueryGraph (r.query, block)
  ]
