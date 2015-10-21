module.exports = function (req) {
  return process.env.BASEURL || (req.headers['x-forwarded-proto'] || req.protocol) + '://' + req.get('host') + '/';
}
