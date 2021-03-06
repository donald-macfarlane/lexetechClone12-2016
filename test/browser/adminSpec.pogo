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
  result(name) = self.find('.search .results a', text = name)
}

user = testBrowser.find('form.user').component {
  firstName() = self.find('.first-name input')
  firstNameMessage() = self.find('.first-name .prompt')
  tokenLink() = self.find('.token-link')
  familyName() = self.find('.family-name input')
  familyNameMessage() = self.find('.family-name .prompt')
  email() = self.find('.email input')
  emailMessage() = self.find('.email .prompt')
  saveButton() = self.find('.button:not(.disabled)', text = 'SAVE')
  createButton() = self.find('.button:not(.disabled)', text = 'CREATE')
  deleteButton() = self.find('.button:not(.disabled)', text = 'DELETE')
  alreadyExistsMessage() = self.find('.already-exists-message')
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
        email = 'joe@example.com'
        firstName = 'Joe'
        familyName = 'Trimble'
      }
      api.users.push {
        id = 2
        email = 'bob@example.com'
        firstName = 'Bob'
        familyName = 'Yeoman'
      }

    it 'can search for, find and edit a user' =>
      app.adminTab().click!()
      admin.searchTextBox().click!()

      admin.searchTextBox().typeIn!('joe')
      admin.result('Joe').shouldExist!()
      admin.result('Bob').shouldNotExist!()
      admin.result('Joe').click!()

      user.firstName().shouldHave! { value = 'Joe' }
      user.firstName().typeIn!('Jack')
      user.saveButton().click!()

      retry!
        expect([u <- api.users, u.firstName]).to.eql ['Jack', 'Bob']

    it 'can create a new user' =>
      self.timeout 100000
      app.adminTab().click!()
      admin.createUser().click!()

      user.firstName().typeIn!('Jane')
      user.familyName().typeIn!('Jones')
      user.email().typeIn!('janejones@example.com')
      user.createButton().click!()

      admin.result('Jane').exists!()

      userObject = retry!
        users = [u <- api.users, "#(u.firstName) #(u.familyName) <#(u.email)>"]
        expect(users).to.eql [
          'Joe Trimble <joe@example.com>'
          'Bob Yeoman <bob@example.com>'
          'Jane Jones <janejones@example.com>'
        ]

        api.users.2

      user.tokenLink().shouldHave!(value: "resetpassword/#(userObject.id)_token")

    it 'must have first name, family name and email address' =>
      self.timeout 100000
      app.adminTab().click!()
      admin.createUser().click!()

      user.firstName().typeIn!('Jane')
      user.createButton().click!()
      user.familyNameMessage().shouldHave!(text: 'please enter a family name')
      user.emailMessage().shouldHave!(text: 'please enter a valid email address')

      admin.result('Jane').shouldNotExist!()

    it "can't create a new user with the same email as another" =>
      self.timeout 100000
      app.adminTab().click!()
      admin.createUser().click!()

      user.firstName().typeIn!('Bobby')
      user.familyName().typeIn!('Jones')
      user.email().typeIn!('bob@example.com')
      user.createButton().click!()

      user.emailMessage().shouldHave!(text: 'email address already exists')
      admin.result('bob@example.com').shouldHave!(length: 1)

    it 'can delete a user' =>
      self.timeout 100000
      app.adminTab().click!()
      admin.result('Bob').click!()
      user.deleteButton().click!()

      admin.result('Joe').shouldExist!()
      admin.result('Bob').shouldNotExist!()

      user.shouldNotExist!()

      retry!
        expect([u <- api.users, "#(u.firstName) #(u.familyName) <#(u.email)>"]).to.eql [
          'Joe Trimble <joe@example.com>'
        ]
