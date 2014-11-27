lexiconJSON = require './lexicon.json'
expect = require 'chai'.expect

createTraversal (graph, block) =
  {
    nextQuery() =
      {
        text = 'What hurts?'
      }
  }

describe 'traversal'
  it 'asks questions in order'
    traversal = createTraversal(lexiconJSON, '100')
    q1 = traversal.nextQuery()
    expect(q1.text).to.equal('What hurts?')
    q2 = traversal.respond('right arm')
    expect(q2.text).to.equal('Is it bleeding?')
    q3 = traversal.respond('yes')
    expect(q3.text).to.equal('Is it aching?')
    q4 = traversal.respond('no')
    expect(q4.text).to.equal('Prescribe dressing')
