mountApp = require './mountApp'
expect = require 'chai'.expect
browser = require 'browser-monkey'
queryApi = require './queryApi'
retry = require 'trytryagain'
rootComponent = require '../../browser/rootComponent'

testBrowser = browser.scope '.test'

app = testBrowser.component {
  adminTab() = self.find('.top-menu a', text = 'ADMIN')
}

admin = testBrowser.component {
  searchTextBox() = self.find('.search .ui.input input')
  createUser() = self.find('.button.create')
  searchResults() = self.find('.search .results')
  result(name) = self.find('.search .results h5', text = name)
}

user = testBrowser.component {
  firstName() = self.find('form.user .first-name input')
  tokenLink() = self.find('form.user .token-link')
  familyName() = self.find('form.user .family-name input')
  email() = self.find('form.user .email input')
  saveButton() = self.find('form.user .button:not(.disabled)', text = 'SAVE')
  createButton() = self.find('form.user .button:not(.disabled)', text = 'CREATE')
}

describe 'admin'
  api = nil
  oldFilter = nil

  beforeEach =>
    api := queryApi()
    $.mockjaxSettings.logging = false
    mountApp(rootComponent {
      user = { email = 'blah@example.com', admin = true }
    }, href = '/')
  
  context 'with some users'
    beforeEach =>
      api.users.push {
        id = 1
        href = '/api/users/1'
        email = 'joe@example.com'
        firstName = 'Joe'
        familyName = 'Trimble'
      }

    it 'can search for, find and edit a user' =>
      app.adminTab().click!()
      admin.searchTextBox().click!()

      admin.searchTextBox().typeIn!('joe')
      admin.result('Joe').click!()

      user.firstName().shouldHave! { value = 'Joe' }
      user.firstName().typeIn!('Jack')
      user.saveButton().click!()

      retry!
        expect([u <- api.users, u.firstName]).to.eql ['Jack']

    it 'can create a new user' =>
      self.timeout 100000
      app.adminTab().click!()
      admin.createUser().click!()

      user.firstName().typeIn!('Jane')
      user.familyName().typeIn!('Jones')
      user.email().typeIn!('janejones@example.com')
      user.createButton().click!()

      admin.result('Jane').exists!()
      user.tokenLink().shouldHave!(value: 'resetpassword/2_token')

      retry!
        expect([u <- api.users, "#(u.firstName) #(u.familyName): #(u.email)"]).to.eql ['Joe Trimble: joe@example.com', 'Jane Jones: janejones@example.com']
