var plastiq = require('plastiq');
var h = plastiq.html;
var router = require('plastiq/router');

module.exports = function (model, contents) {
  if (model.user || location.pathname == '/login') {
    return h('div.main',
      h('div.top-menu',
        topMenuTabs(model.user),
        authStatus(model.user)
      ),
      model.flash
        ? h('div.top-flash.warning', model.flash,
            h('a.close', {onclick: function () { delete model.flash; }})
          )
        : undefined,
      h('div.content', contents)
    );
  } else {
    router.push('/login');
    return h('div', 'redirecting');
  }
};

function topMenuTabs(user) {
  return h('div.tabs',
    user
      ? [
          h('a', {href: '/debug'}, 'Debug'),
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
