var plastiq = require('plastiq');
var h = plastiq.html;
var routes = require('./routes');
var http = require('./http');
var _ = require('underscore');

module.exports = function (model, contents) {
  if (model.user || model.login || model.signup) {
    listenToHttpErrors(model);

    return h('div#wrapper',
      h('div.main',
        h('div.top-menu',
          h('div.content',
            h('div.logo'),
            authStatus(model.user),
            topMenuTabs(model),
            topMenuButtons(model)
          )
        ),
        model.flash && (!(model.flash instanceof Array) || (model.flash.length > 0))
          ? h('div.top-flash.warning', renderFlash(model.flash),
              h('a.close', {onclick: function () { delete model.flash; }})
            )
          : undefined,
        h('div.shadow'),
        h('div.content', contents)
      ),
      footer(model)
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

  function routeTab(route, title) {
    return route.a({class: {active: route.active}}, title);
  }
  var root = routes.root();

  return h('div.tabs',
    model.user
      ? [
        routeTab(routes.root(), 'Home'),
        routeTab(routes.root(), 'Tutorial'),
        routeTab(routes.root(), 'FAQ'),
        routeTab(routes.root(), 'Contact'),
      ]
      : undefined
  );
}

function topMenuButtons(model) {
  var query = model.query();
  var currentDocument = model.currentDocument();
  var document = model.document;

  function routeTab(route, title) {
    return route.a({}, title);
  }

  function authoringTab() {
    if (model.user.author) {
      if (query && query.query) {
        return h('a',
          {href: '/authoring/blocks/' + query.query.block + '/queries/' + query.query.id},
          'Authoring: ' + query.query.text
        );
      } else {
        return h('a', {href: '/authoring'}, 'Authoring')
      }
    }
  }

  function reportTab() {
    if (currentDocument) {
      var title = currentDocument.name? 'Report: ' + currentDocument.name: 'Report';
      return routeTab(routes.report({documentId: currentDocument.id}), title);
    }
  }

  function adminTab() {
    if (model.user.admin) {
      return routeTab(routes.admin(), 'Admin');
    }
  }

  return h('div.buttons',
    model.user
      ? [
          h('a', {href: '#'}, 'Save'),
          routeTab(routes.root(), 'Exit'),
          reportTab(),
          authoringTab(),
          adminTab()
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

function footer(model) {
  return h('footer',
    'LEXeNOTES is  the registered trademark of Lexeme Technologies LLC. Copyright 2015 Lexeme Technologies LLC. All rights protected. US Patent #8,706,680.'
  );
}

function wait(n) {
  return new Promise(function (result) {
    setTimeout(result, n);
  });
}

var listenToHttpErrors = _.once(function (model) {
  http.onError(h.refreshify(function (event, jqxhr, settings) {
    var ignoreError = settings.suppressErrors || jqxhr.statusText == 'abort';

    if (!ignoreError) {
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
