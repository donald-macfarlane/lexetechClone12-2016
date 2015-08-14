var urlUtils = require('url');

var baseurl = process.env.BASEURL && urlUtils.parse(process.env.BASEURL);

module.exports = function (req, res, next) {
  if (baseurl) {
    var protocolCorrect = baseurl.protocol == (req.headers['x-forwarded-proto'] + ':');
    var hostCorrect = baseurl.host == req.headers['host'];

    if (!(protocolCorrect && hostCorrect)) {
      res.redirect(urlUtils.resolve(process.env.BASEURL, req.url));
      return;
    }
  }

  next();
}
