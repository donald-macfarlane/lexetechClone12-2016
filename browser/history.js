var prototype = require('prote');
var plastiq = require('plastiq');
var buildGraph = require('./buildGraph');
var ee = require('event-emitter');
var createContext = require('./context');

module.exports = prototype({
  constructor: function (options) {
    this.document = options.document;
    this.responsesByQueryId = {};
    this.lexemes = [];
    this.index = -1;
    this.queryGraph = options.queryGraph;
    ee(this);

    this.rebuildHistory();
  },

  rebuildHistory: function () {
    var self = this;

    this.document.lexemes.forEach(function (lexeme) {
      lexeme.context = createContext(lexeme.context);
      self.pushLexeme(lexeme, {save: false});
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
        if (lexeme.response) {
          var response = query.responses.filter(function (response) {
            return response.id = lexeme.response.id;
          })[0];

          return response.query();
        } else if (lexeme.skip) {
          return query.skip();
        } else if (lexeme.omit) {
          return query.omit();
        }
      });
    } else {
      return this.queryGraph.firstQueryGraph();
    }
  },

  addQueryResponse: function (query, response, context, options) {
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

    this.pushLexeme(lexeme, options);
  },

  pushLexeme: function (lexeme, options) {
    if (lexeme.response) {
      var responseByQueryId = this.responsesByQueryId[lexeme.query.id] = this.responsesByQueryId[lexeme.query.id] || {};

      if (lexeme.response.repeat) {
        responseByQueryId.others = responseByQueryId.others || [];
        responseByQueryId.others.push(lexeme.response);
      } else {
        responseByQueryId.response = lexeme.response;
      }
    }

    this.index++;

    if (this.index > this.lexemes.length - 1) {
      this.lexemes.push(lexeme);
    } else {
      var lastLexeme = this.lexemes[this.index];

      if (!(lastLexeme.query.id == lexeme.query.id
            && lastLexeme.context.key() == lexeme.context.key()
            && (
              (lexeme.response && lastLexeme.response.id == lexeme.response.id)
              || (lexeme.skip && lastLexeme.skip)
              || (lexeme.omit && lastLexeme.omit)))) {
        this.lexemes.splice(this.index, this.lexemes.length - this.index, lexeme);
      }
    }

    var save = options && options.hasOwnProperty('save')? options.save: true;

    if (save) {
      this.document.update({lexemes: this.lexemes, index: this.index});
    }
  },

  addQuerySkip: function (query, context, options) {
    var lexeme = {
      query: {
        id: query.id,
        name: query.name
      },
      context: context,
      skip: true
    };

    this.pushLexeme(lexeme, options);
  },

  addQueryOmit: function (query, context, options) {
    var lexeme = {
      query: {
        id: query.id,
        name: query.name
      },
      context: context,
      omit: true
    };

    this.pushLexeme(lexeme, options);
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
