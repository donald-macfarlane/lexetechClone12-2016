traversal = require './traversal'
expect = require 'chai'.expect

module.exports(graph) =
  currentQuery = traversal(graph.query)
  {
    asks (query) respondWith (response) =
      expect(currentQuery.text).to.equal (query)
      currentQuery := currentQuery.respond (response)

    query() = currentQuery.query
  }
