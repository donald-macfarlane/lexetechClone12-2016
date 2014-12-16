React = require 'react'
ReactRouter = require 'react-router'
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
State = ReactRouter.State
Navigation = ReactRouter.Navigation
AuthStatus = require './authStatus'
r = React.createElement

module.exports = React.createFactory(React.createClass {
  mixins = [Navigation, State]

  render() =
    signedIn = self.props.user :: Object
    currentRoutes = self.getRoutes()
    routeName = currentRoutes.(currentRoutes.length - 1).name
    isLogin = (routeName == 'login') @or (routeName == 'signup')
    if (!signedIn && !isLogin)
      self.transitionTo 'login'
    else
      r 'div' { className = 'main' } (
        r 'div' { className = 'top-menu' } (
          AuthStatus(user = self.props.user)
        )
        RouteHandler.call(self, self.props)
      )
})
