module.exports = function(queries) {
  var n = 0;
  function stackQueries(n, level, topLevel) {
    var queriesAtLevel = [];
    var lastTree;

    while(n < queries.length) {
      var query = queries[n];
      var tree = {
        query: query
      };

      if (query.level == level) {
        queriesAtLevel.push(tree);
        n++;
      } else if (query.level > level && lastTree) {
        var result = stackQueries(n, query.level);
        lastTree.queries = result.queries;
        n = result.n;
      } else if (query.level < level) {
        if (topLevel) {
          queriesAtLevel.push(tree);
          level = query.level;
          n++;
        } else {
          break;
        }
      }

      lastTree = tree;
    }

    return {
      queries: queriesAtLevel,
      n: n
    };
  }

  if (queries.length > 0) {
    return stackQueries(0, queries[0].level, true).queries;
  } else {
    return queries;
  }
};
