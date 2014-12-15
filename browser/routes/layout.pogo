React = require 'react'
ReactRouter = require 'react-router'
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
Navigation = ReactRouter.Navigation
AuthStatus = require './authStatus'
r = React.createElement

module.exports = React.createFactory(React.createClass {
  mixins = [Navigation]

  render() =
    signedIn = self.props.user :: Object
    isLogin = (window.location.pathname == '/login') @or (window.location.pathname == '/signup')
    if (!signedIn && !isLogin)
      self.transitionTo('login')
    else
      r 'div' { className = 'main' } (
        r 'div' { className = 'top-menu' } (
          AuthStatus(user = self.props.user)
        )
        RouteHandler()
      )
})
