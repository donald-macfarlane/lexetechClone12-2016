redis = require 'redis'
urlUtils = require 'url'
cache = require './cache'

createClient(url) =
  if (url)
    redisURL = urlUtils.parse(url)
    client = redis.createClient(redisURL.port, redisURL.hostname, {no_ready_check = true})
    client.auth(redisURL.auth.split(':').(1))
    client
  else
    redis.createClient()

module.exports () =
  client = createClient(process.env.REDISCLOUD_URL)
  blockCache = cache()

  queryById(id) =
    JSON.parse(client.get("query_#(id)", ^)!)

  block(n) =
    blockCache.cacheBy (n)
      client.lrange ("block_#(n)", 0, -1, ^)!

  {
    clear() =
      client.flushdb(^)!

    setLexicon(lexicon) =
      self.clear()!

      writeBlock(block) =
        promise! @(result, error)
          client.mset.apply (client) [[q <- block.queries, i <- ["query_#(q.id)", JSON.stringify(q)], i], ..., @(er, re)
            if (er)
              error(er)
            else
              result(re)
          ]

        promise! @(result, error)
          client.rpush.apply (client) ["block_#(block.id)", [q <- block.queries, q.id], ...,  @(er, re)
            if (er)
              error(er)
            else
              result(re)
          ]

      [
        block <- lexicon.blocks
        writeBlock(block)!
      ]

      blockCache.clear()

    queryById(id) = queryById(id)

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
