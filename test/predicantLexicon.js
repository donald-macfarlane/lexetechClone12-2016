var lexiconBuilder = require('./lexiconBuilder');

module.exports = function(predicant) {
  var lexicon = lexiconBuilder();
  return lexicon.queries([
    {
      name: 'query1',
      text: 'All Users Query',

      responses: [
        {
          id: '1',
          text: 'User',
        }
      ]
    },
    {
      name: 'query2',
      text: 'User Query',
      predicants: [predicant],

      responses: [
        {
          id: '1',
          text: 'Finished',
        }
      ]
    }
  ]);
};
