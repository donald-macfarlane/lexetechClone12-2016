$ = require 'jquery'
_ = require 'underscore'
cache = require '../server/cache'
uritemplate = require 'uritemplate'

exports.firstQuery(depth = 4)! =
  firstTemplate = uritemplate.parse "/queries/first/graph{?depth}"
  body = $.get (firstTemplate.expand {depth = depth})!

  queryAjaxCache = cache()

  forEachQuery @(query) inQueryGraph (body.query)
    if (query.partial)
      queryPromise = queryAjaxCache.cacheBy (query.hrefTemplate)
        template = uritemplate.parse(query.hrefTemplate)
        $.get(template.expand {depth = depth})

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
