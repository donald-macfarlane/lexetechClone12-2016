traversal (graph, query) =
  if (query)
    {
      text = query.text

      respond (text) =
        response = [
          r <- query.responses
          r.text == text
          r
        ].0

        if (@not response)
          throw (new (Error "no such response #(text), try one of #([r <- query.responses, r.text].join ', ')"))

        traversal (
          graph
          graph.queries.(response.nextQuery)
        )
    }
  else
    firstQuery = graph.firstQuery @and graph.queries.(graph.firstQuery)
    if (firstQuery)
      traversal (graph, firstQuery)
    else
      throw (new (Error "graph with no first query"))

module.exports = traversal
