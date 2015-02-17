var h = require('plastiq').html;
var router = require('plastiq/router');

module.exports = function () {
  return h('div.signup-page',
    h('h1', 'Sign Up'),
    h('form.signup', {method: 'POST', action: '/signup'},
      h('label', { for: 'signup_email' },'Email'),
      h('input#signup_email', { type: 'text', name: 'email' }),
      h('label', { for: 'signup_password' }, 'Password'),
      h('input#signup_password', { type: 'password', name: 'password' }),
      h('button', 'Create')
    ),
    h('div.links',
      h('a', { href: '/login', onclick: router.push}, 'Login')
    )
  );
};
