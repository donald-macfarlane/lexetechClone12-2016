var router = require('plastiq-router');

module.exports = {
  login: router.route('/login'),
  signup: router.route('/signup'),
  report: router.route('/reports/:documentId'),
  root: router.route('/'),
  admin: router.route('/admin'),
  adminUser: router.route('/admin/users/:userId'),
  resetPassword: router.route('/resetpassword/:token')
};
