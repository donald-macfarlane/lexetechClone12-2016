var redisPromise = require('then-redis');
var redis = require('redis');
var urlUtils = require('url');

module.exports = function redisClient(options) {
  var url = process.env.REDISCLOUD_URL;

  var createClient =
    options && options.promises
      ? function (options) {
          return redisPromise.createClient(options);
        }
      : function (options) {
          if (options) {
            return redis.createClient(options.host, options.port, options);
          } else {
            return redis.createClient();
          }
        };

  if (url) {
    var redisUrl = urlUtils.parse(url);

    var client = createClient({
        port: redisUrl.port,
        host: redisUrl.hostname,
        no_ready_check: true
    });

    client.auth(redisUrl.auth.split(":")[1]);

    return client;
  } else {
    return createClient();
  }
};
