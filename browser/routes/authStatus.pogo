React = require 'react'
ReactRouter = require 'react-router'
r = React.createElement

classes(obj) =
  [k <- Object.keys(obj), obj.(k), k].join ' '

module.exports = React.createFactory(React.createClass {
  render() =
    r 'div' { className = classes { user = true, 'logged-out' = @not self.props.user, 'logged-in' = self.props.user } } (
      if (self.props.user)
        [
          r 'span' {} ('welcome: ', self.props.user.email)
          r 'form' { className = 'logout', method = 'POST', action = '/logout' } (
            r 'input' { type = 'submit', value = 'Logout' }
          )
        ]
      else
        []
    )
})
