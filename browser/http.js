var inactivityTimeout = require('../server/inactivityTimeout');
var httpism = require('httpism');

var http = httpism.api([
  function (req, next) {
    timer.start();

    return next().then(undefined, function (error) {
      errorHandler(error);
    });
  }
]);

var errorHandler;

http.onError = function (handler) {
  errorHandler = handler;
};

var timer = makeTimer(function () {
  http.onInactivity();
}, inactivityTimeout.timeout - 2000);

function makeTimer(callback, duration) {
  var timeout;

  return {
    start: function () {
      if (timeout !== undefined) {
        clearTimeout(timeout);
      }

      var self = this;
      timeout = setTimeout(function () {
        callback();
      }, duration);
    }
  };
}

module.exports = http;
