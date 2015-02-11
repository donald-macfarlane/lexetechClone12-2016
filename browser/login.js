var h = require('plastiq').html;
var router = require('plastiq/router');

module.exports = function () {
  return h('div.login-page',
    h('h1', 'Login'),
    h('form.login', {method: 'POST', action: '/login'},
      h('label', {for: 'login_email'}, 'Email'),
      h('input', {id: 'login_email', type: 'text', name: 'email'}),
      h('label', {for: 'login_password'}, 'Password'),
      h('input', {id: "login_password", type: 'password', name: 'password'}),
      h('button','Log in')
    ),
    h('div.links',
      h('a', { href: '/signup', onclick: router.push}, 'Sign up')
    )
  );
};
