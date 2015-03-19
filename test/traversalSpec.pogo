expect = require 'chai'.expect
traversal = require './traversal'

describe 'traversal'
  query = {
    text = 'What hurts?'
    responses [
      {
        text = 'right arm'
        query = {
          text = 'Is it bleeding?'
          
          responses = [
            {
              text = 'yes'

              query = {
                text = 'Is it aching?'
              }
            }
            {
              text = 'no'
            }
          ]
        }
      }
      {
        text = 'left arm'
      }
    ]
  }

  it 'asks questions in order'
    q1 = traversal (query)
    expect(q1.text).to.equal 'What hurts?'
    q2 = q1.respond 'right arm'
    expect(q2.text).to.equal 'Is it bleeding?'
    q3 = q2.respond 'yes'
    expect(q3.text).to.equal 'Is it aching?'

  it "throws if given a response that doesn't exist"
    q1 = traversal (query)
    expect(q1.text).to.equal 'What hurts?'
    expect @{ q1.respond 'no such response' }.to.throw 'no such response'
