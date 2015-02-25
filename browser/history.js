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
    console.log('history: updating');
    this.documentsApi.updateDocument({lexemes: lexemes});
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
