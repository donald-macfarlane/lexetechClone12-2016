var h = require('plastiq').html;
var router = require('plastiq/router');
var prototype = require('prote');

var queryComponent = require('./query');
var debugComponent = require('./debug');
var documentComponent = require('./document');
var layout = require('./layout');
var login = require('./login');
var signup = require('./signup');
var historyComponent = require('./history');

module.exports = prototype({
  constructor: function (pageData) {
    this.user = pageData.user;
    this.flash = pageData.flash;
    this.document = documentComponent(this);
    this.debug = debugComponent(this);
    this.history = historyComponent();
    this.query = queryComponent(this);
  },

  currentQuery: function () {
    return this.query.query;
  },

  render: function () {
    var self = this;

    function master(fn) {
      return function() {
        return layout(self, fn());
      };
    }

    return router(
      router.page('/',
        master(function () {
          return h('div.report',
            self.query.render(),
            self.document.render(),
            h('button', {onclick: function () { self.debug.show = !self.debug.show; }}, 'debug'),
            self.debug.render()
          );
        })
      ),
      router.page('/login',
        {
          binding: [self, 'auth'],
          state: true
        },
        master(login)
      ),
      router.page('/signup',
        {
          binding: [self, 'auth'],
          state: true
        },
        master(signup)
      )
    );
  }
});
