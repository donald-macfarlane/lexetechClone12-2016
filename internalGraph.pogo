uniqueGraph = require './uniqueGraph'
_ = require 'underscore'

module.exports () =
  queries = []
  responses = {}

  findOrCreateResponse (response) =
    r = responses.(response.id)

    if (r)
      r
    else
      responses.(response.id) = {
        id = response.id
        predicants = response.predicants
        response = response.response
        queries = []
      }

  graph = uniqueGraph {
    response (response) toQuery (query) =
      r = findOrCreateResponse (response)
      r.queries.push((query @and query.id) @or 'end')

    query (query) toResponse (response) = nil

    response (response) = nil

    query (query) =
      queries.push {
        id = query.id
        name = query.name
        predicants = query.predicants
        responses = [
          r <- query.responses
          findOrCreateResponse (r)
        ]
      }

    debug (comment) =
      console.log (comment)
  }

  graph.toJSON () = queries

  graph
