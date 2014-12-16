_ = require 'underscore'

module.exports (buildGraph) =
  createResponse = prototype {
    query() =
      buildGraph.nextQueryForResponse(self.response, self.context)!
  }

  {
    query (query, context) =
      if (query)
        {
          query = query
          context = context
          responses = [
            r <- query.responses
            createResponse {
              context = context
              response = r
            }
          ]
        }
  }
