var prototype = require('prote');
var createContext = require('./context');

module.exports = prototype({
  constructor: function (options) {
    var self = this;

    this.document = options.document;
    this.responsesByQueryId = {};
    this.lexemes = [];
    this.index = -1;
    this.queryGraph = options.queryGraph;
    this.lexemeApi = options.lexemeApi;

    this.rebuildHistory().then(function () {
      self.refresh();
    });

    this.setQuery = this.setQuery.bind(this);

    this.refresh = options.refresh;
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

    return Promise.all(
      this.document.lexemes.map(function (lexeme) {
        if (lexeme.response) {

          var unchangedStyles = Object.keys(lexeme.response.styles).filter(function (style) {
            return !lexeme.response.changedStyles[style];
          });

          if (unchangedStyles.length > 0) {
            return self.lexemeApi.query(lexeme.query.id).then(function (query) {
              Object.keys(lexeme.response.styles).forEach(function (style) {
                if (!lexeme.response.changedStyles[style]) {
                  var response = query.responses.filter(function (r) {
                    return r.id == lexeme.response.id;
                  })[0];

                  if (response) {
                    lexeme.response.styles[style] = response.styles[style];
                  }
                }
              });
            });
          }
        }
      })
    );
  },

  acceptLexeme: function (lexeme) {
    return this.queryGraph.query(lexeme.query.id, lexeme.context).then(function (query) {
      if (lexeme.response) {
        var response = query.responses.filter(function (response) {
          return response.id == lexeme.response.id;
        })[0];

        return response.query();
      } else if (lexeme.skip) {
        return query.skip();
      } else if (lexeme.omit) {
        return query.omit();
      }
    });
  },

  currentLexemes: function () {
    return this.lexemes.slice(0, this.index + 1);
  },

  variables: function (options) {
    var varList = [];

    this.currentLexemes().forEach(function (lexeme) {
      varList.push.apply(varList, lexeme.variables);
    });

    if (options && options.hash) {
      var variables = {};

      varList.forEach(function (variable) {
        variables[variable.name] = variable.value;
      });

      return variables;
    } else {
      return varList;
    }
  },

  currentQuery: function () {
    this.loadingQuery = true;

    if (this.document.lexemes.length && this.index >= 0) {
      var lexeme = this.document.lexemes[this.index];
      return this.acceptLexeme(lexeme).then(this.setQuery);
    } else {
      return this.queryGraph.firstQueryGraph().then(this.setQuery);
    }
  },

  selectResponse: function (response, styles) {
    this.loadingQuery = true;
    return {
      query: response.query().then(this.setQuery),
      documentSaved: this.addQueryResponse(this.query.query, this.query.context, response, styles)
    };
  },

  skip: function () {
    var self = this;

    this.loadingQuery = true;
    return {
      query: self.query.skip().then(this.setQuery),
      documentSaved: self.addQuerySkip(self.query.query, self.query.context)
    };
  },

  setQuery: function (q) {
    this.loadingQuery = false;
    this.query = q;
    return q;
  },

  omit: function () {
    var self = this;

    this.loadingQuery = true;
    return {
      query: self.query.omit().then(self.setQuery),
      documentSaved: self.addQueryOmit(self.query.query, self.query.context)
    };
  },

  serialiseQuery: function (query) {
    return {
      id: query.id,
      name: query.name,
      text: query.text
    };
  },

  addQueryResponse: function (query, context, response, styles) {
    var lexeme = {
      query: this.serialiseQuery(query),
      context: context,
      variables: response.variables,
      suppressPunctuation: response.suppressPunctuation,
      response: {
        text: response.text,
        id: response.id,
        repeat: response.repeat,
        styles: styles || response.styles,
        changedStyles: (styles && changedStyles(styles, response.styles)) || {}
      }
    };

    return this.pushLexeme(lexeme);
  },

  stylesForQueryResponse: function (response) {
    var responseByQueryId = this.responsesByQueryId[this.query.query.id];

    if (responseByQueryId) {
      return responseByQueryId.stylesByResponseId[response.id];
    }
  },

  pushLexeme: function (lexeme, options) {
    if (lexeme.response) {
      var responseByQueryId = this.responsesByQueryId[lexeme.query.id] = this.responsesByQueryId[lexeme.query.id] || {
        stylesByResponseId: {}
      };

      responseByQueryId.stylesByResponseId[lexeme.response.id] = lexeme.response.styles;

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
              (lexeme.response && lastLexeme.response && lastLexeme.response.id == lexeme.response.id)
              || (lexeme.skip && lastLexeme.skip)
              || (lexeme.omit && lastLexeme.omit)))) {
        this.lexemes.splice(this.index, this.lexemes.length - this.index, lexeme);
      } else {
        this.lexemes[this.index] = lexeme;
      }
    }

    var save = options && options.hasOwnProperty('save')? options.save: true;

    if (save) {
      return this.updateDocument();
    }
  },

  addQuerySkip: function (query, context, options) {
    var lexeme = {
      query: this.serialiseQuery(query),
      context: context,
      skip: true
    };

    this.pushLexeme(lexeme, options);
  },

  addQueryOmit: function (query, context, options) {
    var lexeme = {
      query: this.serialiseQuery(query),
      context: context,
      omit: true
    };

    this.pushLexeme(lexeme, options);
  },

  checkedResponses: function () {
    var responses = {};

    var index = this.loadingQuery? this.index - 1: this.index;
    
    for (var n = index; n >= 0; n--) {
      var lexeme = this.document.lexemes[n];
      if (this.query.query && this.query.query.id === lexeme.query.id) {
        responses[lexeme.response.id] = true;
      } else {
        break;
      }
    }

    return responses;
  },

  accept: function () {
    this.index++;
    var lexeme = this.document.lexemes[this.index];
    var queryPromise = this.acceptLexeme(lexeme);

    this.loadingQuery = true;

    return {
      query: queryPromise.then(this.setQuery),
      documentSaved: this.updateDocument()
    };
  },

  lexemeToAccept: function () {
    if (this.index + 1 < this.document.lexemes.length) {
      return this.document.lexemes[this.index + 1];
    }
  },

  updateDocument: function () {
    return this.document.update({lexemes: this.lexemes, index: this.index});
  },

  undo: function () {
    var lexeme = this.lexemes[this.index];
    this.index--;

    this.loadingQuery = true;

    return {
      query: this.queryGraph.query(lexeme.query.id, lexeme.context).then(this.setQuery),
      documentSaved: this.updateDocument()
    };
  },

  back: function (index) {
    if (this.lexemes.length > index) {
      if (this.index !== index) {
        this.index = index;

        return {
          query: this.currentQuery(),
          documentSaved: this.updateDocument()
        };
      } else {
        return {
          query: Promise.resolve(this.query),
          documentSaved: Promise.resolve(undefined)
        };
      }
    } else {
      throw new Error('cannot go to query index: ' + index + ', there are only ' + this.lexemes.length + ' queries');
    }
  },

  canUndo: function () {
    return this.index >= 0;
  },
});

function changedStyles(styles, originalStyles) {
  var changed = {};

  Object.keys(styles).forEach(function (key) {
    changed[key] = styles[key] !== originalStyles[key];
  });

  return changed;
}
