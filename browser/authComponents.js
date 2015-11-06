var h = require('plastiq').html;
var routes = require('./routes');

module.exports.login = function (params) {
  return h('div.login-page',
    params.inactive
      ? h('h3', 'While you were away, we logged you out to protect your documents.')
      : undefined,
    credentialsForm('/login', h('button.ui.button', 'Log in')),
    links(
      signupLink(),
      routes.forgotPassword().link({class: 'ui link'}, 'I forgot my password')
    )
  );
};

function links() {
  var args = Array.prototype.slice.call(arguments);
  return h('.links', args);
}

module.exports.signup = function () {
  return h('div.signup-page',
    h('h1', 'Sign Up'),
    credentialsForm('/signup', h('button.ui.button', 'Create')),
    links(loginLink())
  );
};

module.exports.resetPassword = function (token) {
  return h('div.signup-page',
    h('h1', 'Welcome'),
    h('p', "This is the first time you've used Lexenotes, please enter a new password to start"),
    credentialsForm('/resetpassword', h('button.ui.button', 'Login'), {email: false, token: token}),
    links(signupLink(), loginLink())
  );
};

module.exports.forgotPassword = function () {
  return h('div.signup-page',
    h('h1', 'Reset Your Password'),
    h('p', "Please enter your email address"),
    credentialsForm('/forgotpassword', h('button.ui.button', 'Reset'), {password: false}),
    links(signupLink(), loginLink())
  );
};

function signupLink() { return routes.signup().link({class: 'ui link'}, 'Sign up'); }
function loginLink() { return routes.login().link({class: 'ui link'}, 'Login'); }

function credentialsForm(action, button, options) {
  var email = options && options.hasOwnProperty('email')? options.email: true;
  var password = options && options.hasOwnProperty('password')? options.password: true;
  var token = options && options.hasOwnProperty('token')? options.token: true;

  return h('form.signup.ui.form', {method: 'POST', action: action},
    email
      ? h('div.field',
          h('div.ui.input',
            h('input#email', { type: 'text', name: 'email', placeholder: 'Email' })
          )
        )
      : undefined,
    password
      ? h('div.field',
          h('div.ui.input',
            h('input#password', { type: 'password', name: 'password', placeholder: 'Password' })
          )
        )
      : undefined,
    token
      ? h('input', { type: 'hidden', name: 'token', value: token })
      : undefined,
    h('div',
      button
    )
  );
}
