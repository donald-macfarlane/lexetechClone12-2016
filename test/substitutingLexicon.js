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
          text: 'Patient gender',

          responses: [
            {
              id: '1',
              text: 'Male',

              actions: [
                {name: 'setVariable', arguments: ['His', 'His']},
                {name: 'setVariable', arguments: ['He', 'He']},
                {name: 'setVariable', arguments: ['his', 'his']},
                {name: 'setVariable', arguments: ['he', 'he']}
              ],
            },
            {
              id: '2',
              text: 'Female',

              actions: [
                {name: 'setVariable', arguments: ['His', 'Her']},
                {name: 'setVariable', arguments: ['He', 'She']},
                {name: 'setVariable', arguments: ['his', 'her']},
                {name: 'setVariable', arguments: ['he', 'she']}
              ],
            }
          ]
        },
        {
          name: 'query2',
          text: 'Where does it hurt?',

          responses: [
            {
              id: '1',
              text: 'left leg',

              actions: [
                {name: 'setVariable', arguments: ['leg', 'left']}
              ],
            },
            {
              id: '2',
              text: 'right leg',

              actions: [
                {name: 'setVariable', arguments: ['leg', 'right']}
              ],
            }
          ]
        },
        {
          name: 'query3',
          text: 'Is it bleeding?',

          responses: [
            {
              id: '1',
              text: 'yes',

              styles: {
                style1: '!He complains that !his !leg leg is bleeding',
                style2: ', bleed'
              }
            }
          ]
        }
      ]
    }
  ]);
};
