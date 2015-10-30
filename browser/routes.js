var router = require('plastiq-router');

module.exports = {
  login:                router.route('/login'),
  signup:               router.route('/signup'),
  forgotPassword:       router.route('/forgotpassword'),
  enote:                router.route('/enotes/:documentId'),
  printEnote:           router.route('/enotes/:documentId/print/:style'),
  root:                 router.route('/'),
  admin:                router.route('/admin'),
  adminUser:            router.route('/admin/users/:userId'),
  resetPassword:        router.route('/resetpassword/:token'),
  inactive:             router.route('/inactive'),
  authoring:            router.route('/authoring'),
  authoringCreateBlock: router.route('/authoring/blocks/create'),
  authoringBlock:       router.route('/authoring/blocks/:blockId'),
  authoringCreateQuery: router.route('/authoring/blocks/:blockId/queries/create'),
  authoringQuery:       router.route('/authoring/blocks/:blockId/queries/:queryId'),
  authoringPredicants:  router.route('/authoring/predicants'),
  authoringCreatePredicant:   router.route('/authoring/predicants/create'),
  authoringPredicant:   router.route('/authoring/predicants/:predicantId')
};
