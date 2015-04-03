var plastiqRouter = require('plastiq-router');
var router = plastiqRouter();

router.login = router.route('/login', {
  onarrive: function (model) {
    model.login = true;
  },
  onleave: function (model) {
    delete model.login;
  }
});

router.signup = router.route('/signup', {
  onarrive: function (model) {
    model.signup = true;
  },
  onleave: function (model) {
    delete model.signup;
  }
});

router.report = router.route('/report/:documentId', {
  onarrive: function (model, params, document) {
    model.documentId = params.documentId;
    if (document) {
      model.openDocument(model.documentsApi.document(document));
    } else {
      model.openDocumentById(model.documentId).then(function () {
        model.refresh();
      });
    }
  },
  onleave: function (model) {
    delete model.documentId;
    delete model.document;
  }
});

router.root = router.route('/');

module.exports = router;
