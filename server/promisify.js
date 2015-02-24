var Promise = require('bluebird');

module.exports = function(fn) {
  return new Promise(function(fulfill, reject) {
    fn(function(error, result) {
      if (error) {
        reject(error);
      } else {
        fulfill(result);
      }
    });
  });
};
