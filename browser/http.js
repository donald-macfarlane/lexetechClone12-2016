var jquery = require("./jquery");
var Promise = require('bluebird');
var _ = require('underscore');
var qs = require('qs');

function send(method, url, body, options) {
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

['get', 'delete'].forEach(function (method) {
  module.exports[method] = function (url, options) {
    return send(method.toUpperCase(), urlWithParams(url, options), undefined, options);
  };
});

['put', 'post'].forEach(function (method) {
  module.exports[method] = function (url, body, options) {
    return send(method.toUpperCase(), urlWithParams(url, options), body, options);
  };
});

module.exports.onError = function(fn) {
  jquery(document).ajaxError(fn);
}
