Given(/^I am logged in as an admin$/) do
  @admin_email = "admin@surgery.com"
  @admin_password = "omgomgomg"
  api.sign_up(@admin_email, @admin_password, admin: true)
  login(@admin_email, @admin_password)
end

When(/^I create a new user with email "(.*?)"$/) do |email|
  click_on 'Admin'
  find('.button', text: 'add user').click
  @new_user_email = email
  find('.user .email input').set(email)
  find('.button', text: 'Create').click
end

Then(/^I can copy the signup link$/) do
  @token_link = find('.user input.token-link').value
end

When(/^that link is used by the new user$/) do
  logout
  visit @token_link
end

Then(/^they can set their password "(.*?)" and login$/) do |password|
  @new_user_password = password
  fill_in "Password", with: password
  find('button', text: 'Login').click
end

Then(/^can log back in with the same password "(.*?)"$/) do |arg1|
  login(@new_user_password, @new_user_password)
end
