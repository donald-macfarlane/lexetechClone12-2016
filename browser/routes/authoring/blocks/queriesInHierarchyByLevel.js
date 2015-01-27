module.exports = function(queries) {
  var n = 0;
  function stackQueries(n, level) {
    var queriesAtLevel = [];
    var lastQuery;

    while(n < queries.length) {
      var query = queries[n];

      if (query.level == level) {
        queriesAtLevel.push(query);
        n++;
      } else if (query.level > level && lastQuery) {
        var result = stackQueries(n, query.level);
        lastQuery.queries = result.queries;
        n = result.n;
      } else if (query.level < level) {
        break;
      }

      lastQuery = query;
    }

    return {
      queries: queriesAtLevel,
      n: n
    };
  }

  if (queries.length > 0) {
    return stackQueries(0, queries[0].level).queries;
  } else {
    return queries;
  }
};
