uniqueGraph = require './uniqueGraph'
_ = require 'underscore'
cache = require './cache'

module.exports () =
  queries = []
  queryCache = cache()
  responseCache = cache()
  firstQuery = nil

  findOrCreateResponse (response, context) =
    responseCache.cacheBy "#(response.id):#(context.key())"
      {
        id = response.id
        text = response.response
        query = nil
      }

  findOrCreateQuery (query, context) =
    q = queryCache.cacheBy "#(query.id):#(context.key())"
      {
        id = queries.length + 1
        text = query.name
        responses = []
        href = "/queries/#(query.id)/graph?context=#(encodeURIComponent(JSON.stringify(_.pick(context, 'blocks', 'predicants', 'level'))))&depth=2"
      }

    if (@not firstQuery)
      firstQuery := q
    
    q

  {
    response (response) toQuery (query, responseContext = nil) =
      r = findOrCreateResponse (response, responseContext)
      delete (r.parentQuery.partial)
      nextQuery = query @and findOrCreateQuery(query, responseContext)
      r.query = nextQuery

    query (query) toResponse (response, parentQueryContext = nil, responseContext = nil) =
      q = findOrCreateQuery (query, parentQueryContext)
      q.partial = true
      r = findOrCreateResponse (response, responseContext)
      Object.defineProperty(r, 'parentQuery', { enumerable = false, value = q })
      q.responses.push(r)

    response (response, context = nil) = nil
    query (query, context = nil) = nil

    debug (comment) =
      console.log (comment)

    toJSON () = {
      query = firstQuery
    }
  }
