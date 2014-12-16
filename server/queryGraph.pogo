_ = require 'underscore'
buildGraph = require './buildGraph'

module.exports () =
  {
    query (query, context = nil, db = db) =
      createQuery {
        query = query
        context = context
        partial = true
        responses = []
        db = db
      }
  }

createQuery = prototype {
  addResponse (response) =
    r = createResponse {
      parentQuery = self
      response = response
    }

    self.responses.push (r)

    r

  rebuild() =
    if (self._rebuilt)
      self._rebuilt
    else
      self._rebuilt = buildGraph.buildQueryGraph(self.db, self.query, self.context, 4)
}

createResponse = prototype {
  setQuery (query) =
    self._query = query
    delete (self.parentQuery.partial)
    query

  query() =
    if (@not self._query)
      rebuiltQuery = self.parentQuery.rebuild()!
      rebuiltResponse = [r <- rebuiltQuery.responses, r.response.id == self.response.id, r].0
      self._query = rebuiltResponse._query

    if (self._query.query)
      self._query
}
