$ = require 'jquery'
cache = require '../common/cache'

module.exports(http = $) =
  blockQueriesCache = cache()

  blockQueries(n) =
    blockQueriesCache.cacheBy (n)
      http.get "/api/blocks/#(n)/queries"!

  {
    block(blockId) = {
      query(n) =
        blockQueries(blockId)!.(n)

      length() =
        blockQueries(blockId)!.length
    }
  }
