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

  domainObject(name) =
    {
      addAll(objects) =
        if (objects.length > 0)
          last = client.incrby("last_#(name)_id", objects.length)!
          first = last - objects.length

          for each @(pn) in (_.zip(objects, [(first + 1)..last]))
            pn.0.id = String(pn.1)
          
          client.mset! [
            p <- objects
            key = "#(name):#(p.id)"
            value = JSON.stringify(p)
            x <- [key, value]
            x
          ] ...

      get(id) =
        JSON.parse(client.get "#(name):#(id)"!)

      add(object) =
        id = client.incr("last_#(name)_id")!
        object.id = String(id)
        client.set("#(name):#(id)", JSON.stringify(object))!
        object

      update(id, object) =
        object.id = id
        client.set("#(name):#(id)", JSON.stringify(object))!
        object

      remove(id) =
        client.del("#(name):#(id)")!

      ids() =
        ids = []

        scan(c) =
          cursor = if (c == nil)
            0
          else if (c == '0')
            nil
          else
            c
          
          if (cursor != nil)
            result = client.scan(cursor, 'match', "#(name):*")!
            ids.push(result.1, ...)
            scan(result.0)!

        scan()!

        ids

      list() =
        ids = self.ids()!
        if (ids.length > 0)
          objects = [
            p <- client.mget(ids)!
            JSON.parse(p)
          ]
        else
          []

      removeAll() =
        ids = self.ids()!
        if (ids.length > 0)
          client.del(ids, ...)!
    }

  blocks = domainObject 'block'
  predicants = domainObject 'predicant'
  queries = domainObject 'query'

  {
    clear() =
      client.flushdb()!

    setLexicon(lexicon) =
      self.clear()!

      writeBlock(block) =
        queries.addAll(block.queries)!
        id = block.id
        savedBlock = blocks.add(_.omit(block, 'queries'))!
        client.rpush ("block_queries:#(savedBlock.id)", [q <- block.queries, q.id], ...)!

      [
        block <- lexicon.blocks
        writeBlock(block)!
      ]

      predicateNames = _.uniq [
        b <- lexicon.blocks
        q <- b.queries
        p <- [q.predicants, ..., [r <- q.responses, rp <- r.predicants, rp], ...]
        p
      ]

      self.addPredicants([ name <- predicateNames, { name = name }])!

    queryById(id) =
      queries.get(id)!

    updateQuery(id, query) =
      queries.update(id, query)!
      query

    moveQueryAfter(blockId, queryId, afterQueryId) =
      client.multi()
      client.linsert("block_queries:#(blockId)", 'after', afterQueryId, queryId)
      client.lrem("block_queries:#(blockId)", 1, queryId)
      client.exec()!

    moveQueryBefore(blockId, queryId, beforeQueryId) =
      client.multi()
      client.linsert("block_queries:#(blockId)", 'before', beforeQueryId, queryId)
      client.lrem("block_queries:#(blockId)", -1, queryId)
      client.exec()!

    listBlocks()! =
      b = blocks.list()!
      _.sortBy(b, 'name')

    blockById(id) =
      blocks.get(id)!

    createBlock(block)! =
      blocks.add(block)!

    updateBlockById(id, block)! =
      blocks.update(id, block)!

    insertQueryBefore(blockId, queryId, query) =
      q = queries.add(query)!
      client.linsert("block_queries:#(blockId)", 'before', queryId, q.id)!
      q

    insertQueryAfter(blockId, queryId, query) =
      q = queries.add(query)!
      client.linsert("block_queries:#(blockId)", 'after', queryId, q.id)!
      q

    addQuery(blockId, query) =
      q = queries.add(query)!
      client.rpush("block_queries:#(blockId)", q.id)!
      q

    deleteQuery(blockId, queryId) =
      queries.remove(queryId)!
      client.lrem("block_queries:#(blockId)", 1, queryId)!

    predicants(predicant) =
      _.indexBy(predicants.list()!, 'id')

    removeAllPredicants() =
      predicants.removeAll()!

    addPredicant(predicant) =
      predicants.add(predicant)!

    addPredicants(p) =
      predicants.addAll(p)!

    blockQueries(blockId)! =
      queryIds = client.lrange("block_queries:#(blockId)", 0, -1)!

      if (queryIds.length > 0)
        [
          query <- client.mget ([q <- queryIds, "query:#(q)"], ...)!
          JSON.parse(query)
        ]
      else
        []
  }
