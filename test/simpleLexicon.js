var lexiconBuilder = require('./lexiconBuilder');

module.exports = function simpleLexicon() {
  var lexicon = lexiconBuilder();
  return lexicon.blocks([
    {
      id: "1",
      name: "block 1",

      queries: [
        {
          name: 'query1',
          text: 'Where does it hurt?',

          responses: [
            {
              id: '1',
              text: 'left leg',

              styles: {
                style1: 'Complaint\n---------\nleft leg '
              }
            },
            {
              id: '2',
              text: 'right leg',

              styles: {
                style1: 'Complaint\n---------\nright leg '
              }
            }
          ]
        },
        {
          name: 'query2',
          text: 'Is it bleeding?',

          responses: [
            {
              id: '1',
              text: 'yes',

              styles: {
                style1: 'bleeding'
              }
            }
          ]
        },
        {
          name: 'query3',
          text: 'Is it aching?',

          responses: [
            {
              id: '1',
              text: 'yes',

              styles: {
                style1: ', aching'
              }
            }
          ]
        }
      ]
    }
  ]);
};
