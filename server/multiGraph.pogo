module.exports (graphs, ...) = {
  response (response) toQuery (query) =
    [g <- graphs, g.response (response) toQuery (query)]

  query (query) toResponse (response) =
    [g <- graphs, g.query (query) toResponse (response)]

  response (response) =
    [g <- graphs, g.response (response)]

  query (query) =
    [g <- graphs, g.query (query)]

  debug (comment) =
    [g <- graphs, g.debug (comment)]
}
