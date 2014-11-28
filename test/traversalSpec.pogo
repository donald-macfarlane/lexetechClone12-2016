lexiconJSON = require '../app/lexicon.json'
expect = require 'chai'.expect

traversalState (graph, query) =
  if (query::Object)
    {
      text = query.text

      respond (text) =
        response = [
          r <- query.responses
          r.text == text
          r
        ].0
        traversalState (
          graph
          graph.queries.(response.next_query)
        )
    }
  else
    nil

startTraversal (graph) =
  traversalState (graph, graph.queries.(graph.firstQuery))

describe 'traversal'
  it 'asks questions in order'
    q1 = startTraversal (lexiconJSON)
    expect(q1.text).to.equal 'What hurts?'
    q2 = q1.respond 'right arm'
    expect(q2.text).to.equal 'Is it bleeding?'
    q3 = q2.respond 'yes'
    expect(q3.text).to.equal 'Is it aching?'
    q4 = q3.respond 'no'
    expect(q4.text).to.equal 'Prescribe dressing'
