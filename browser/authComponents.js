var h = require('plastiq').html;
var routes = require('./routes');

module.exports.login = function (params) {
  return h('div.login-page',
    params.inactive
      ? h('h3', 'While you were away, we logged you out to protect your documents.')
      : undefined,
    credentialsForm('/login', h('button.ui.button', 'Log in')),
    h('div.links', signupLink())
  );
};

module.exports.signup = function () {
  return h('div.signup-page',
    h('h1', 'Sign Up'),
    credentialsForm('/signup', h('button.ui.button', 'Create')),
    h('div.links', loginLink())
  );
};

module.exports.resetPassword = function (token) {
  return h('div.signup-page',
    h('h1', 'Welcome'),
    h('p', "This is the first time you've used Lexenotes, please enter a new password to start"),
    credentialsForm('/resetpassword', h('button', 'Login'), {email: false, token: token}),
    h('div.links', signupLink(), ' | ', loginLink())
  );
};

function signupLink() { return routes.signup().link({class: 'ui link'}, 'Sign up'); }
function loginLink() { return routes.login().link({class: 'ui link'}, 'Login'); }

function credentialsForm(action, button, options) {
  var email = options && options.hasOwnProperty('email')? options.email: true;

  return h('form.signup.ui.form', {method: 'POST', action: action},
    h('div.field',
        h('div.ui.input',email
        ? [
            h('input#email', { type: 'text', name: 'email', placeholder: 'Email' })
          ]
        : h('input', { type: 'hidden', name: 'token', value: options.token })
      )
    ),
    h('div.field',
      h('div.ui.input',
        h('input#password', { type: 'password', name: 'password', placeholder: 'Password' })
      )
    ),
    h('div',
      button
    )
  );
}
