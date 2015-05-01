var prototype = require('prote');
var sync = require('./sync');
var userApi = require('./userApi');
var h = require('plastiq').html;
var routes = require('./routes');
var semanticUi = require('plastiq-semantic-ui');
var jsonHtml = require('./jsonHtml');
var userComponent = require('./userComponent');

module.exports = prototype({
  constructor: function () {
    var self = this;

    this.userApi = userApi();

    this.syncUser = sync({
      watch: function () { return self.userId; }
    }, function () {
      if (self.userId) {
        return self.userApi.user(self.userId).then(function (user) {
          self.user = userComponent(user.edit());
        });
      } else {
        delete self.user;
      }
    });
  },

  render: function (userId) {
    var self = this;

    this.userId = userId;
    this.syncUser();

    return h('.admin',
      semanticUi.search(
        {
          apiSettings: {
            url: '/api/users/search?q={query}'
          },
          onSelect: function (user) {
            routes.adminUser({userId: user.id}).push();
          }
        },
        h('.ui.search',
          h('.ui.icon.input',
            h('input.prompt', {type: 'text', placeholder: 'user'}),
            h('i.search.icon')
          ),
          h('.results')
        )
      ),
      this.user
        ? this.user.render()
        : undefined
    );
  }
});
