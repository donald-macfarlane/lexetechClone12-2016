var plastiq = require('plastiq');
var h = plastiq.html;
var router = require('./router');

module.exports = function (model, contents) {
  if (model.user || model.login || model.signup) {
    return h('div.main',
      h('div.top-menu',
        topMenuTabs(model.user),
        authStatus(model.user)
      ),
      model.flash && model.flash.length > 0
        ? h('div.top-flash.warning', model.flash,
            h('a.close', {onclick: function () { delete model.flash; }})
          )
        : undefined,
      h('div.content', contents)
    );
  } else {
    model.login = true;
    h.refresh();
    return h('div', 'redirecting');
  }
};

function topMenuTabs(user) {
  return h('div.tabs',
    user
      ? [
          h('a.active', {href: '/'}, 'Report'),
          h('a', {href: '/authoring'}, 'Authoring')
      ]
      : undefined
  );
}

function authStatus(user) {
  return h('div.user', {class: { 'logged-out': !user, 'logged-in': user }},
    user
      ? [
        h('span', user.email),
        h('form.logout', {method: 'POST', action: '/logout'},
          h('input', {type: 'submit', value: 'Logout'})
        )
      ]
      : undefined
  );
}
