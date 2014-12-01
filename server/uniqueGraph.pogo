module.exports(graph) =
  onceForEachResponseQuery = onceForEach()
  onceForEachQueryResponse = onceForEach()
  onceForEachResponse = onceForEach()
  onceForEachQuery = onceForEach()

  {
    response (response) toQuery (query) =
      queryId =
        if (query)
          query.id
        else
          'end'

      onceForEachResponseQuery "#(response.id):#(queryId)"
        graph.response (response) toQuery (query)

    query (query) toResponse (response) =
      onceForEachQueryResponse "#(response.id):#(query.id)"
        graph.query (query) toResponse (response)

    response (response) =
      onceForEachResponse(response.id)
        graph.response (response)

    query (query) =
      onceForEachQuery(query.id)
        graph.query (query)

    debug (comment) =
      graph.debug (comment)
  }

onceForEach() =
  hash = {}
  @(key, block)
    if (@not hash.(key))
      hash.(key) = true
      block()
