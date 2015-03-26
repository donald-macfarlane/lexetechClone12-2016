var cache = require("../common/cache");
var Promise = require('bluebird');

module.exports = function(options) {
  var http = (options && options.hasOwnProperty('http'))? options.http: require('./http');
  var blockQueriesCache = cache();
  var queryCache = cache();

  function blockQueries(n) {
    return blockQueriesCache.cacheBy(n, function() {
      return http.get("/api/blocks/" + n + "/queries").then(function (queries) {
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
        return http.get('/api/queries/' + queryId);
      });
    },

    predicants: function () {
      return this._predicants || (
        this._predicants = http.get('/api/predicants')
      );
    }
  };
};
