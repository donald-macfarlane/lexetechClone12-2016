var lexiconBuilder = require('./lexiconBuilder');

module.exports = function() {
  var lexicon = lexiconBuilder();
  return lexicon.blocks([
    {
      id: "1",
      name: "block 1",

      queries: [
        {
          name: 'query1',
          text: 'Heading',

          responses: [
            {
              id: '1',
              text: 'One',

              actions: [
                { name: 'suppressPunctuation' }
              ],

              styles: {
                style1: 'Heading One'
              }
            }
          ]
        },
        {
          name: 'query2',
          text: 'Sentence',

          responses: [
            {
              id: '1',
              text: 'One',

              styles: {
                style1: '. This is the beginning of a sentence'
              }
            }
          ]
        }
      ]
    }
  ]);
};
