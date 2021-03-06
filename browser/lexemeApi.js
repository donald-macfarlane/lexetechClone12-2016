var cache = require("../common/cache");

module.exports = function(options) {
  var http = (options && options.hasOwnProperty('http'))? options.http: require('./http');
  var blockQueriesCache = cache();
  var queryCache = cache();

  function blockQueries(n) {
    return blockQueriesCache.cacheBy(n, function() {
      return http.get("/api/blocks/" + n + "/queries").then(function (response) {
        var queries = response.body;
        queries.forEach(function (query) {
          queryCache.add(query.id, Promise.resolve(query));
        });
        return queries;
      });
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
      return queryCache.cacheBy(queryId, function () {
        return http.get('/api/queries/' + queryId).then(function (response) {
          return response.body;
        });
      });
    },

    predicants: function () {
      return this._predicants || (
        this._predicants = http.get('/api/predicants').then(function (response) {
          return response.body;
        })
      );
    }
  };
};
