module.exports (element, graphApi) =
  React = require 'react'
  r = React.createElement

  App = React.createClass {
    displayName = 'Lexeme'

    getInitialState () =
      { query = { text = '', responses = [] } }

    selectResponse (response) =
      queryId = response.nextQueries.0
      self.setState { query = self.state.graph.queries.(queryId) }

    render () =
      r "div" { className = 'query' } (
        r "div" { className =  'text' } (self.state.query.text)
        r "ul" {} [
          response <- self.state.query.responses
          responseSelected () =
            self.selectResponse(response)

          r "li" {
            key = response.id
          } (
            r 'button' {
              onClick = responseSelected
              className = 'response'
            } (response.text)
          )
        ]
      )

    componentDidMount () =
      graph = graphApi.graphForQuery(nil)!
      self.setState {
        query = graph.queries.(graph.firstQuery)
        graph = graph
      }
  }

  React.render(React.createElement(App, null), element)
