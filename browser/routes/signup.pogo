React = require 'react'
ReactRouter = require 'react-router'
Link = React.createFactory(ReactRouter.Link)
r = React.createElement

module.exports = React.createFactory(React.createClass {
  render() =
    r 'div' { className = 'signup-page' } (
      r 'h1' {} 'Sign Up'
      r 'form' { method = 'POST', action = '/signup', className = 'signup' } (
        r 'label' { htmlFor = 'signup_email' } 'Email'
        r 'input' { id = 'signup_email', type = 'text', name = 'email' }
        r 'label' { htmlFor = 'signup_password' } 'Password'
        r 'input' { id = "signup_password", type = 'password', name = 'password' }
        r 'button' {} 'Create'
      )
      r 'div' { className = 'links' } [
        Link { to = 'login'} 'Login'
      ]
    )
})
