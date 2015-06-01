var h = require('plastiq').html;
var prototype = require('prote');
var removePunctuation = require('./removePunctuation');
var isWhitespaceHtml = require('./isWhitespaceHtml');

module.exports = prototype({
  constructor: function (model) {
    this.history = model.history;
    this.setQuery = model.setQuery;
    this.documentStyle = model.documentStyle;
  },

  render: function (style) {
    var self = this;

    var variables = this.history.variables({hash: true});
    var suppressPunctuation = false;

    return h('.document-outer',
      h('ol.document',
        this.history.currentLexemes().map(function (lexeme, index) {
          return {
            lexeme: lexeme,
            index: index
          };
        }).filter(function (lexemeIndex) {
          var response = lexemeIndex.lexeme.response;
          return response && response.styles && response.styles[style] && !isWhitespaceHtml(response.styles[style]);
        }).map(function (lexemeIndex) {
          var lexeme = lexemeIndex.lexeme;
          var index = lexemeIndex.index;

          var styleHtml = lexeme.response.styles[style].replace(/!([a-z_][a-z0-9_]*)/gi, function (m, name) {
            return variables[name] || m;
          });

          if (suppressPunctuation) {
            styleHtml = removePunctuation(styleHtml);
          }

          suppressPunctuation = lexeme.suppressPunctuation;

          return h('li',
            h('a.section',
              {
                href: '#',
                onclick: function (ev) {
                  ev.preventDefault();

                  return self.history.back(index - 1).query.then(function (query) {
                    self.setQuery(query);
                  });
                }
              },
              h.rawHtml('span', styleHtml)
            )
          );
        })
      )
    );
  },
});
