React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  render() =
    r 'div' { className = 'login-page' } (
      r 'h1' {} 'Login'
      r 'form' { method = 'POST', action = '/login', className = 'login' } (
        r 'label' { htmlFor = 'login_email' } 'Email'
        r 'input' { id = 'login_email', type = 'text', name = 'email' }
        r 'label' { htmlFor = 'login_password' } 'Password'
        r 'input' { id = "login_password", type = 'password', name = 'password' }
        r 'button' {} 'Log in'
      )
      r 'div' { className = 'links' } [
        Link { to = 'signup' } 'Sign up'
      ]
    )
})
