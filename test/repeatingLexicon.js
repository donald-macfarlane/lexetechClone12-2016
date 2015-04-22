var lexiconBuilder = require('./lexiconBuilder');

module.exports = function simpleLexicon() {
  var lexicon = lexiconBuilder();
  return lexicon.blocks([
    {
      id: '1',
      name: 'one',

      queries: [
        {
          name: 'One',
          text: 'One',

          responses: [
            {
              id: '1',
              text: 'A',

              actions: [
                {
                  name: 'repeatLexeme',
                  arguments: []
                }
              ]
            },
            {
              id: '2',
              text: 'B',

              actions: [
                {
                  name: 'repeatLexeme',
                  arguments: []
                }
              ]
            },
            {
              id: '3',
              text: 'C',

              actions: [
                {
                  name: 'repeatLexeme',
                  arguments: []
                }
              ]
            },
            {
              id: '4',
              text: 'D',

              actions: [
                {
                  name: 'repeatLexeme',
                  arguments: []
                }
              ]
            },
            {
              id: '5',
              text: 'No More'
            }
          ]
        }
      ]
    }
  ]);
};
