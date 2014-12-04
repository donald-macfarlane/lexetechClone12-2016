traversal (query) =
  if (query)
    {
      text = query.text
      query = query

      respond (text) =
        response = [
          r <- query.responses
          r.text == text
          r
        ].0

        if (@not response)
          throw (new (Error "no such response #(text), try one of #([r <- query.responses, r.text].join ', ')"))
        
        traversal (response.query)
    }

module.exports = traversal
