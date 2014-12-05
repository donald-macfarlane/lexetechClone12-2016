module.exports (element, queryApi) =
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
      self.state.responses.push(response)

      query = if (response.query)
        response.query()!

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
      self.setState {
        query = queryApi.firstQuery()!.query
      }
  }

  React.render(React.createElement(App, null), element)
