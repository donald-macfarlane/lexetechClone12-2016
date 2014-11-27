module.exports() =
  statements = []

  {
    response (response) toQuery (query) =
      statements.push "  response_#(response.id) -> query_#(query.id)"

    query (query) toResponse (response) =
      statements.push "  query_#(query.id) -> response_#(response.id)"

    response (response) =
      statements.push "  response_#(response.id) [label=#(JSON.stringify(response.response))]"

    query (query) =
      statements.push "  query_#(query.id) [label=#(JSON.stringify(query.name))]"

    debug (comment) =
      statements.push "  /* #(comment) */"

    toString() =
      "digraph {
       #(statements.join "\n")
       }"
  }
