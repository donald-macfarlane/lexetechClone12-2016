var h = require('plastiq').html;
var prototype = require('prote');

module.exports = prototype({
  constructor: function (model) {
    this.model = model;
  },

  render: function () {
    return h('ol.document',
      this.model.history.queryResponses.filter(function (queryResponse) {
        return queryResponse.response.styles;
      }).map(function (queryResponse) {
        return h('li', queryResponse.response.styles.style1);
      })
    );
  },
});
