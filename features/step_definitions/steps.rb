Given(/^I am at the doctors$/) do
  visit '/'
  expect(page).to have_content("Welcome to the hospital")
end

When(/^the doctor asks me "(.*?)"$/) do |query_text|
  expect(page).to have_content(query_text)
end
