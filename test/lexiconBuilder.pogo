_ = require 'underscore'

module.exports () =
  queryId = 0
  responseId = 0

  buildQuery(q) =
    ++queryId
    query = _.extend {
      id = String(queryId)
      level = 1

      predicants = []
    } (q)

    query.responses = [r <- q.responses @or [], buildResponse(r)]
    query

  buildResponse(r) =
    ++responseId

    _.extend {
      id = responseId
      setLevel = 1

      predicants = []

      actions = []
    } (r)

  {
    lexicon(lexicon) = {
      blocks = [
        block <- lexicon.blocks
        {
          name = block.name
          id = String(block.id)

          queries = [
            query <- block.queries @or []
            buildQuery(query)
          ]
        }
      ]
    }

    blocks(blocks) = self.lexicon {blocks = blocks}
    queries(queries) = self.blocks [{id = "1", queries = queries}]
  }
