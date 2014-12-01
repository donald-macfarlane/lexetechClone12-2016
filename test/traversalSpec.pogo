lexiconJSON = require '../browser/lexicon.json'
expect = require 'chai'.expect
traversal = require '../browser/traversal'

describe 'traversal'
  it 'asks questions in order'
    q1 = traversal (lexiconJSON)
    expect(q1.text).to.equal 'What hurts?'
    q2 = q1.respond 'right arm'
    expect(q2.text).to.equal 'Is it bleeding?'
    q3 = q2.respond 'yes'
    expect(q3.text).to.equal 'Is it aching?'
    q4 = q3.respond 'no'
    expect(q4.text).to.equal 'Prescribe dressing'

  it "throws if given a response that doesn't exist"
    q1 = traversal (lexiconJSON)
    expect(q1.text).to.equal 'What hurts?'
    expect @{ q1.respond 'no such response' }.to.throw 'no such response'
