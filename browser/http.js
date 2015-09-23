var inactivityTimeout = require('../server/inactivityTimeout');
var httpism = require('httpism');
var _ = require('underscore');

var http = httpism.api([
  function (req, next) {
    timer.start();

    if (req.options.showErrors === false) {
      return next();
    } else {
      return next().then(undefined, function (error) {
        errorHandler(error);
        throw error;
      });
    }
  }
]);

var errorHandler;

http.onError = function (handler) {
  errorHandler = handler;
};

var timer = makeTimer(function () {
  http.onInactivity();
}, inactivityTimeout.timeout - 2000);

http.extendSession = _.throttle(function () {
  timer.start();
  httpism.post('/stayalive');
}, 500, {leading: false});

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
