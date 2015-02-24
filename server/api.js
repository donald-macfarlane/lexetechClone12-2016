var Promise = require("bluebird");
var express = require("express");
var _ = require("underscore");
var githubContent = require("./githubContent");
var app = express();

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

app.use(function(req, res, next) {
  if (req.method === "PUT" || req.method === "POST" || req.method === "DELETE") {
    var backupHttpism = app.get("backupHttpism");

    if (backupHttpism) {
      delayBackup(app.get("backupDelay"))(app.get("db"), backupHttpism);
    }

    return next();
  } else {
    return next();
  }
});

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

app.post("/blocks/:id", function(req, res) {
  var db = app.get("db");

  db.updateBlockById(req.params.id, req.body).then(function(block) {
    res.send(block);
  });
});

app.get("/blocks/:id/queries", function(req, res) {
  var db = app.get("db");

  db.blockQueries(req.params.id).then(function(queries) {
    res.send(queries);
  });
});

app.get("/blocks/:blockId/queries/:queryId", function(req, res) {
  var db = app.get("db");
  db.queryById(req.params.queryId).then(function(query) {
    if (query) {
      res.send(query);
    } else {
      res.status(404).send({});
    }
  });
});

app.post("/blocks/:blockId/queries/:queryId", function(req, res) {
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
});

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

app.post("/user/documents", function(req, res) {
  var db = app.get("db");

  db.createDocument(req.user.id, req.body).then(function(document) {
    res.set("location", req.baseUrl + "/user/documents/" + document.id);
    res.send(document);
  });
});

app.post("/user/documents/:id", function(req, res) {
  var db = app.get("db");
  db.writeDocument(req.user.id, req.params.id, req.body).then(function() {
    res.send({});
  });
});

app.get("/user/documents/:id", function(req, res) {
  var db = app.get("db");
  db.readDocument(req.user.id, req.params.id).then(function(doc) {
    if (doc) {
      res.send(doc);
    } else {
      res.status(404).send({
        message: "no such document"
      });
    }
  });
});

module.exports = app;
