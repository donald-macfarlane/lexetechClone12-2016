queries = []

module.exports =
  {
    setQueries(qs) =
      queries := qs

    query(n) = queries.(n)
    length() = queries.length
  }
