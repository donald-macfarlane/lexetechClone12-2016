var h = require('plastiq').html;
var prototype = require('prote');

module.exports = prototype({
  constructor: function (model) {
    this.model = model;
  },

  render: function () {
    var self = this;

    return h('.document-outer',
      h('ol.document',
        this.model.history.currentLexemes().map(function (lexeme, index) {
          return {
            lexeme: lexeme,
            index: index
          };
        }).filter(function (lexemeIndex) {
          return lexemeIndex.lexeme.response && lexemeIndex.lexeme.response.styles;
        }).map(function (lexemeIndex) {
          return h('li',
            h('a.section',
              {
                href: '#',
                onclick: function (ev) {
                  ev.preventDefault();

                  return self.model.history.back(lexemeIndex.index - 1).query.then(function (query) {
                    self.model.query.setQuery(query);
                  });
                }
              },
              h.rawHtml('span', lexemeIndex.lexeme.response.styles.custom || lexemeIndex.lexeme.response.styles.style1)
            )
          );
        })
      )
    );
  },
});
