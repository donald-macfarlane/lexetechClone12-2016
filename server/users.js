var promisify = require('./promisify');
var Promise = require("bluebird");

var User = require("./models/user");
var authenticate = User.authenticate();

exports.deleteAll = function() {
  return promisify(function(cb) {
    User.remove({}, cb);
  });
};

exports.authenticate = function(email, password) {
  return new Promise(function(success, failure) {
    return authenticate(email, password, function(err, result, otherStuff) {
      if (result) {
        success(result);
      } else {
        failure(otherStuff);
      }
    });
  });
};

exports.signUp = function(email, password) {
  return promisify(function(cb) {
    return User.register(new User({
      email: email
    }), password, cb);
  }).then(function(user) {
    user.id = user._id;
    delete user._id;
    return user;
  });
};
