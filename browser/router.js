var plastiqRouter = require('plastiq-router');
var router = plastiqRouter();
var documentApi = 

router.login = router.route('/login', {
  to: function (model) {
    model.login = true;
  },
  from: function (model) {
    delete model.login;
  }
});

router.signup = router.route('/signup', {
  to: function (model) {
    model.login = true;
  },
  from: function (model) {
    delete model.login;
  }
});

router.report = router.route('/report/:documentId', {
  to: function (model, params, document) {
    model.documentId = params.documentId;
    if (document) {
      model.openDocument(model.documentsApi.document(document));
    } else {
      model.openDocumentById(model.documentId).then(function () {
        model.refresh();
      });
    }
  },
  from: function (model) {
    delete model.documentId;
    delete model.document;
  }
});

router.root = router.route('/');

module.exports = router;
