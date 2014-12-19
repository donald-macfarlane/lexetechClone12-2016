React = require 'react'
ReactRouter = require 'react-router'
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
State = ReactRouter.State
Navigation = ReactRouter.Navigation
r = React.createElement

AuthStatus = require './authStatus'
TopMenuTabs = require './topMenuTabs'

module.exports = React.createFactory(React.createClass {
  mixins = [Navigation, State]

  getInitialState() =
    { warning = nil, showFlash = false }

  componentDidMount() =
    self.props.http(document).ajaxError @(event, jqxhr, settings, thrownError)
      message = jqxhr.responseText || "Unknown. Are you online?"
      self.setState({
        showFlash = true
        warning = "ERROR: #(message)"
      })

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
          TopMenuTabs(user = self.props.user)
          AuthStatus(user = self.props.user)
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
})
