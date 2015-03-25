var plastiq = require('plastiq');
var h = plastiq.html;
var reportComponent = require('./report');
var prototype = require('prote');
var login = require('./login');
var signup = require('./signup');
var layout = require('./layout');
var documentsApi = require('./documentsApi')();
var router = require('./router');

var appComponent = prototype({
  constructor: function (pageData) {
    this.user = pageData.user;
    this.flash = pageData.flash;
    this.documentsApi = documentsApi;
  },

  openDocumentById: function (docId) {
    var self = this;

    return this.documentsApi.document(self.documentId).then(function (doc) {
      self.openDocument(doc);
    });
  },

  openDocument: function (doc) {
    this.document = doc;
    this.documentId = doc.id;
    this.report = reportComponent({user: this.user, document: doc});
  },

  createDocument: function () {
    var self = this;

    return this.documentsApi.create().then(function (doc) {
      self.openDocument(doc);
    });
  },

  render: function () {
    var self = this;
    this.refresh = h.refresh;

    function master(fn) {
      return function() {
        return layout(self, fn.apply(this, arguments));
      };
    }

    return layout(this,
      this.login ?
        router.login(login)
        : this.signup ?
          router.signup(signup)
          : this.documentId ?
            router.report({documentId: this.documentId}, this.document,
              this.report
                ? this.report.render()
                : h('h1', 'loading')
            )
            : h('.app',
                h('.ui.basic.button', {onclick: self.createDocument.bind(self)}, 'Start new document'),
                h('.ui.basic.button', {onclick: self.createDocument.bind(self)}, 'Load previous document')
              )
    );
  }
});

var app = appComponent(window.lexemeData);

plastiq.append(document.body, function () {
  return router.render(app, function () { return app.render(); });
});
