$ = require 'jquery'
cache = require '../common/cache'

module.exports(http = $) =
  blockCache = cache()
  queryCache = cache()

  block(n) =
    blockCache.cacheBy (n)
      http.get "/api/blocks/#(n)"!

  queryById(id) =
    queryCache.cacheBy (id)
      http.get "/api/queries/#(id)"!

  {
    block(blockId) = {
      query(n) =
        queryId = block(blockId)!.(n)
        queryById(queryId)!

      length() =
        block(blockId)!.length

      coherenceIndexForQueryId(id) =
        index = block(blockId)!.indexOf(id)

        if (index < 0)
          throw (new (Error "no such query id #(JSON.stringify(id)) in block #(blockId)"))

        index
    }
  }
