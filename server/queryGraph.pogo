_ = require 'underscore'

module.exports () =
  firstQuery = nil

  {
    query (query, context = nil) =
      q = createQuery {
        query = query @and {
          text = query.text
          responses = []
          hrefTemplate = "/queries/#(query.id)/graph?context=#(encodeURIComponent(JSON.stringify(_.pick(context, 'blocks', 'predicants', 'level')))){&depth}"
          partial = true
        }
      }

      if (@not firstQuery)
        firstQuery := q.query

      q

    toJSON () = {
      query = firstQuery
    }
  }

createQuery = prototype {
  addResponse (response) =
    r = {
      id = response.id
      text = response.text
      notes = response.notes
    }

    self.query.responses.push (r)

    createResponse {
      parentQuery = self.query
      response = r
    }
}

createResponse = prototype {
  setQuery (query) =
    self.response.query = query.query
    delete (self.parentQuery.partial)
    query
}
