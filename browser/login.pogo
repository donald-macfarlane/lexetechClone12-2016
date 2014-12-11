React = require 'react'
r = React.createElement

module.exports = React.createFactory(React.createClass {
  getInitialState() = { signingUp = false, loggingIn = false }

  signup() =
    self.setState { signingUp = true }

  login() =
    self.setState { loggingIn = true }

  render() =
    r 'div' {} (
      if (self.props.user)
        [
          r 'form' { method = 'POST', action = '/logout' } (
            r 'input' { type = 'submit', value = 'Logout' }
          )
        ]
      else
        [
          r 'button' { onClick = self.signup } 'Sign up'
          r 'button' { onClick = self.login } 'Log in'
        ]

      ...

      if (self.state.signingUp)
        signupForm()
      else if (self.state.loggingIn)
        loginForm()
    )
})

signupForm = React.createFactory(React.createClass {
  render() =
    r 'form' { method = 'POST', action = '/signup' } (
      r 'label' { htmlFor = 'signup_email' } 'Email'
      r 'input' { id = 'signup_email', type = 'text', name = 'email' }
      r 'label' { htmlFor = 'signup_password' } 'Password'
      r 'input' { id = "signup_password", type = 'password', name = 'password' }
      r 'button' {} 'Create'
    )
})

loginForm = React.createFactory(React.createClass {
  render() =
    r 'form' { method = 'POST', action = '/login' } (
      r 'label' { htmlFor = 'login_email' } 'Email'
      r 'input' { id = 'login_email', type = 'text', name = 'email' }
      r 'label' { htmlFor = 'login_password' } 'Password'
      r 'input' { id = "login_password", type = 'password', name = 'password' }
      r 'button' {} 'Login'
    )
})
