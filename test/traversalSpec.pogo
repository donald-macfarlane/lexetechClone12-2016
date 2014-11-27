lexiconJSON = require './lexicon.json'
expect = require 'chai'.expect

startTraversal (graph, block) =
  {
    text = 'What hurts?'
  }

describe 'traversal'
  it 'asks questions in order'
    q1 = startTraversal(lexiconJSON, '100')
    expect(q1.text).to.equal('What hurts?')
    q2 = q1.respond('right arm')
    expect(q2.text).to.equal('Is it bleeding?')
    q3 = q2.respond('yes')
    expect(q3.text).to.equal('Is it aching?')
    q4 = q3.respond('no')
    expect(q4.text).to.equal('Prescribe dressing')
