_ = require 'underscore'

module.exports () =
  firstQuery = nil

  {
    query (query, context = nil) =
      q = createQuery {
        query = query @and {
          text = query.text
          responses = []
          hrefTemplate = queryHrefTemplate(query, context)
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

queryHrefTemplate(query, context) =
  "/api/queries/#(query.id)/graph?context=#(encodeURIComponent(JSON.stringify(_.pick(context, 'blocks', 'predicants', 'level')))){&depth}"

createQuery = prototype {
  addResponse (response) =
    r = {
      id = response.id
      text = response.text
      notes = response.notes

      queryHrefTemplate =
        if (response.repeating)
          self.query.hrefTemplate
    }

    self.query.responses.push (r)

    createResponse {
      parentQuery = self.query
      response = r
    }
}

createResponse = prototype {
  setQuery (query) =
    if (@not self.response.queryHrefTemplate)
      self.response.query = query.query

    delete (self.parentQuery.partial)

    query
}
