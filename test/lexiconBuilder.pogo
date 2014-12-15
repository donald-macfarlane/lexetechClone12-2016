_ = require 'underscore'

module.exports () =
  queryId = 0
  responseId = 0

  buildQuery(q, blockId) =
    ++queryId
    query = _.extend {
      id = queryId
      level = 1
      block = blockId

      predicants = []
    } (q)

    query.responses = [r <- q.responses, buildResponse(r)]
    query

  buildResponse(r) =
    ++responseId

    _.extend {
      id = responseId
      setLevel = 1

      predicants = []

      action = {
        name = 'none'
        arguments = []
      }
    } (r)

  {
    lexicon(lexicon) = {
      blocks = [
        block <- lexicon.blocks
        {
          name = block.name
          id = block.id

          queries = [
            query <- block.queries
            buildQuery(query, block.id)
          ]
        }
      ]
    }

    blocks(blocks) = self.lexicon {blocks = blocks}
    queries(queries) = self.blocks [{id = 1, queries = queries}]
  }
