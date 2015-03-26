var prototype = require('prote');
var plastiq = require('plastiq');
var buildGraph = require('./buildGraph');
var ee = require('event-emitter');
var createContext = require('./context');

module.exports = prototype({
  constructor: function (model) {
    this.document = model.document;
    this.responsesByQueryId = {};
    this.lexemes = [];
    this.index = -1;
    this.queryGraph = buildGraph({cache: false, hack: model.graphHack !== undefined? model.graphHack: true});
    ee(this);

    this.rebuildHistory();
  },

  rebuildHistory: function () {
    var self = this;

    this.document.lexemes.forEach(function (lexeme) {
      self.addQueryResponse(lexeme.query, lexeme.response, createContext(lexeme.context), {save: false});
    });

    if (this.document.index !== undefined) {
      this.index = this.document.index;
    }
  },

  currentQuery: function () {
    var self = this;

    if (this.document.lexemes.length && this.index >= 0) {
      var lexeme = this.document.lexemes[this.index];
      return self.queryGraph.query(lexeme.query.id, lexeme.context).then(function (query) {
        var response = query.responses.filter(function (response) {
          return response.id = lexeme.response.id;
        })[0];

        return response.query();
      });
    } else {
      return this.queryGraph.firstQueryGraph();
    }
  },

  addQueryResponse: function (query, response, context, options) {
    var save = options && options.hasOwnProperty('save')? options.save: true;

    var responseByQueryId = this.responsesByQueryId[query.id] = this.responsesByQueryId[query.id] || {};

    if (response.repeat) {
      responseByQueryId.others = responseByQueryId.others || [];
      responseByQueryId.others.push(response);
    } else {
      responseByQueryId.response = response;
    }

    this.index++;

    var lexeme = {
      query: {
        id: query.id,
        name: query.name
      },
      context: context,
      response: {
        text: response.text,
        id: response.id,
        repeat: response.repeat,
        styles: response.styles
      }
    };

    if (this.index > this.lexemes.length - 1) {
      this.lexemes.push(lexeme);
    } else {
      var lastLexeme = this.lexemes[this.index];

      if (!(lastLexeme.query.id == query.id && lastLexeme.context.key() == context.key() && lastLexeme.response.id == response.id)) {
        this.lexemes.splice(this.index, this.lexemes.length - this.index, lexeme);
      }
    }

    if (save) {
      this.document.update({lexemes: this.lexemes, index: this.index});
    }
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
    var self = this;
    var lexeme = this.lexemes[this.index];
    this.index--;
    this.queryGraph.query(lexeme.query.id, lexeme.context).then(function (query) {
      self.emit('query', query);
    });

    this.document.update({lexemes: this.lexemes, index: this.index});
  },

  back: function (lexeme) {
    var self = this;
    var currentLexeme;

    while(this.lexemes.length > 0) {
      currentLexeme = this.lexemes.pop();
      if (currentLexeme == lexeme) {
        break;
      }
    }

    var queryId = currentLexeme.query.id;
    var context = currentLexeme.context;
    this.queryGraph.query(queryId, context).then(function (query) {
      self.emit('query', query);
    });
  },

  canUndo: function () {
    return this.index >= 0;
  },
});
