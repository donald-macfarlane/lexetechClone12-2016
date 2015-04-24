var jquery = require("./jquery");
var Promise = require('bluebird');
var _ = require('underscore');

function send(method, url, body, options) {
  return Promise.resolve(jquery.ajax(_.extend({
    url: url,
    type: method,
    contentType: "application/json; charset=UTF-8",
    data: body? JSON.stringify(body): undefined
  }, options)));
}

['get', 'delete'].forEach(function (method) {
  module.exports[method] = function (url, options) {
    return send(method.toUpperCase(), url, undefined, options);
  };
});

['put', 'post'].forEach(function (method) {
  module.exports[method] = function (url, body, options) {
    return send(method.toUpperCase(), url, body, options);
  };
});

module.exports.onError = function(fn) {
  jquery(document).ajaxError(fn);
}
