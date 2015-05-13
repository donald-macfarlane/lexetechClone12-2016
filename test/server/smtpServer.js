var SMTPServer = require('smtp-server').SMTPServer;
var MailParser = require('mailparser').MailParser;
var promisify = require('../../server/promisify');

module.exports = function (options) {
  var port = options && options.hasOwnProperty('port') && options.port !== undefined? options.port: 34567;

  var server = new SMTPServer({
    hideSTARTTLS: true,
    disabledCommands: ['AUTH'],
    logger: false,
    onData: function (stream, session, cb) {
      var mailparser = new MailParser();
      mailparser.on('end', function (email) {
        if (options.emailReceived) {
          options.emailReceived(email);
        }
        cb();
      });
      stream.pipe(mailparser);
    }
  });
  server.listen(port);

  return {
    stop: function () {
      return promisify(function (cb) {
        server.close(cb);
      });
    },
    url: 'smtp://localhost:' + port
  };
};
