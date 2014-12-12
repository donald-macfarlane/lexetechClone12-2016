$ = require 'jquery'
_ = require 'underscore'
cache = require '../server/cache'
uritemplate = require 'uritemplate'

module.exports (http = $) = {
  firstQuery(depth = 4)! =
    firstTemplate = uritemplate.parse "/api/queries/first/graph{?depth}"
    body = http.get (firstTemplate.expand {depth = depth})!

    queryAjaxCache = cache()

    queryAjaxCache.cacheBy (body.query.hrefTemplate)
      body.query

    getQuery(hrefTemplate) =
      queryAjaxCache.cacheBy (hrefTemplate)
        template = uritemplate.parse(hrefTemplate)
        http.get(template.expand {depth = depth})

    prepareQuery(topLevelQuery) =
      forEachQuery @(query) inQueryGraph (topLevelQuery)
        if (query.partial)

          [
            responsePair <- _.zip(query.responses, [0..(query.responses.length - 1)])

            @{
              responsePair.0.query()! =
                q = getQuery(query.hrefTemplate)!
                responseQuery = q.query.responses.(responsePair.1).query
                if (responseQuery)
                  prepareQuery(responseQuery)
            }()
          ]
        else
          for each @(response) in (query.responses)
            if (response.query)
              response._query = response.query
              response.query()! =
                self._query
            else if (response.queryHrefTemplate)
              response.query()! = getQuery(self.queryHrefTemplate)!
            else
              response.query()! = nil

      topLevelQuery
              
    prepareQuery(body.query)

    body.query
}

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
