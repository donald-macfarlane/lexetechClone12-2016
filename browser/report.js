var h = require('plastiq').html;
var router = require('plastiq/router');
var prototype = require('prote');

var queryComponent = require('./query');
var debugComponent = require('./debug');
var documentComponent = require('./document');
var layout = require('./layout');
var login = require('./login');
var historyComponent = require('./history');

module.exports = prototype({
  constructor: function (pageData) {
    this.user = pageData.user;
    this.document = documentComponent(this);
    this.debug = debugComponent(this);
    this.query = queryComponent(this);
    this.history = historyComponent(this);
  },

  currentQuery: function () {
    return this.query.query;
  },

  render: function () {
    var self = this;

    return layout(self,
      router(
        router.page('/',
          function () {
            return h('div.report',
              self.query.render(),
              self.document.render(),
              h('button', {onclick: function () { self.debug.show = !self.debug.show; }}, 'debug'),
              self.debug.render()
            );
          }
        ),
        router.page('/login', login)
      )
    );
  }
});
