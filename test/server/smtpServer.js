var SMTPServer = require('smtp-server').SMTPServer;
var MailParser = require('mailparser').MailParser;
var promisify = require('../../server/promisify');
var debug = require('debug')('smtp-server');

module.exports = function (options) {
  var port = options && options.hasOwnProperty('port') && options.port !== undefined? options.port: 34567;

  var emails = [];

  var server = new SMTPServer({
    hideSTARTTLS: true,
    disabledCommands: ['AUTH'],
    logger: false,
    onData: function (stream, session, cb) {
      var mailparser = new MailParser();
      mailparser.on('end', function (email) {
        debug('email received', email);

        emails.push(email);

        if (options && options.emailReceived) {
          options.emailReceived(email);
        }

        cb();
      });
      stream.pipe(mailparser);
    }
  });

  return promisify(function (cb) {
    server.listen(port, cb);
  }).then(function () {
    return {
      stop: function () {
        return promisify(function (cb) {
          server.close(cb);
        });
      },
      emails: emails,
      url: 'smtp://localhost:' + port,

      clear: function () {
        this.emails.length = 0;
      }
    };
  });
};
