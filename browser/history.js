var prototype = require('prote');
var plastiq = require('plastiq');
var ee = require('event-emitter');
var documentsApi = require('./documentsApi');

module.exports = prototype({
  constructor: function () {
    this.documentsApi = documentsApi();
    this.responsesByQueryId = {};
    this.queryResponses = [];
    ee(this);
  },

  addQueryResponse: function (query, response) {
    this.responsesByQueryId[query.query.id] = response;
    this.queryResponses.push({query: query, response: response});

    var lexemes = this.queryResponses.map(function (r) {
      return {
        query: {
          id: r.query.query.id,
          name: r.query.query.name
        },
        context: r.query.context,
        response: {
          text: r.response.text,
          id: r.response.id
        }
      };
    });
    this.documentsApi.updateDocument({lexemes: lexemes});
  },

  responseIdForQuery: function (query) {
    if (query.query) {
      var response = this.responsesByQueryId[query.query.id];
      return response && response.id;
    }
  },

  undo: function () {
    var query = this.queryResponses.pop().query;
    this.emit('query', {blockId: query.query.block, queryId: query.query.id, context: query.context});
  },

  back: function (queryResponse) {
    var currentQueryResponse;

    while(this.queryResponses.length > 0) {
      currentQueryResponse = this.queryResponses.pop();
      if (currentQueryResponse == queryResponse) {
        break;
      }
    }

    this.emit('query', {queryId: currentQueryResponse.query.query.id, context: currentQueryResponse.query.context});
  },

  canUndo: function () {
    return this.queryResponses.length > 0;
  },
});
