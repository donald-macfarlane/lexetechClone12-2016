var lexiconBuilder = require('./lexiconBuilder');

module.exports = function loopingLexicon() {
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
      text: 'query 2, level 2',
      level: 2,

      responses: [
        {
          text: 'response 1 (left)',
          setLevel: 2,
          predicants: ['left']
        },
        {
          text: 'response 2 (right)',
          setLevel: 2,
          predicants: ['right']
        }
      ]
    },
    {
      text: 'query 3, level 2 (left)',
      level: 2,

      responses: [
        {
          text: 'response 1',
          setLevel: 2
        }
      ],

      predicants: ['left']
    },
    {
      text: 'query 4, level 2 (right)',
      level: 2,

      responses: [
        {
          text: 'response 1',
          setLevel: 2
        }
      ],

      predicants: ['right']
    },
    {
      text: 'query 5, level 2',
      level: 2,

      responses: [
        {
          text: 'again',
          setLevel: 2,

          actions: [
            { name: 'loopBack', arguments: [] }
          ]
        },
        {
          text: 'no more',
          setLevel: 2
        }
      ]
    },
    {
      text: 'query 6, level 1',
      level: 1,

      responses: [
        {
          text: 'response 1',
          setLevel: 1
        }
      ]
    },
    {
      text: 'query 7, level 1 (left)',
      level: 1,

      responses: [
        {
          text: 'response 1',
          setLevel: 1
        }
      ],

      predicants: ['left']
    },
    {
      text: 'query 8, level 1 (right)',
      level: 1,

      responses: [
        {
          text: 'response 1',
          setLevel: 1
        }
      ],

      predicants: ['right']
    }
  ]);
};
