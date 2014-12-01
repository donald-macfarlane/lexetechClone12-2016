module.exports () =
  queries = {}

  {
    query (id, query)! =
      if (query)
        queries.(id) = query
      else
        queries.(id)
  }
