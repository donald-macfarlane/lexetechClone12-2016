var plastiq = require('plastiq');
var h = plastiq.html;
var reportComponent = require('./reportComponent');
var prototype = require('prote');
var authComponents = require('./authComponents');
var layoutComponent = require('./layoutComponent');
var documentApi = require('./documentApi')();
var routes = require('./routes');
var buildGraph = require('./buildGraph');
var lexemeApi = require('./lexemeApi');
var startReportComponent = require('./startReportComponent');
var throttle = require('plastiq-throttle');
var adminComponent = require('./adminComponent');
var authoringComponent = require('./routes/authoring/blocks/block');

var rootComponent = prototype({
  constructor: function (pageData) {
    this.user = pageData.user;
    this.flash = pageData.flash;

    if (pageData.user) {
      this.documentApi = documentApi;
      this.admin = adminComponent();

      this.startReport = startReportComponent({
        documentApi: documentApi,
        root: {openDocument: this.openDocument.bind(this)},
        user: this.user,
        currentDocument: this.currentDocument.bind(this)
      });
    }
  },

  openDocumentById: function (docId) {
    var self = this;

    if (docId != this.documentId) {
      return this.documentApi.document(docId).then(function (doc) {
        self.openDocument(doc);
      });
    }
  },

  query: function () {
    return this.report && this.report.history.query;
  },

  lexemeApi: function () {
    return this._lexemeApi || (
      this._lexemeApi = lexemeApi()
    );
  },

  queryGraph: function () {
    return this._queryGraph || (
      this._queryGraph = buildGraph({
        startingPredicants: ['H&P', 'any-user', 'user:' + this.user.id],
        lexemeApi: this.lexemeApi(),
        cache: false
      })
    );
  },

  openDocument: function (doc) {
    this.document = doc;
    this.setCurrentDocument(doc);
    this.documentId = doc.id;
    this.report = reportComponent({
      user: this.user,
      document: doc,
      queryGraph: this.queryGraph(),
      lexemeApi: this.lexemeApi()
    });
    routes.report({documentId: doc.id}).push();
  },

  currentDocument: function () {
    var self = this;

    if (!this._loadedCurrentDocument && this.user) {
      this._loadedCurrentDocument = true;

      self.documentApi.currentDocument().then(function (doc) {
        if (!self._currentDocument) {
          self.setCurrentDocument(doc);
          self.refresh();
        }
      });
    }

    return this._currentDocument;
  },

  setCurrentDocument: function (doc) {
    this._currentDocument = doc;
  },

  authoringComponent: function () {
    if (!this._authoringComponent) {
      this._authoringComponent = authoringComponent();
    }

    return this._authoringComponent;
  },

  render: function () {
    var self = this;
    this.refresh = h.refresh;

    function adminAuth(fn) {
      return function () {
        if (self.user.admin) {
          return fn.apply(this, arguments);
        } else {
          return h('h1', "Sorry, you need to be an administrator to see this page.");
        }
      }
    }

    function authorAuth(fn) {
      return function () {
        if (self.user.author) {
          return fn.apply(this, arguments);
        }
      }
    }

    function whenLoggedIn(fn) {
      if (!self.user) {
        var authPage = first([
          routes.signup(authComponents.signup),
          routes.login(authComponents.login),
          routes.resetPassword(function (params) {
            return authComponents.resetPassword(params.token);
          })
        ]);

        if (authPage) {
          return authPage;
        } else {
          routes.login().push();
        }
      }

      return fn();
    }

    function first(array) {
      return array.filter(function (x) { return x; })[0];
    }

    return layoutComponent(self, whenLoggedIn(function () {
      return [
        routes.report(
          {
            documentId: {
              set: function (docId) {
                return self.openDocumentById(docId);
              }
            },
          },
          function (params) {
            if (self.report) {
              return self.report.render();
            } else {
              return h('h1', 'loading');
            }
          }
        ),
        routes.root(function () {
          return self.startReport.render();
        }),
        routes.admin(adminAuth(function () {
          return self.admin.render();
        })),
        routes.adminUser(adminAuth(function (params) {
          return self.admin.render(params.userId);
        })),
        routes.authoring.under(authorAuth(function () {
          return self.authoringComponent().render();
        })),
        routes.resetPassword(function () {
          return h('h1', 'you have already logged in');
        })
      ];
    }));
  }
});

module.exports = rootComponent;
