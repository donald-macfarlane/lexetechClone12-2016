React = require 'react'
ReactRouter = require 'react-router'
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
State = ReactRouter.State
Navigation = ReactRouter.Navigation
r = React.createElement

AuthStatus = require './authStatus'
TopMenuTabs = require './topMenuTabs'

module.exports = React.createClass {
  mixins = [Navigation, State]

  getInitialState() =
    { warning = nil, showFlash = false }

  componentDidMount() =
    self.props.http.onError @(event, jqxhr, settings, thrownError)
      if (@not settings.suppressErrors)
        message = jqxhr.responseText || "Unknown. Are you online?"
        self.setState({
          showFlash = true
          warning = "ERROR: #(message)"
        })

  render() =
    signedIn = self.props.user :: Object
    currentRoutes = self.context.router.getCurrentRoutes()
    routeName = currentRoutes.(currentRoutes.length - 1).name
    isLogin = (routeName == 'login') @or (routeName == 'signup')
    if (!signedIn && !isLogin)
      self.transitionTo 'login'
    else
      r 'div' { className = 'main' } (
        r 'div' { className = 'top-menu' } (
          React.createElement(TopMenuTabs, {user = self.props.user, documentApi = self.props.documentApi})
          React.createElement(AuthStatus, {user = self.props.user})
        )
        if (self.state.showFlash)
          r 'div' { className = 'top-flash warning' } (
            self.state.warning
            r 'a' { className = 'close', onClick = self.closeFlash } '✕'
          )

        r 'div' { className = 'content' } (
          RouteHandler.call(self, self.props)
        )
      )

  closeFlash () =
    self.setState({ showFlash = false })
}
