queries = []

module.exports =
  {
    queryByCoherenceIndex(index) =
      queries.(index)

    setQueries(qs) =
      queries := qs

    queries() = queries
  }
