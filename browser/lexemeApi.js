var cache = require("../common/cache");

module.exports = function(options) {
  var http = (options && options.hasOwnProperty('http'))? options.http: require('./http');
  var blockQueriesCache = cache();

  function blockQueries(n) {
    return blockQueriesCache.cacheBy(n, function() {
      return http.get("/api/blocks/" + n + "/queries");
    });
  };

  return {
    block: function(blockId) {
      return {
        query: function(n) {
          return blockQueries(blockId).then(function(queries) {
            return queries[n];
          });
        },

        length: function() {
          return blockQueries(blockId).then(function(queries) {
            return queries.length;
          });
        }
      };
    },

    query: function (queryId) {
      return http.get('/api/queries/' + queryId);
    }
  };
};
