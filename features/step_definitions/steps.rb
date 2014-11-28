Given(/^I am at the doctors$/) do
  visit '/'
end

When(/^the doctor asks me "(.*?)"$/) do |query_text|
  expect(page).to have_content(query_text)
end
