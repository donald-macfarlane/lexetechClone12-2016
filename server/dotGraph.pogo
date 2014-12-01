uniqueGraph = require './uniqueGraph'

module.exports(stdout = false) =
  statements = []

  generate =
    if (stdout)
      @(s)
        console.log(s)
    else
      @(s)
        statements.push(s)

  graph = uniqueGraph {
    response (response) toQuery (query) =
      queryId =
        if (query)
          query.id
        else
          'end'

      generate "  response_#(response.id) -> query_#(queryId)"

    query (query) toResponse (response) =
      generate "  query_#(query.id) -> response_#(response.id)"

    response (response) =
      generate "  response_#(response.id) [label=#(JSON.stringify(response.response))]"

    query (query) =
      generate "  query_#(query.id) [label=#(JSON.stringify(query.name))]"

    debug (comment) =
      generate "  /* #(comment) */"
  }

  graph.toString() =
    "digraph {
     #(statements.join "\n")
     }"

  graph
