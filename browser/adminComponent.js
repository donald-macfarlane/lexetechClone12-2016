var prototype = require('prote');
var throttle = require('plastiq-throttle');
var userApi = require('./userApi');
var h = require('plastiq').html;
var routes = require('./routes');
var semanticUi = require('plastiq-semantic-ui');
var userComponent = require('./userComponent');

module.exports = prototype({
  constructor: function () {
    var self = this;

    this.userApi = userApi();
    this.users = [];

    this.userApi.changed.on(function () {
      self.searchUsers.reset();
      self.refresh();
    });

    this.loadUser = throttle(function (userId) {
      if (userId == 'new') {
        self.user = userComponent({user: self.userApi.create(), userApi: self.userApi});
      } else if (userId) {
        return self.userApi.user(userId).then(function (user) {
          self.user = userComponent({user: user.edit(), userApi: self.userApi});
        });
      } else {
        delete self.user;
      }
    });

    this.searchUsers = throttle(function (query) {
      self.usersLoading = true;
      if (!query) {
        return self.userApi.users({max: 20}).then(function (users) {
          self.users = users;
          delete self.usersLoading;
        });
      } else {
        return self.userApi.search(query).then(function (users) {
          self.users = users;
          delete self.usersLoading;
        });
      }
    });
  },

  addUser: function () {
    routes.adminUser({userId: 'new'}).push();
  },

  render: function (userId) {
    var self = this;

    this.refresh = h.refresh;
    this.loadUser(userId);
    this.searchUsers(this.query);

    return h('.admin',
      h('.search',
        h('.ui.button.create.green', {onclick: this.addUser.bind(this)}, 'add user'),
        h('.ui.divider'),
        h('.ui.icon.input', {class: {loading: this.usersLoading}},
          h('input', {type: 'text', placeholder: 'search users', binding: [this, 'query']}),
          h('i.search.icon')
        ),
        h('.ui.vertical.menu.results',
          self.users.map(function (user) {
            return routes.adminUser({userId: user.id}).link({class: {item: true, teal: true, active: user.id === userId}},
              h('h5', (user.firstName || '') + ' ' + (user.familyName || '')),
              user.email
            );
          })
        )
      ),
      this.user
        ? this.user.render()
        : undefined
    );
  }
});
