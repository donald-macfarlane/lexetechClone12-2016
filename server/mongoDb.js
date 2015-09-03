var mongoose = require("mongoose");
var promisify = require('./promisify');
var Document = require('./models/document');
var User = require('./models/user');
var escapeRegexp = require('escape-regexp');
var crypto = require('crypto');

mongoose.set("debug", process.env.MONGO_DEBUG === "true");

var connected = false;

exports.connect = function() {
  if (!connected) {
    var url = process.env.MONGOLAB_URI || "mongodb://localhost/lexeme";
    mongoose.connect(url);
    connected = true;
  }
};

function objectify(doc) {
  if (doc) {
    var object = doc.toObject();
    object.id = object._id;
    delete object._id;
    delete object.__v;
    return object;
  }
}

exports.writeDocument = function (userId, docId, doc) {
  return Document.update({_id: docId, userId: userId}, {$set: doc}, {overwrite: true}).exec();
};

exports.createDocument = function (userId, doc) {
  doc.userId = userId;
  return new Document(doc).save().then(objectify);
};

exports.limitDocuments = function(userId, limit) {
  return Document.find({userId: userId}).sort('-lastModified').skip(limit).exec().then(function (documents) {
    if (documents.length > 0) {
      var ids = documents.map(function (d) { return d._id; });
      return Document.remove({_id: {$in: ids}});
    }
  });
};

exports.readDocument = function (userId, docId) {
  return Document.findOne({_id: docId, userId: userId}).then(objectify);
};

exports.currentDocument = function (userId) {
  return Document.findOne({userId: userId}).sort('-lastModified').then(objectify);
};

exports.documents = function (userId) {
  return Document.find({userId: userId}).sort('-lastModified').exec().then(function (docs) {
    return docs.map(objectify);
  });
};

exports.deleteDocument = function (userId, docId) {
  return Document.findOneAndRemove({_id: docId, userId: userId}).exec();
};

exports.allUsers = function (options) {
  var max = options && options.max;

  var usersCollection = User.find();

  if (max) {
    usersCollection = usersCollection.limit(max)
  }

  return usersCollection.exec().then(function (users) {
    var u = users.map(objectify);
    return u;
  });
};

exports.addUser = function (user) {
  var password = user.password;
  if (password) {
    delete user.password;
    user.created = Date.now();

    return promisify(function(cb) {
      return User.register(new User(user), password, cb);
    }).then(objectify);
  } else {
    return new User(user).save().then(objectify);
  }
};

exports.user = function (userId) {
  return User.findOne({_id: userId}).then(objectify);
};

exports.updateUser = function (userId, user) {
  var password = user.password;
  return User.update({_id: userId}, {$set: user}, {overwrite: true}).exec().then(function () {
    if (password) {
      return User.findOne({_id: userId}).then(function (user) {
        return promisify(function (cb) {
          user.setPassword(password, cb);
        }).then(function () {
          return user.save();
        });
      });
    }
  });
};

exports.deleteUser = function (userId) {
  return User.findOneAndRemove({_id: userId}).exec();
};

function generateResetPasswordToken() {
  return promisify(function (cb) {
    crypto.randomBytes(20, cb);
  }).then(function (buffer) {
    return buffer.toString('hex');
  });
}

exports.resetPasswordToken = function (userId) {
  return User.findOne({_id: userId}).then(function (user) {
    if (!user.hash) {
      if (!user.resetPasswordToken) {
        return generateResetPasswordToken().then(function (resetPasswordToken) {
          user.resetPasswordToken = resetPasswordToken;
          return user.save().then(function () {
            return resetPasswordToken;
          });
        });
      } else {
        return user.resetPasswordToken;
      }
    } else {
      var error = new Error();
      error.alreadyHasPassword = true;
      throw error;
    }
  });
};

exports.setPassword = function (token, password) {
  return User.findOne({resetPasswordToken: token}).then(function (user) {
    if (user && user.resetPasswordToken) {
      user.resetPasswordToken = undefined;
      return promisify(function (cb) {
        user.setPassword(password, cb);
      }).then(function () {
        return user.save().then(function () {
          user.id = user._id;
          delete user._id;
          return user;
        });
      });
    } else {
      var error = new Error();
      error.wrongToken = true;
      throw error;
    }
  });
};

exports.searchUsers = function (query) {
  var escapedQuery = query.split(/ +/).map(function (q) { return new RegExp(escapeRegexp(q), 'i'); });

  return User.find({$or: [{firstName: {$in: escapedQuery}}, {familyName: {$in: escapedQuery}}, {email: {$in: escapedQuery}}, ]}).sort('created').exec().then(function (users) {
    return users.map(objectify);
  });
};
