_ = require 'underscore'

module.exports () =
  queryId = 0
  responseId = 0

  {
    query(q) =
      ++queryId
      _.extend {
        id = queryId
        level = 1
        block = 1

        predicants = []
      } (q)

    response(r) =
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
  }
