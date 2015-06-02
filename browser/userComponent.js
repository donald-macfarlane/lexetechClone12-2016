var prototype = require('prote');
var h = require('plastiq').html;
var form = require('./form');
var routes = require('./routes');
var userApi = require('./userApi');
var throttle = require('plastiq-throttle');
var zeroClipboard = require('plastiq-zeroclipboard');

zeroClipboard.config({ swfPath: "/static/zeroclipboard/ZeroClipboard.swf" });

module.exports = prototype({
  constructor: function (user) {
    this.user = user;
    this.userApi = userApi();
    this.validationPromises = 0;

    this.getResetPasswordToken = throttle(function (user) {
      if (!user.hasPassword && user.id) {
        var self = this;

        return this.userApi.resetPasswordToken(user).then(function (response) {
          self.resetPasswordToken = response.token;
        });
      }
    });
  },

  render: function () {
    var self = this;

    this.getResetPasswordToken(this.user);

    function saveUser(form) {
      return form.validate().then(function () {
        delete self.user.dirty;

        return self.user.save().then(function (user) {
          routes.adminUser({userId: user.id}).push();
        });
      });
    }

    function dirtyUser(v) {
      self.user.dirty = true;
      return v;
    }

    var newUser = self.user.id === undefined;

    var user = this.user;
    var tokenLink = this.resetPasswordToken? location.origin + routes.resetPassword({token: this.resetPasswordToken}).href: undefined;

    return form.form(
      {
        key: user.id || 'new',
        rules: {
          email: {
            identifier: 'email',
            rules: [{
              type: 'email',
              prompt: 'please enter a valid email address'
            }]
          },
          firstName: {
            identifier: 'first-name',
            rules: [{
              type: 'empty',
              prompt: 'please enter a first name'
            }]
          },
          familyName: {
            identifier: 'family-name',
            rules: [{
              type: 'empty',
              prompt: 'please enter a family name'
            }]
          }
        },
        settings: {
          inline: true
        }
      },
      function (component) {
        return h('form.ui.form.user',
          newUser
            ? h('h2', 'New User')
            : h('h2',
              self.user.firstName, ' ', self.user.familyName,
              tokenLink
                ? [
                    h('input.token-link', {type: 'text', value: tokenLink, onclick: function () { this.select(); }}),
                    zeroClipboard(
                      tokenLink,
                      h('.ui.button.green', 'copy')
                    )
                  ]
                : h('span.no-token-link')
            ),
          h('.two.fields',
            form.text('First Name', [self.user, 'firstName', dirtyUser], {class: 'first-name', placeholder: 'first name', name: 'first-name'}),
            form.text('Family Name', [self.user, 'familyName', dirtyUser], {class: 'family-name', placeholder: 'family name', name: 'family-name'})
          ),
          form.text('Email', [self.user, 'email', dirtyUser], {class: 'email', placeholder: 'email', name: 'email'}),
          form.textarea('Address', [self.user, 'address', dirtyUser]),
          h('.two.fields',
            form.text('Office Phone Number', [self.user, 'officePhoneNumber', dirtyUser], {placeholder: 'office phone number'}),
            form.text('Cell Phone Number', [self.user, 'cellPhoneNumber', dirtyUser], {placeholder: 'cell phone number'})
          ),
          form.text('State License Number', [self.user, 'stateLicenseNumber', dirtyUser], {placeholder: 'state license number'}),
          form.boolean('Author', [self.user, 'author', dirtyUser]),
          form.boolean('Admin', [self.user, 'admin', dirtyUser]),
          h('.ui.button', {class: {disabled: !self.user.dirty, blue: !newUser, green: newUser}, onclick: function () { return saveUser(component.state); }}, newUser? 'Create': 'Save'),
          h('.ui.button', {onclick: routes.admin().push}, 'Close')
        );
      }
    );
  }
});
