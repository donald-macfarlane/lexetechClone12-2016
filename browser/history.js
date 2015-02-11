var prototype = require('prote');

module.exports = prototype({
  constructor: function () {
    this.responsesByQueryId = {};
    this.queryResponses = [];
  },

  addQueryResponse: function (query, response) {
    this.responsesByQueryId[query.query.id] = response;
    this.queryResponses.push({query: query, response: response});
  },

  responseForQuery: function (query) {
    if (query.query) {
      return this.responsesByQueryId[query.query.id];
    }
  },

  undo: function () {
    return this.queryResponses.pop().query;
  },

  canUndo: function () {
    return this.queryResponses.length > 0;
  },
});
