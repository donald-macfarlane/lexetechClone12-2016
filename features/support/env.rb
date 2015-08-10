require 'pry-byebug'
require 'cappie'
require 'capybara-screenshot/cucumber'
require 'capybara-webkit'

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

Cappie.start(
  command: 'gulp server-no-watch',
  await: %r{http://localhost:8001/},
  host: 'http://localhost:8001',
  driver: :selenium,
  environment: { PORT: 8001 }
)
