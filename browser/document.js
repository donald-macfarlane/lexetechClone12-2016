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
        this.model.history.lexemes.filter(function (lexeme) {
          return lexeme.response.styles;
        }).map(function (lexeme) {
          return h('li',
            h('a.section',
              {
                href: '#',
                onclick: function (ev) {
                  self.model.history.back(lexeme);
                  ev.preventDefault();
                }
              },
              h.rawHtml('span', lexeme.response.styles.custom || lexeme.response.styles.style1)
            )
          );
        })
      )
    );
  },
});
