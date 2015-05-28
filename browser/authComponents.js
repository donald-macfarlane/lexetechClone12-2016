var h = require('plastiq').html;
var routes = require('./routes');

module.exports.login = function () {
  return h('div.login-page',
    h('h1', 'Login'),
    credentialsForm('/login', h('button', 'Log in')),
    h('div.links', signupLink())
  );
};

module.exports.signup = function () {
  return h('div.signup-page',
    h('h1', 'Sign Up'),
    credentialsForm('/signup', h('button', 'Create')),
    h('div.links', loginLink())
  );
};

module.exports.resetPassword = function (token) {
  return h('div.signup-page',
    h('h1', 'Welcome'),
    h('p', 'Please think of a password to login'),
    credentialsForm('/resetpassword', h('button', 'Login'), {email: false, token: token}),
    h('div.links', signupLink(), loginLink())
  );
};

function signupLink() { return routes.signup().link('Sign up'); }
function loginLink() { return routes.login().link('Login'); }

function credentialsForm(action, button, options) {
  var email = options && options.hasOwnProperty('email')? options.email: true;

  return h('form.signup', {method: 'POST', action: action},
    email
      ? [
          h('label', { for: 'email' },'Email'),
          h('input#email', { type: 'text', name: 'email' })
        ]
      : h('input', { type: 'hidden', name: 'token', value: options.token }),
    h('label', { for: 'password' }, 'Password'),
    h('input#password', { type: 'password', name: 'password' }),
    button
  );
}
