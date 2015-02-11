redis = require 'then-redis'
urlUtils = require 'url'
cache = require '../common/cache'
_ = require 'underscore'
bluebird = require 'bluebird'

createClient(url) =
  if (url)
    redisURL = urlUtils.parse(url)
    client = redis.createClient {port = redisURL.port, host = redisURL.hostname, no_ready_check = true}
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

      getAll(ids, withPrefix) =
        keys =
          if (withPrefix)
            ids
          else
            [id <- ids, "#(name):#(id)"]

        if (keys.length > 0)
          objects = [
            p <- client.mget(keys)!
            JSON.parse(p)
          ]
        else
          []

      list() =
        ids = self.ids()!
        self.getAll(ids, true)!

      removeAll() =
        ids = self.ids()!
        if (ids.length > 0)
          client.del(ids, ...)!
    }

  orderedListPrototype = prototype {
    add(id, item) =
      i = self.collection.add(item)!
      client.rpush("#(self.name):#(id)", i.id)!
      i

    addAll(id, items) =
      self.collection.addAll(items)!
      client.rpush ("#(self.name):#(id)", [i <- items, i.id], ...)!

    list(id) =
      ids = client.lrange("#(self.name):#(id)", 0, -1)!
      self.collection.getAll(ids)!

    moveAfter(id, itemId, afterItemId) =
      client.multi()
      client.linsert("#(self.name):#(id)", 'after', afterItemId, itemId)
      client.lrem("#(self.name):#(id)", 1, itemId)
      client.exec()!

    moveBefore(id, itemId, beforeItemId) =
      client.multi()
      client.linsert("#(self.name):#(id)", 'before', beforeItemId, itemId)
      client.lrem("#(self.name):#(id)", -1, itemId)
      client.exec()!

    insertBefore(id, itemId, item) =
      i = self.collection.add(item)!
      client.linsert("#(self.name):#(id)", 'before', itemId, i.id)!
      i

    insertAfter(id, itemId, item) =
      i = self.collection.add(item)!
      client.linsert("#(self.name):#(id)", 'after', itemId, i.id)!
      i

    remove(id, itemId) =
      self.collection.remove(itemId)!
      client.lrem("#(self.name):#(id)", 1, itemId)!
  }

  orderedList(name, collection) = orderedListPrototype {
    name = name
    collection = collection
  }

  blocks = domainObject 'block'
  predicants = domainObject 'predicant'
  queries = domainObject 'query'
  blockQueries = orderedList('block_queries', queries)
  userQueries = orderedList('user_queries', queries)

  {
    clear() =
      client.flushdb()!

    setLexicon(lexicon) =
      self.clear()!

      writePredicants() =
        predicateNames = _.uniq [
          b <- lexicon.blocks
          q <- b.queries
          p <- [q.predicants, ..., [r <- q.responses, rp <- r.predicants, rp], ...]
          p
        ]

        preds = [name <- predicateNames, { name = name }]
        self.addPredicants(preds)!
        predIndex = _.indexBy(preds, 'name')

        predicantContainers = [
          b <- lexicon.blocks
          q <- b.queries
          x <- [q, q.responses, ...]
          x
        ]

        for each @(predicantContainer) in (predicantContainers)
          predicantContainer.predicants = [
            pred <- predicantContainer.predicants
            predIndex.(pred).id
          ]

      writePredicants()!

      writeBlock(block) =
        savedBlock = blocks.add(_.omit(block, 'queries'))!

        block.queries.forEach @(query)
          query.block = savedBlock.id

        blockQueries.addAll(savedBlock.id, block.queries)!

      [
        block <- lexicon.blocks
        writeBlock(block)!
      ]

    mapQueryPredicants(query, predicants) =
      query.predicants = [
        pred <- query.predicants
        predicants.(pred).name
      ]

      query.responses.forEach @(response)
        response.predicants = [
          pred <- response.predicants
          predicants.(pred).name
        ]

      query

    getLexicon() =
      predicantsById = self.predicants()!

      getBlockQueries(block) =
        block.queries = [
          query <- blockQueries.list(block.id)!
          self.mapQueryPredicants(query, predicantsById)
        ]

        block

      {
        blocks = [
          block <- _.sortBy (blocks.list()!, @(b) @{ Number(b.id) })
          getBlockQueries(block)!
        ]
      }

    queryById(id) =
      queries.get(id)!

    updateQuery(id, query) =
      queries.update(id, query)!
      query

    moveQueryAfter(blockId, queryId, afterQueryId) =
      blockQueries.moveAfter(blockId, queryId, afterQueryId)!

    moveQueryBefore(blockId, queryId, beforeQueryId) =
      blockQueries.moveBefore(blockId, queryId, beforeQueryId)!

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
      blockQueries.insertBefore(blockId, queryId, query)!

    insertQueryAfter(blockId, queryId, query) =
      blockQueries.insertAfter(blockId, queryId, query)!

    addQuery(blockId, query) =
      blockQueries.add(blockId, query)!

    addQueryToUser(userId, query) =
      userQueries.add(userId, query)!

    userQueries(userId, query) =
      userQueries.list(userId)!

    deleteUserQuery(userId, queryId) =
      userQueries.remove(userId, queryId)!

    deleteQuery(blockId, queryId) =
      blockQueries.remove(blockId, queryId)!

    predicants(predicant) =
      _.indexBy(predicants.list()!, 'id')

    removeAllPredicants() =
      predicants.removeAll()!

    addPredicant(predicant) =
      predicants.add(predicant)!

    addPredicants(p) =
      predicants.addAll(p)!

    blockQueries(blockId)! =
      blockQueries.list(blockId)!
  }
