module.exports () =
  queries = {}

  {
    cacheByQuery (query) andContext (context, block) =
      cached = self.hasVisitedQuery (query) context (context)
      if (@not cached)
        value = block()
        self.visitedQuery (query) context (context, value = value)
        value
      else
        cached
      
    hasVisitedQuery (query) context (context) =
      q = queries.(query.id)

      if (q)
        q.(context.key())
      else
        false

    visitedQuery (query) context (context, value = true) =
      q = queries.(query.id)

      if (@not q)
        q := queries.(query.id) = {}

      q.(context.key()) = value
  }
