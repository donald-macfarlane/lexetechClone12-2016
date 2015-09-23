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
var documentsComponent = require('./documentsComponent');
var adminComponent = require('./adminComponent');
var authoringComponent = require('./routes/authoring/blocks/block');
var http = require('./http');

var rootComponent = prototype({
  constructor: function (pageData) {
    this.user = pageData.user;
    this.flash = pageData.flash;

    if (pageData.user) {
      this.documentApi = documentApi;
      this.admin = adminComponent();

      this.documentsComponent = documentsComponent({
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
      return this.documentApi.document(docId, {showErrors: false}).then(function (doc) {
        self.openDocument(doc);
      }, function (error) {
        if (error.status == 404) {
          self.documentNotFound = true;
        }
      });
    } else {
      self.openDocument(self.document);
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
    this.documentNotFound = false;
    this.document = doc;
    this.setCurrentDocument(doc);
    this.documentId = doc.id;
    this.report = reportComponent({
      user: this.user,
      document: doc,
      queryGraph: this.queryGraph(),
      lexemeApi: this.lexemeApi()
    });
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
      var inactive = routes.inactive(function () {
        return h('h1', 'inactive');
      });

      if (inactive) {
        return inactive;
      }

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

    function refreshDocuments() {
      return self.documentsComponent.loadDocuments();
    }

    return h.component(
      {
        on: function (eventType, handler) {
          return function () {
            http.extendSession();
            return handler.apply(this, arguments);
          }
        }
      },
      function () {
        return layoutComponent(self, whenLoggedIn(function () {
          return [
            routes.report.under(
              {
                documentId: {
                  set: function (docId) {
                    return self.openDocumentById(docId);
                  }
                },
              },
              function () {
                if (self.documentNotFound) {
                  return h('h1.center', "Very sorry! We couldn't find this document.");
                } else if (self.report) {
                  return [
                    routes.report(function () {
                      return self.report.render();
                    }),
                    routes.printReport(function () {
                      return self.report.renderPrint();
                    })
                  ];
                } else {
                  return h('h1.center', 'loading');
                }
              }
            ),
            routes.root({onarrival: refreshDocuments}, function () {
              return self.documentsComponent.render();
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
    );
  }
});

module.exports = rootComponent;
