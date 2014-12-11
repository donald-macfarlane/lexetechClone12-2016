redis = require 'redis'
urlUtils = require 'url'

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

  queriesInCoherenceOrder = nil

  queries() =
    if (queriesInCoherenceOrder)
      queriesInCoherenceOrder
    else
      queriesInCoherenceOrder := client.lrange 'queries' (0, -1) ^!

  {
    clear() =
      client.flushdb(^)!

    setQueries(queries) =
      self.clear()!

      for each @(q) in (queries)
        client.set(q.id, JSON.stringify(q), ^)!

      promise! @(result, error)
        client.rpush.apply (client) [
          "queries"
          [q <- queries, q.id], ...
          @(er, re)
            if (er)
              error(er)
            else
              result(re)
        ]

      queriesInCoherenceOrder := nil

    query(n) =
      self.queryById(queries()!.(n))!

    queryById(id) =
      JSON.parse(client.get(id, ^)!)

    coherenceIndexForQueryId(id) =
      index = queries()!.indexOf(id)

      if (index < 0)
        throw (new (Error "no such query id: #(JSON.stringify(id))"))

      index

    length() = queries()!.length
  }
