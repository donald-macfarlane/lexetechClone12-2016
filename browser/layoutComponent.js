var plastiq = require('plastiq');
var h = plastiq.html;
var routes = require('./routes');
var http = require('./http');
var _ = require('underscore');
var wait = require('./wait');

module.exports = function (model, contents) {
  if (model.user || model.login || model.signup) {
    listenToHttpErrors(model);

    return h('div#wrapper',
      h('div.main',
        h('div.top-menu',
          h('div.content',
            h('div.logo',
              h('img',{src: '/source/logo.png'})
            ),
            authStatus(model.user),
            topMenuTabs(model),
            topMenuButtons(model)
          )
        ),
        h('div.shadow'),
        model.flash
          ? renderFlash(model)
          : undefined,
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

function renderFlash(model) {
  var flash = model.flash;
  
  function close() {
    return h('a.close', {onclick: function () { delete model.flash; }});
  }

  if (flash instanceof Array) {
    return flash.map(function (flashMessage) {
      return h('div.ignored.ui.message', {class: flashMessage.type}, h.rawHtml('span', flashMessage.message), close());
    });
  } else if (flash instanceof Object) {
    return h('div.ignored.ui.message.warning',
      h('.message', flash.message),
      h('.detail', flash.detail),
      close()
    );
  } else if (flash) {
    return h('div.ignored.ui.message.warning', flash, close());
  }
}

function topMenuTabs(model) {
  var query = model.query();
  var currentDocument = model.currentDocument();
  var document = model.document;

  function routeTab(route, title, active) {
    return route.a({class: {active: active}}, title);
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

  function routeTab(route, title, active) {
    return route.a({class: {ui: true, button: true, active: active}}, title);
  }

  function authoringTab() {
    if (model.user.author) {
      if (query && query.query) {
        return routeTab(
          routes.authoringQuery({blockId: query.query.block, queryId: query.query.id}),
          'Authoring',
          routes.authoring.under().active
        );
      } else {
        return routeTab(
          routes.authoring(),
          'Authoring',
          routes.authoring.under().active
        );
      }
    }
  }
  
  function adminTab() {
    if (model.user.admin) {
      return routeTab(routes.admin(), 'Admin', routes.admin.under().active);
    }
  }

  function reportTab() {
    var currentDocument = model.currentDocument();

    if (currentDocument) {
      if (routes.authoring.under().active) {
        var href = routes.report({documentId: currentDocument.id}).href;
        return h('a.ui.button.enote', {href: href, title: currentDocument.name}, 'eNOTE');
      } else {
        var route = routes.report({documentId: currentDocument.id});
        return route.link({class: {ui: true, button: true, active: route.active, enote: true}}, 'eNOTE');
      }
    }
  }

  return h('div.buttons',
    model.user
      ? [
        routeTab(routes.root(), 'Home', routes.root().active),
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
    'LEXeNOTES is  the registered trademark of Lexeme Technologies LLC.',
    h('br'),
    'Copyright 2015 Lexeme Technologies LLC. All rights protected. US Patent #8,706,680.',
    h('span.release-time', 'Released: ' + new Date(model.releaseTime))
  );
}

var listenToHttpErrors = _.once(function (model) {
  http.onError(h.refreshify(function (error) {
    if (!error.aborted) {
      var errorMessage = error.statusText + (
        error.responseJSON && error.responseJSON.message
        ? ': ' + error.responseJSON.message
        : error.responseText
          ? ': ' + error.responseText
          : ''
      );

      model.flash = {message: 'Network Error', detail: errorMessage};
      return wait(3000).then(function () {
        delete model.flash;
      });
    }
  }));

  http.onInactivity = function () {
    http.post('/logout').then(function () {
      window.location = routes.login({inactive: true}).href;
    });
  };
});
