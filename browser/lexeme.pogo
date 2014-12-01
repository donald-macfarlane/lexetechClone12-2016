module.exports (element, graphApi) =
  React = require 'react'
  r = React.createElement

  App = React.createClass {
    displayName = 'Lexeme'

    getInitialState () =
      {
        query = { text = '', responses = [] }
        responses = []
      }

    selectResponse (response) =
      queryId = response.nextQuery

      query =
        if (queryId != nil)
          self.state.graph.queries.(queryId)

      self.state.responses.push(response)

      self.setState {
        query = query
        responses = self.state.responses
      }

    render () =
      r "div" (nil) (
        if (self.state.query)
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
        else
          r "div" { className = 'finished' } "finished"

        r "div" { className = 'notes' } ([ n <- self.state.responses, n.notes, n.notes ].join ' ')
      )

    componentDidMount () =
      graph = graphApi.graphForQuery(nil)!
      self.setState {
        query = graph.queries.(graph.firstQuery)
        graph = graph
      }
  }

  React.render(React.createElement(App, null), element)
