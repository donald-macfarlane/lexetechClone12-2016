React = require 'react'
r = React.createElement

App = React.createClass {
    displayName = 'Lexeme'

    render () =
        r "div" (nil) "React rendered this..."
}

React.render(React.createElement(App, null), window.document.body)
