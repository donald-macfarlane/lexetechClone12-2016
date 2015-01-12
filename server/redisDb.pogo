redis = require 'then-redis'
urlUtils = require 'url'
cache = require '../common/cache'
_ = require 'underscore'
bluebird = require 'bluebird'

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
    JSON.parse(client.get("query_#(id)")!)

  block(n) =
    blockCache.cacheBy (n)
      client.lrange("block_#(n)_queries", 0, -1)!

  {
    clear() =
      client.flushdb()!

    setLexicon(lexicon) =
      self.clear()!

      writeBlock(block) =
        client.mset ([q <- block.queries, i <- ["query_#(q.id)", JSON.stringify(q)], i], ...)!
        client.rpush ("block_#(block.id)_queries", [q <- block.queries, q.id], ...)!

      [
        block <- lexicon.blocks
        writeBlock(block)!
      ]

      blockCache.clear()

    queryById(id) = queryById(id)

    listBlocks()! =
      blockIds = client.keys("block_*")!
      blocks = [
        block <- client.mget(blockIds)!
        JSON.parse(block)
      ]
      _.sortBy(blocks, @(b) @{ b.name })

    blockById(id)! =
      JSON.parse(client.get("block_#(id)")!)

    createBlock(block)! =
      id = client.incr("next_block_id")!
      block.id = id
      client.set("block_#(id)", JSON.stringify(block))!
      id

    updateBlockById(id, block)! =
      b = self.blockById(id)!
      b.name = block.name
      client.set("block_#(id)", JSON.stringify(b))!
      true

    predicants(predicant) =
      ids = client.keys("predicant_*")!
      predicants = [
        p <- client.mget(ids)!
        JSON.parse(p)
      ]
      _.indexBy(predicants, 'id')

    addPredicant(predicant) =
      id = client.incr("next_predicant_id")!
      predicant.id = String(id)
      client.set "predicant_#(id)" (JSON.stringify(predicant))

    blockQueries(blockId)! =
      queryIds = block(blockId)!
      if (queryIds.length > 0)
        [
          query <- client.mget ([q <- queryIds, "query_#(q)"], ...)!
          JSON.parse(query)
        ]
      else
        []
  }
