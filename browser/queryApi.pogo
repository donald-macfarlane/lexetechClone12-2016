$ = require 'jquery'
_ = require 'underscore'
cache = require '../server/cache'
uritemplate = require 'uritemplate'

exports.firstQuery(depth = 4)! =
  firstTemplate = uritemplate.parse "/queries/first/graph{?depth}"
  body = $.get (firstTemplate.expand {depth = depth})!

  queryAjaxCache = cache()

  queryAjaxCache.cacheBy (body.query.hrefTemplate)
    body.query

  getQuery(hrefTemplate) =
    queryAjaxCache.cacheBy (hrefTemplate)
      template = uritemplate.parse(hrefTemplate)
      $.get(template.expand {depth = depth})

  forEachQuery @(query) inQueryGraph (body.query)
    if (query.partial)
      queryPromise = getQuery(query.hrefTemplate)

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
        if (response.query)
          response._query = response.query
          response.query()! =
            self._query
        else
          response.query()! = getQuery(self.queryHrefTemplate)!
            

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
