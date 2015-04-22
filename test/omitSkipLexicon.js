var lexiconBuilder = require('./lexiconBuilder');

module.exports = function simpleLexicon() {
  var lexicon = lexiconBuilder();
  return lexicon.queries([
    {
      text: 'query 1, level 1',
      level: 1,

      responses: [
        {
          text: 'response 1',
          setLevel: 2
        }
      ]
    },
    {
      text: 'query 2, level 1',
      level: 1,

      responses: [
        {
          text: 'response 1',
          setLevel: 2
        }
      ]
    },
    {
      text: 'query 3, level 2',
      level: 2,

      responses: [
        {
          text: 'response 1',
          setLevel: 2
        }
      ]
    },
    {
      text: 'query 4, level 3',
      level: 3,

      responses: [
        {
          text: 'response 1',
          setLevel: 3
        }
      ]
    },
    {
      text: 'query 5, level 1',
      level: 1,

      responses: [
        {
          text: 'response 1',
          setLevel: 1
        }
      ]
    }
  ]);
};
