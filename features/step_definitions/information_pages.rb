When(/^I go to the (.*?) page$/) do |page|
  visit('/' + page.downcase)
end

Then(/^I can see the content (.*?)$/) do |content|
  expect(page).to have_content(content)
end
