var prototype = require('prote');
var plastiq = require('plastiq');
var ee = require('event-emitter');

module.exports = prototype({
  constructor: function () {
    this.responsesByQueryId = {};
    this.queryResponses = [];
    ee(this);
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
    var query = this.queryResponses.pop().query;
    this.emit('query', query);
  },

  back: function (queryResponse) {
    var currentQueryResponse;

    while(this.queryResponses.length > 0) {
      currentQueryResponse = this.queryResponses.pop();
      if (currentQueryResponse == queryResponse) {
        break;
      }
    }

    this.emit('query', currentQueryResponse.query);
  },

  canUndo: function () {
    return this.queryResponses.length > 0;
  },
});
