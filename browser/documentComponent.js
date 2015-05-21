var h = require('plastiq').html;
var prototype = require('prote');

module.exports = prototype({
  constructor: function (model) {
    this.history = model.history;
    this.setQuery = model.setQuery;
    this.documentStyle = model.documentStyle;
  },

  render: function (style) {
    var self = this;

    var variables = {};
    var suppressPunctuation = false;

    return h('.document-outer',
      h('ol.document',
        this.history.currentLexemes().map(function (lexeme, index) {
          return {
            lexeme: lexeme,
            index: index
          };
        }).filter(function (lexemeIndex) {
          return lexemeIndex.lexeme.response && lexemeIndex.lexeme.response.styles;
        }).map(function (lexemeIndex) {
          var lexeme = lexemeIndex.lexeme;
          var index = lexemeIndex.index;

          if (lexeme.variables) {
            lexeme.variables.forEach(function (variable) {
              variables[variable.name] = variable.value;
            });
          }

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

function removePunctuation(html) {
  return html.replace(/^[.,] /, '');
}
