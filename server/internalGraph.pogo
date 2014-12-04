uniqueGraph = require './uniqueGraph'
_ = require 'underscore'
cache = require './cache'

module.exports () =
  queries = []
  queryCache = cache()
  responseCache = cache()

  findOrCreateResponse (response, context) =
    responseCache.cacheBy "#(response.id):#(context.key())"
      {
        id = response.id
        predicants = response.predicants
        text = response.response
        nextQuery = nil
      }

  findOrCreateQuery (query, context) =
    queryCache.cacheBy "#(query.id):#(context.key())"
      q = {
        id = queries.length + 1
        text = query.name
        predicants = query.predicants
        responses = []
      }

      queries.push (q)
      q

  {
    response (response) toQuery (query, responseContext = nil) =
      r = findOrCreateResponse (response, responseContext)
      nextQuery = query @and findOrCreateQuery(query, responseContext)
      r.nextQuery = nextQuery @and nextQuery.id

    query (query) toResponse (response, parentQueryContext = nil, responseContext = nil) =
      q = findOrCreateQuery (query, parentQueryContext)
      r = findOrCreateResponse (response, responseContext)
      q.responses.push(r)

    response (response, context = nil) = nil
    query (query, context = nil) = nil

    debug (comment) =
      console.log (comment)

    toJSON () = {
        firstQuery = queries.0.id
        queries = _.indexBy(queries, 'id')
      }
  }
