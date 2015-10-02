var Promise = require("bluebird");
var express = require("express");
var _ = require("underscore");
var githubContent = require("./githubContent");
var app = express();
var mongoDb = require('./mongoDb');
var errorhandler = require('errorhandler');
var debug = require('debug')('lexenotes:api');
var handleErrors = require('./handleErrors');
var styleChangeNotifier = require('./styleChangeNotifier');

function backup(redisDb, backupHttpism) {
  var github = githubContent(backupHttpism);

  return redisDb.getLexicon().then(function (lexicon) {
    return github.put("lexicon.json", JSON.stringify(lexicon, void 0, 2)).then(function () {
      debug("backed up lexicon");
    });
  }).then(void 0, function(e) {
    debug("could not backup lexicon", e);
  });
}

var delayBackupsByWait = {};

function delayBackup(wait) {
  if (delayBackupsByWait[wait]) {
    return delayBackupsByWait[wait];
  } else {
    return delayBackupsByWait[wait] = _.debounce(backup, wait);
  }
}

function methodIsWrite(method) {
  return method === 'PUT' || method === 'POST' || method === 'DELETE' || method == 'PATCH';
}

app.use('/user', function (req, res, next) {
  req.isUserRoute = true;
  next();
});

app.use('/users', function (req, res, next) {
  req.isUsersRoute = true;
  next();
});

app.use('/', function (req, res, next) {
  if (methodIsWrite(req.method) && !req.user.author && !req.isUsersRoute && !req.isUserRoute) {
    res.status(403).send({message: 'not authorised'});
  } else {
    next();
  }
});

app.use('/', function(req, res, next) {
  if (methodIsWrite(req.method)) {
    var backupHttpism = app.get('backupHttpism');

    if (backupHttpism) {
      delayBackup(app.get('backupDelay'))(app.get('db'), backupHttpism);
    }

    return next();
  } else {
    return next();
  }
});

app.get("/blocks", function(req, res) {
  var db = app.get("db");

  db.listBlocks().then(function(blocks) {
    blocks.forEach(function (block) { outgoingBlock(req, block); });
    res.send(blocks);
  });
});

app.post("/blocks", function(req, res) {
  var db = app.get("db");

  db.createBlock(req.body).then(function(block) {
    res.set("location", req.baseUrl + "/blocks/" + block.id);
    outgoingBlock(req, block);
    res.status(201).send(block);
  });
});

function outgoingBlock(req, block) {
  block.href = req.baseUrl + "/blocks/" + block.id;
  return block;
}

function outgoingQuery(req, query, options) {
  if (options && options.clipboard) {
    query.href = req.baseUrl + '/user/queries/' + query.id;
  } else {
    query.href = req.baseUrl + '/queries/' + query.id;
  }
  return query;
}

function incomingQuery(query) {
  delete query.href;
}

function outgoingPredicant(req, predicant) {
  predicant.href = req.baseUrl + '/predicants/' + predicant.id;
}

app.get("/blocks/:id", function(req, res) {
  var db = app.get("db");

  db.blockById(req.params.id).then(function(block) {
    outgoingBlock(req, block);
    res.send(block);
  });
});

function putBlock(req, res) {
  var db = app.get("db");

  db.updateBlockById(req.params.id, req.body).then(function(block) {
    res.send(block);
  });
}

app.post("/blocks/:id", putBlock);
app.put("/blocks/:id", putBlock);

app.get("/blocks/:id/queries", function(req, res) {
  var db = app.get("db");

  db.blockQueries(req.params.id).then(function(queries) {
    res.send(queries.map(function (q) {
      return outgoingQuery(req, q);
    }));
  });
});

function getQuery(req, res) {
  var db = app.get("db");
  db.queryById(req.params.queryId).then(function(query) {
    if (query) {
      res.send(query);
    } else {
      res.status(404).send({});
    }
  });
}

app.get("/blocks/:blockId/queries/:queryId", getQuery);
app.get("/queries/:queryId", getQuery);

function putQuery(req, res) {
  var db = app.get("db");
  var query = req.body;

  if (query.after) {
    db.moveQueryAfter(req.params.blockId, req.params.queryId, query.after).then(function(query) {
      res.send(query);
    });
  } else {
    if (query.before) {
      db.moveQueryBefore(req.params.blockId, req.params.queryId, query.before).then(function(query) {
        res.send(query);
      });
    } else {
      db.updateQuery(req.params.queryId, query).then(function(query) {
        res.send(query);
      });
    }
  }
}

app.post("/blocks/:blockId/queries/:queryId", putQuery);
app.put("/blocks/:blockId/queries/:queryId", putQuery);

app.delete("/blocks/:blockId/queries/:queryId", function(req, res) {
  var db = app.get("db");

  db.deleteQuery(req.params.blockId, req.params.queryId).then(function() {
    res.status(204).send({});
  });
});

