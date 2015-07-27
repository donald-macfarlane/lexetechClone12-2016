var jquery = require("./jquery");
var Promise = require('bluebird');
var _ = require('underscore');
var qs = require('qs');
var inactivityTimeout = require('../server/inactivityTimeout');

var timer = makeTimer(function () {
  http.onInactivity();
}, inactivityTimeout);

function send(method, url, body, options) {
  timer.start();

  return Promise.resolve(jquery.ajax(_.extend({
    url: url,
    type: method,
    contentType: "application/json; charset=UTF-8",
    data: body? JSON.stringify(body): undefined
  }, options)));
}

function urlWithParams(url, options) {
  if (options && options.params) {
    var u = url + '?' + qs.stringify(options.params);
    delete options.params;
    return u;
  } else {
    return url;
  }
}

var http = {};

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

['get', 'delete'].forEach(function (method) {
  http[method] = function (url, options) {
    return send(method.toUpperCase(), urlWithParams(url, options), undefined, options);
  };
});

['put', 'post'].forEach(function (method) {
  http[method] = function (url, body, options) {
    return send(method.toUpperCase(), urlWithParams(url, options), body, options);
  };
});

http.onError = function(fn) {
  jquery(document).ajaxError(fn);
};

module.exports = http;
