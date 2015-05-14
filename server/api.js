var Promise = require("bluebird");
var express = require("express");
var _ = require("underscore");
var githubContent = require("./githubContent");
var app = express();
var mongoDb = require('./mongoDb');
var errorhandler = require('errorhandler');
var sendEmail = require('./sendEmail');
var documentHasChangedStyles = require('./documentHasChangedStyles');

function backup(redisDb, backupHttpism) {
  var github = githubContent(backupHttpism);

  redisDb.getLexicon().then(function (lexicon) {
    return github.put("lexicon.json", JSON.stringify(lexicon, void 0, 2)).then(function () {
      console.log("backed up lexicon");
    });
  }).then(void 0, function(e) {
    console.log("could not backup lexicon");
    console.log(e);
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
    var backupHttpism = app.get("backupHttpism");

    if (backupHttpism) {
      delayBackup(app.get("backupDelay"))(app.get("db"), backupHttpism);
    }

    return next();
  } else {
    return next();
  }
});

function errors(req, res, next) {
  function sendError(error) {
    console.log(error);
    res.status(500).send({message: error.message});
  }

  var result;
  try {
    result = next();
  } catch (error) {
    sendError(error);
  }

  if (result && typeof result.then === 'function') {
    result.then(undefined, sendError);
  }
}

app.use(errorhandler());

app.get("/blocks", function(req, res) {
  var db = app.get("db");

  db.listBlocks().then(function(blocks) {
    res.send(blocks);
  });
});

app.post("/blocks", function(req, res) {
  var db = app.get("db");

  db.createBlock(req.body).then(function(block) {
    res.set("location", req.baseUrl + "/blocks/" + block.id);
    res.status(201).send(block);
  });
});

app.get("/blocks/:id", function(req, res) {
  var db = app.get("db");

  db.blockById(req.params.id).then(function(block) {
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
    res.send(queries);
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
    res.send({});
  });
});

app.post("/blocks/:blockId/queries", function(req, res) {
  var db = app.get("db");
  var query = req.body;

  if (query.before) {
    var before = query.before;
    delete query.before;
    db.insertQueryBefore(req.params.blockId, before, query).then(function(query) {
      res.send(query);
    });
  } else {
    if (query.after) {
      var after = query.after;
      delete query.after;
      db.insertQueryAfter(req.params.blockId, after, query).then(function(query) {
        res.send(query);
      });
    } else {
      db.addQuery(req.params.blockId, query).then(function(query) {
        res.send(query);
      });
    }
  }
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
    res.send(predicants);
  });
});

app.post("/predicants", function(req, res) {
  var db = app.get("db");

  var added = req.body instanceof Array
    ? db.addPredicants(req.body)
    : db.addPredicant(req.body)

  added.then(function() {
    res.status(201).send({});
  });
});

app.delete("/predicants", function(req, res) {
  var db = app.get("db");

  db.removeAllPredicants().then(function() {
    res.status(204).send({});
  });
});

function outgoingUser(user, req) {
  if (user._id) {
    user.id = user._id;
  }
  delete user._id;
  delete user.salt;
  delete user.hash;
  user.href = req.baseUrl + "/users/" + user.id;
  return user;
}

function incomingUser(user) {
  if (user.id) {
    user._id = user.id;
  }
  delete user.id;
  delete user.href;
  return user;
}

app.use('/users', function (req, res, next) {
  if (req.user.admin) {
    next();
  } else {
    res.status(403).send({message: 'not authorised'});
  }
});

app.post('/users', function (req, res) {
  mongoDb.addUser(req.body).then(function (user) {
    res.send(outgoingUser(user, req));
  });
});

app.get('/users', function (req, res) {
  mongoDb.allUsers().then(function(u) {
    var users = u.map(function (user) {
      return outgoingUser(user, req);
    });

    res.send(users);
  }).then(undefined, function (error) {
    res.status(500).send({message: error.message});
  });
});

app.get('/users/search', function (req, res) {
  mongoDb.searchUsers(req.query.q).then(function (users) {
    res.send(
      {
        results: users.map(function (user) {
          outgoingUser(user, req);
          return {
            title: [user.firstName, user.familyName].filter(function (n) { return n; }).join(' '),
            description: user.email,
            id: user.id,
            href: user.href
          };
        })
      }
    );
  }).then(undefined, function (error) {
    res.status(500).send({message: error.message});
  });
});

app.get('/users/:userId', function (req, res) {
  mongoDb.user(req.params.userId).then(function (user) {
    if (user) {
      res.send(outgoingUser(user, req));
    } else {
      res.status(404).send({message: 'no user with id: ' + req.params.userId});
    }
  });
});

app.put('/users/:userId', function (req, res) {
  mongoDb.updateUser(req.params.userId, incomingUser(req.body)).then(function () {
    res.send(outgoingUser(req.body, req));
  });
});

app.post("/user/queries", function(req, res) {
  var db = app.get("db");
  var query = req.body;

  db.addQueryToUser(req.user.id, query).then(function(q) {
    res.send(q);
  });
});

app.get("/user/queries", function(req, res) {
  var db = app.get("db");
  var query = req.body;

  db.userQueries(req.user.id, query).then(function(updatedQuery) {
    res.send(updatedQuery);
  });
});

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

function sendResponseChangedEmail() {
  var smtpUrl = app.get('smtp url');

  if (smtpUrl) {
    return sendEmail(smtpUrl, {
      from: 'Lexetech System <system@lexetech.com>',
      to: 'Lexetech Admin <admin@lexetech.com>',
      subject: 'response change',
      text: 'response was changed'
    });
  }
}

app.post("/user/documents", errors, function(req, res) {
  var doc = req.body;
  incomingDocument(doc);
  doc.created = doc.lastModified;
  return mongoDb.createDocument(req.user.id, doc).then(function(document) {
    outgoingDocument(document, req);
    res.set("location", document.href);
    res.send(document);
    if (documentHasChangedStyles(document)) {
      sendResponseChangedEmail();
    }
  });
});

app.get('/user/documents', function (req, res) {
  mongoDb.documents(req.user.id).then(function (docs) {
    docs.forEach(function (doc) {
      outgoingDocument(doc, req);
    });
    res.send(docs);
  });
});

function putDocument(req, res) {
  var document = req.body;
  incomingDocument(document);
  mongoDb.readDocument(req.user.id, req.params.id).then(function (originalDocument) {
    return mongoDb.writeDocument(req.user.id, req.params.id, document).then(function() {
      outgoingDocument(document, req);
      res.send(document);
      if (documentHasChangedStyles(document, originalDocument)) {
        sendResponseChangedEmail();
      }
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
