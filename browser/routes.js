var router = require('plastiq-router');

router.start();

module.exports = {
  login: router.route('/login'),
  signup: router.route('/signup'),
  report: router.route('/reports/:documentId'),
  root: router.route('/'),
  admin: router.route('/admin'),
  adminUser: router.route('/admin/users/:userId')
};
