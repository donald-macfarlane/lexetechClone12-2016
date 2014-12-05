$ = require 'jquery'
_ = require 'underscore'

exports.firstQuery()! =
  body = $.get '/queries/first/graph'!

  forEachQuery @(query) inQueryGraph (body.query)
    if (query.partial)
      queryPromise = $.get(query.href)

      [
        responsePair <- _.zip(query.responses, [0..(query.responses.length - 1)])

        @{
          responsePair.0.query()! =
            q = queryPromise!
            q.query.responses.(responsePair.1).query
        }()
      ]
    else
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
