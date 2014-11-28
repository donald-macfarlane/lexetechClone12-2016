module.exports (element, graphApi) =
  React = require 'react'
  r = React.createElement

  App = React.createClass {
    displayName = 'Lexeme'

    getInitialState () =
      { query = { text = '' } }

    render () =
      r "div" { className = 'query' } (
        r "div" { className =  'text' } (self.state.query.text)
      )

    componentDidMount () =
      graph = graphApi.graphForQuery(nil)!
      self.setState(query: graph.queries.(graph.firstQuery))
  }

  React.render(React.createElement(App, null), element)
