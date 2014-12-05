redis = require 'redis'

module.exports () =
  client = redis.createClient()

  qs = nil

  queries() =
    if (qs)
      qs
    else
      qs := client.lrange 'queries' (0, -1) ^!

  {
    setQueries(queries) =
      client.flushdb(^)!

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

    query(n) =
      self.queryById(queries()!.(n))!

    queryById(id) =
      JSON.parse(client.get(id, ^)!)

    coherenceIndexForQueryId(id) =
      queries()!.indexOf(id)

    length() = queries()!.length
  }