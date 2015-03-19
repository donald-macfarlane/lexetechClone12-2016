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
    var responseByQueryId = this.responsesByQueryId[query.query.id] = this.responsesByQueryId[query.query.id] || {};

    if (response.repeat) {
      responseByQueryId.others = responseByQueryId.others || [];
      responseByQueryId.others.push(response);
    } else {
      responseByQueryId.response = response;
    }

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

  responsesForQuery: function (query) {
    if (query.query) {
      var responses = this.responsesByQueryId[query.query.id];
      if (responses) {
        var others = {};

        responses.others && responses.others.forEach(function (r) {
          others[r.id] = true;
        });

        return {
          previous: responses.response && responses.response.id,
          others: others
        };
      }
    }
  },

  undo: function () {
    var query = this.queryResponses.pop().query;
    this.emit('query', {blockId: query.query.block, queryId: query.query.id, context: query.nextContext});
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
