$ = require 'jquery'
cache = require '../common/cache'

module.exports(http = $) =
  blockCache = cache()

  block(n) =
    blockCache.cacheBy (n)
      http.get "/api/blocks/#(n)"!

  {
    block(blockId) = {
      query(n) =
        block(blockId)!.(n)

      length() =
        block(blockId)!.length
    }
  }
