var prototype = require('prote');
var h = require('plastiq').html;
var form = require('./form');
var routes = require('./routes');
var userApi = require('./userApi');
var throttle = require('plastiq-throttle');
var zeroClipboard = require('plastiq-zeroclipboard');
var wait = require('./wait');

zeroClipboard.config({ swfPath: "/static/zeroclipboard/ZeroClipboard.swf" });

module.exports = prototype({
  constructor: function (options) {
    this.user = options.user;
    this.userApi = options.userApi;
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

    this.refresh = h.refresh;

    this.getResetPasswordToken(this.user);

    function saveUser(form) {
      var errors = form.validate();

      if (!errors) {
        delete self.user.dirty;

        return self.user.save().then(function (user) {
          routes.adminUser({userId: user.id}).push();
        }, function (error) {
          if (error.body.alreadyExists) {
            form.formElement.form('add prompt', 'email', 'email address already exists');
          } else {
            throw error;
          }
        });
      }
    }

    function dirtyUser(v) {
      self.user.dirty = true;
      return v;
    }

    var newUser = self.user.id === undefined;

    var user = this.user;
    var tokenLink = this.resetPasswordToken? location.origin + routes.resetPassword({token: this.resetPasswordToken}).href: undefined;

    var fields = {
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
      },
      officePhoneNumber: {
        identifier: 'office-phone-number',
        rules: []
      },
      cellPhoneNumber: {
        identifier: 'cell-phone-number',
        rules: []
      },
      stateLicenseNumber: {
        identifier: 'state-license-number',
        rules: []
      }
    };

    if (user.author) {
      fields.officePhoneNumber.rules.push({
        type: 'empty',
        prompt: 'please enter a valid office phone number'
      });

      fields.cellPhoneNumber.rules.push({
        type: 'empty',
        prompt: 'please enter a valid cell phone number'
      });
    }

    function deleteUser() {
      return self.userApi.deleteUser(user).then(function () {
        routes.admin().push();
      });
    }

    return h('form.user',
      form.form(
        {
          key: user.id || 'new',
          fields: fields,
          inline: true,
          v1: true
        },
        function (validationForm) {
          return h('.ui.form',
            newUser
              ? h('h2', 'New User')
              : h('h2',
                self.user.firstName, ' ', self.user.familyName
              ),
            tokenLink
              ? [
                  h('.field',
                    h('label', 'Login Link'),
                    h('.ui.action.input',
                      h('input.token-link', {type: 'text', value: tokenLink, onclick: function () { this.select(); }}),
                      zeroClipboard(
                        {
                          oncopy: function () {
                            self.tokenLinkCopied = true;
                            return wait(1000).then(function () {
                              self.tokenLinkCopied = false;
                            });
                          }
                        },
                        tokenLink,
                        h('button.ui.teal.right.labeled.icon.button.copy-token-link',
                          {
                            onclick: function (ev) { ev.preventDefault(); },
                            class: {copied: self.tokenLinkCopied}
                          },
                          h('i.copy.icon'),
                          self.tokenLinkCopied? 'Copied!': 'Copy'
                        )
                      )
                    )
                  ),
                ]
              : h('span.no-token-link'),
            h('.two.fields',
              form.text('First Name', [self.user, 'firstName', dirtyUser], {class: 'first-name', placeholder: 'first name', name: 'first-name'}),
              form.text('Family Name', [self.user, 'familyName', dirtyUser], {class: 'family-name', placeholder: 'family name', name: 'family-name'})
            ),
            form.text('Email', [self.user, 'email', dirtyUser], {class: 'email', placeholder: 'email', name: 'email'}),
            form.textarea('Address', [self.user, 'address', dirtyUser]),
            h('.two.fields',
              form.text('Office Phone Number', [self.user, 'officePhoneNumber', dirtyUser], {placeholder: 'office phone number', name: 'office-phone-number'}),
              form.text('Cell Phone Number', [self.user, 'cellPhoneNumber', dirtyUser], {placeholder: 'cell phone number', name: 'cell-phone-number'})
            ),
            form.text('State License Number', [self.user, 'stateLicenseNumber', dirtyUser], {placeholder: 'state license number', name: 'state-license-number'}),
            form.boolean('Author', [self.user, 'author', dirtyUser]),
            form.boolean('Admin', [self.user, 'admin', dirtyUser]),
            h('.ui.button', {class: {disabled: !self.user.dirty, blue: !newUser, green: newUser}, onclick: function () { return saveUser(validationForm); }}, newUser? 'Create': 'Save'),
            !newUser? h('.ui.button', {onclick: deleteUser}, 'Delete'): undefined,
            h('.ui.button', {onclick: routes.admin().push}, 'Close')
          );
        }
      )
    );
  }
});
