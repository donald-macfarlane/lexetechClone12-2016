var plastiqRouter = require('plastiq-router');
var router = plastiqRouter();

router.login = router.route('/login', {
  onarrive: function (model) {
    if (!model.user) {
      model.login = true;
    }
  },
  onleave: function (model) {
    delete model.login;
  }
});

router.signup = router.route('/signup', {
  onarrive: function (model) {
    if (!model.user) {
      model.signup = true;
    }
  },
  onleave: function (model) {
    delete model.signup;
  }
});

function ensureLoggedIn(model, fn) {
  if (model.user) {
    if (fn) {
      return fn();
    }
  } else {
    model.login = true;
  }
}

router.report = router.route('/reports/:documentId', {
  onarrive: function (model, params, document) {
    ensureLoggedIn(model, function () {
      model.documentId = params.documentId;
      if (document) {
        model.openDocument(model.documentApi.document(document));
      } else {
        model.openDocumentById(model.documentId).then(function () {
          model.refresh();
        });
      }
    });
  },
  onleave: function (model) {
    delete model.documentId;
    delete model.document;
    delete model.report;
  }
});

router.root = router.route('/', {
  onarrive: function (model) {
    ensureLoggedIn(model);
  }
});

module.exports = router;
