module.exports (element, queryApi, pageData) =
  React = require 'react'
  r = React.createElement

  report = require './reportGenerator'
  login = require './login'

  app = React.createFactory(React.createClass {
    render() =
      r 'div' {} (
        r 'div' { className = 'top-menu' } (
          login(user = self.props.user)
        )
        if (self.props.user)
          report(queryApi = self.props.queryApi)
      )
  })

  React.render(React.createElement(app, {queryApi = queryApi, user = pageData.user}), element)
