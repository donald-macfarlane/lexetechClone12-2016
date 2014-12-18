React = require 'react'
ReactRouter = require 'react-router'
RouteHandler = React.createFactory(ReactRouter.RouteHandler)
State = ReactRouter.State
Navigation = ReactRouter.Navigation
AuthStatus = require './authStatus'
r = React.createElement

module.exports = React.createFactory(React.createClass {
  mixins = [Navigation, State]

  getInitialState() =
    { warning = nil, showFlash = false }

  componentDidMount() =
    self.props.http(document).ajaxError @(event, jqxhr, settings, thrownError)
      self.setState({
        showFlash = true
        warning = "ERROR: #(jqxhr.responseText)"
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
