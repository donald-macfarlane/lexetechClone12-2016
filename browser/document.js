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
        this.model.history.queryResponses.filter(function (queryResponse) {
          return queryResponse.response.styles;
        }).map(function (queryResponse) {
          return h('li',
            h('a.section',
              {
                href: '#',
                onclick: function (ev) {
                  self.model.history.back(queryResponse);
                  ev.preventDefault();
                }
              },
              h.rawHtml('span', queryResponse.response.styles.custom || queryResponse.response.styles.style1)
            )
          );
        })
      )
    );
  },
});
