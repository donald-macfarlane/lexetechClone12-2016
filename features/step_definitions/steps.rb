Given(/^I am at the doctors$/) do
  visit '/'
end

Given(/^the doctor has signed in with email "(.*?)" and password "(.*?)"$/) do |email, password|
  click_on "Log in"
  fill_in "Email", with: email
  fill_in "Password", with: password
  click_on "Login"
end

When(/^the doctor asks me "(.*?)"$/) do |query_text|
  expect(page).to have_content(query_text)
end

When(/^I answer "(.*?)"$/) do |response|
  click_on response
end

Then(/^the doctor makes the following notes:$/) do |string|
  within '.notes' do
    expect(page).to have_content(string)
  end
end

When(/^I create a new user with email address "(.*?)" and password "(.*?)"$/) do |email, password|
  visit '/'
  click_on "Sign up"
  fill_in "Email", with: email
  fill_in "Password", with: password
  click_on "Create"
end
