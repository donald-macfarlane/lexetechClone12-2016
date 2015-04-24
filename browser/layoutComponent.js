var plastiq = require('plastiq');
var h = plastiq.html;
var router = require('./router');
var http = require('./http');
var _ = require('underscore');

module.exports = function (model, contents) {
  if (model.user || model.login || model.signup) {
    listenToHttpErrors(model);

    return h('div.main',
      h('div.top-menu',
        topMenuTabs(model.user, model.query()),
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

function topMenuTabs(user, query) {
  return h('div.tabs',
    user
      ? [
          h('a.active', {href: '/', onclick: router.push}, 'Report'),
          query && query.query
            ? h('a', {href: '/authoring/blocks/' + query.query.block + '/queries/' + query.query.id}, 'Author ' + query.query.text)
            : h('a', {href: '/authoring'}, 'Authoring')
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

function wait(n) {
  return new Promise(function (result) {
    setTimeout(result, n);
  });
}

var listenToHttpErrors = _.once(function (model) {
  http.onError(h.refreshify(function (event, jqxhr) {
    model.flash = [jqxhr.responseText];
    return wait(3000).then(function () {
      delete model.flash;
    });
  }));
});
