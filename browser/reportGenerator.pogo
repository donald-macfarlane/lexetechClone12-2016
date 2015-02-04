React = require 'react'
r = React.createElement

module.exports = React.createFactory(React.createClass {
  displayName = 'Lexeme'

  getInitialState () =
    {
      query = { text = '', responses = [] }
      responses = []
    }

  selectResponse (response) =
    self.state.responses.push(response)

    self.setState {
      query = response.query()!
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

      r "div" {
        className = 'notes'
        dangerouslySetInnerHTML = {
          __html = [
            response <- self.state.responses
            response.styles
            response.styles.style1
            response.styles.style1
          ].join ' '
        }
      }
    )

  componentDidMount () =
    self.setState {
      query = self.props.queryApi.firstQueryGraph()!
    }
})