app.post("/blocks/:blockId/queries", function(req, res) {
  var db = app.get("db");

  function addQuery(query) {
    if (query.before) {
      var before = query.before;
      delete query.before;
      return db.insertQueryBefore(req.params.blockId, before, query);
    } else {
      if (query.after) {
        var after = query.after;
        delete query.after;
        return db.insertQueryAfter(req.params.blockId, after, query);
      } else {
        return db.addQuery(req.params.blockId, query);
      }
    }
  }

  return addQuery(req.body).then(function (query) {
    res.send(outgoingQuery(req, query));
  });
});

app.post("/lexicon", function(req, res) {
  var db = app.get("db");

  db.setLexicon(req.body).then(function() {
    res.status(201).send({});
  });
});

app.get("/lexicon", function(req, res) {
  var db = app.get("db");

  db.getLexicon(req.body).then(function(lexicon) {
    res.send(lexicon);
  });
});

app.get("/predicants", function(req, res) {
  var db = app.get("db");

  db.predicants().then(function(predicants) {
    predicants.forEach(function (predicant) {
      outgoingPredicant(req, predicant);
    });
    var predicantsById = _.indexBy(predicants, "id");
    res.send(predicantsById);
  });
});

app.post("/predicants", handleErrors(function(req, res) {
  var db = app.get("db");

  var added = req.body instanceof Array
    ? db.addPredicants(req.body)
    : db.addPredicant(req.body)

  return added.then(function(result) {
    if (result instanceof Array) {
      result.forEach(function (p) {
        outgoingPredicant(req, p);
      });
    } else {
      outgoingPredicant(req, result);
    }
    res.status(201).send(result);
  });
}));

app.put('/predicants/:id', handleErrors(function (req, res) {
  var db = app.get('db');

  return db.updatePredicantById(req.params.id, req.body).then(function () {
    res.send(req.body);
  });
}));

app.get('/predicants/:id', handleErrors(function (req, res) {
  var db = app.get('db');

  return db.predicantById(req.params.id).then(function (predicant) {
    outgoingPredicant(req, predicant);
    res.send(predicant);
  });
}));

app.get('/predicants/:id/usages', handleErrors(function (req, res) {
  var db = app.get('db');

  return db.usagesForPredicant(req.params.id).then(function (usages) {
    usages.queries.forEach(function (query) {
      outgoingQuery(req, query);
    });
    usages.responses.forEach(function (response) {
      outgoingQuery(req, response.query);
    });
    res.send(usages);
  });
}));

app.delete("/predicants", function(req, res) {
  var db = app.get("db");

  db.removeAllPredicants().then(function() {
    res.status(204).send({});
  });
});

app.delete("/predicants/:id", function(req, res) {
  var db = app.get("db");

  db.removePredicantById(req.params.id).then(function() {
    res.status(204).send({});
  });
});

function outgoingUser(user, req) {
  if (user._id) {
    user.id = user._id;
  }
  user.hasPassword = !!user.hash;
  delete user._id;
  delete user.salt;
  delete user.hash;
  user.href = req.baseUrl + "/users/" + user.id;
  user.resetPasswordTokenHref = req.baseUrl + '/users/' + user.id + '/resetpasswordtoken';
  user.resetPasswordHref = req.baseUrl + '/users/resetpassword';
  return user;
}

function incomingUser(user) {
  if (user.id) {
    user._id = user.id;
  }
  delete user.hasPassword;
  delete user.id;
  delete user.href;
  return user;
}

app.use('/users', function (req, res, next) {
  if (req.user.admin) {
    return next();
  } else {
    res.status(403).send({message: 'not authorised'});
  }
});

function handleEmailAlreadyExists(req, res, error) {
  if (error.code == 11000) {
    res.status(400).send({
      alreadyExists: true,
      message: 'user with email address <' + req.body.email + '> already exists'
    });
  } else {
    throw error;
  }
}

app.post('/users', handleErrors(function (req, res) {
  return mongoDb.addUser(req.body).then(function (user) {
    res.send(outgoingUser(user, req));
  }, function (error) {
    handleEmailAlreadyExists(req, res, error);
  });
}));

app.get('/users', handleErrors(function (req, res) {
  return mongoDb.allUsers({max: Number(req.query.max)}).then(function(u) {
    var users = u.map(function (user) {
      return outgoingUser(user, req);
    });

    res.send(users);
  }).then(undefined, function (error) {
    res.status(500).send({message: error.message});
  });
}));

app.get('/users/search', handleErrors(function (req, res) {
  return mongoDb.searchUsers(req.query.q).then(function (users) {
    var users = users.map(function (user) {
      return outgoingUser(user, req);
    });
    res.send(users);
  }).then(undefined, function (error) {
    res.status(500).send({message: error.message});
  });
}));

