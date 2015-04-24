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
        topMenuTabs(model),
        authStatus(model.user)
      ),
      model.flash && (!(model.flash instanceof Array) || (model.flash.length > 0))
        ? h('div.top-flash.warning', renderFlash(model.flash),
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

function renderFlash(flash) {
  if (flash instanceof Array) {
    return flash.map(function (text) {
      return h('.message', text);
    });
  } else if (flash instanceof Object) {
    return [
      h('.message', flash.message),
      h('.detail', flash.detail)
    ];
  } else if (flash) {
    return h('.message', flash);
  }
}

function topMenuTabs(model) {
  var query = model.query();
  var currentDocument = model.currentDocument();
  var document = model.document;

  return h('div.tabs',
    model.user
      ? [
          h('a', {class: {active: !document}, href: '/', onclick: router.push}, 'Home'),
          currentDocument
            ? h('a', {class: {active: document}, href: '/reports/' + currentDocument.id, onclick: router.push}, currentDocument.name? 'Report: ' + currentDocument.name: 'Report')
            : undefined,
          query && query.query
            ? h('a', {href: '/authoring/blocks/' + query.query.block + '/queries/' + query.query.id}, 'Authoring: ' + query.query.text)
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
  http.onError(h.refreshify(function (event, jqxhr, settings) {
    if (!settings.suppressErrors) {
      var errorMessage = jqxhr.statusText + (
        jqxhr.responseJSON && jqxhr.responseJSON.message
        ? ': ' + jqxhr.responseJSON.message
        : jqxhr.responseText
          ? ': ' + jqxhr.responseText
          : ''
      );

      model.flash = {message: 'Network Error', detail: errorMessage};
      return wait(3000).then(function () {
        delete model.flash;
      });
    }
  }));
});
