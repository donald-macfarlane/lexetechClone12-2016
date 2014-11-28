module.exports (element) =
  React = require 'react'
  r = React.createElement

  App = React.createClass {
      displayName = 'Lexeme'

      render () =
          r "div" (nil) "Welcome to the hospital..."
  }

  React.render(React.createElement(App, null), element)
