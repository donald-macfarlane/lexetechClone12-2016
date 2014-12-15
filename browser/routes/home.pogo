React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
r = React.createElement
report = require '../reportGenerator'

module.exports = React.createFactory(React.createClass {
  render() =
    if (self.props.user)
      report(queryApi = self.props.queryApi)
    else
      r 'div' { className = 'signed-out-home-page' } [
        Link { to = 'signup'} 'Sign up'
        Link { to = 'login'} 'Log in'
      ]
})