app.get('/users/:userId', handleErrors(function (req, res) {
  return mongoDb.user(req.params.userId).then(function (user) {
    if (user) {
      res.send(outgoingUser(user, req));
    } else {
      res.status(404).send({message: 'no user with id: ' + req.params.userId});
    }
  });
}));

app.post('/users/:userId/resetpasswordtoken', handleErrors(function (req, res) {
  return mongoDb.resetPasswordToken(req.params.userId).then(function (token) {
    res.send({token: token});
  }, function (error) {
    if (error.alreadyHasPassword) {
      res.status(400).send({message: 'already has password'});
    } else {
      throw error;
    }
  });
}));

app.post('/users/resetpassword', handleErrors(function (req, res) {
  return mongoDb.setPassword(req.body.token, req.body.password).then(function () {
    res.send({});
  }, function (error) {
    if (error.wrongToken) {
      res.status(400).send({message: 'wrong token'});
    } else {
      throw error;
    }
  });
}));

app.put('/users/:userId', handleErrors(function (req, res) {
  return mongoDb.updateUser(req.params.userId, incomingUser(req.body)).then(function () {
    res.send(outgoingUser(req.body, req));
  }, function (error) {
    handleEmailAlreadyExists(req, res, error);
  });
}));

app.delete('/users/:userId', handleErrors(function (req, res) {
  return mongoDb.deleteUser(req.params.userId).then(function () {
    res.status(204).send({});
  });
}));

app.post("/user/queries", handleErrors(function(req, res) {
  var db = app.get("db");
  var query = req.body;

  return db.addQueryToUser(req.user.id, query).then(function(q) {
    res.send(outgoingQuery(req, q, {clipboard: true}));
  });
}));

app.get("/user/queries", handleErrors(function(req, res) {
  var db = app.get("db");
  var query = req.body;

  return db.userQueries(req.user.id, query).then(function(queries) {
    res.send(queries.map(function (q) {
      return outgoingQuery(req, q, {clipboard: true});
    }));
  });
}));

app.delete("/user/queries/:queryId", function(req, res) {
  var db = app.get("db");
  var query = req.body;

  db.deleteUserQuery(req.user.id, req.params.queryId).then(function() {
    res.status(204).send({});
  });
});

function incomingDocument(document) {
  if (document.id) {
    document._id = document.id;
  }
  delete document.id;
  delete document.href;
  document.lastModified = new Date().toISOString();
}

function outgoingDocument(document, req) {
  delete document.userId;
  addDocumentHref(document, req);
}

function addDocumentHref(document, req) {
  document.href = req.baseUrl + "/user/documents/" + document.id;
  return document;
}

app.post("/user/documents", handleErrors(function(req, res) {
  var doc = req.body;
  incomingDocument(doc);
  doc.created = doc.lastModified;
  return mongoDb.createDocument(req.user.id, doc).then(function(document) {
    return mongoDb.limitDocuments(req.user.id, 5).then(function () {
      outgoingDocument(document, req);
      res.set("location", document.href);
      res.send(document);
      return createStyleChangeNotifier(req).notifyOnStyleChange(document);
    });
  });
}));

app.delete('/user/documents/:id', handleErrors(function (req, res) {
  return mongoDb.deleteDocument(req.user.id, req.params.id).then(function (result) {
    if (result) {
      res.status(204).send({});
    } else {
      res.status(404).send({});
    }
  });
}));

app.get('/user/documents', function (req, res) {
  mongoDb.documents(req.user.id).then(function (docs) {
    docs.forEach(function (doc) {
      outgoingDocument(doc, req);
    });
    res.send(docs);
  });
});

function createStyleChangeNotifier(req) {
  return styleChangeNotifier({
    smtpUrl: app.get('smtp url'),
    systemEmail: app.get('system email'),
    adminEmail: app.get('admin email'),
    db: app.get('db'),
    user: req.user
  });
}

function putDocument(req, res) {
  var document = req.body;
  incomingDocument(document);
  mongoDb.readDocument(req.user.id, req.params.id).then(function (originalDocument) {
    return mongoDb.writeDocument(req.user.id, req.params.id, document).then(function() {
      outgoingDocument(document, req);
      res.send(document);
      return createStyleChangeNotifier(req).notifyOnStyleChange(document, originalDocument);
    });
  });
}

app.post("/user/documents/:id", putDocument);
app.put("/user/documents/:id", putDocument);

app.get("/user/documents/current", function(req, res) {
  mongoDb.currentDocument(req.user.id).then(function(doc) {
    if (doc) {
      outgoingDocument(doc, req);
      res.send(doc);
    } else {
      res.status(404).send({
        message: "no such document"
      });
    }
  });
});

app.get("/user/documents/:id", function(req, res) {
  mongoDb.readDocument(req.user.id, req.params.id).then(function(doc) {
    if (doc) {
      outgoingDocument(doc, req);
      res.send(doc);
    } else {
      res.status(404).send({
        message: "no such document"
      });
    }
  });
});

module.exports = app;
