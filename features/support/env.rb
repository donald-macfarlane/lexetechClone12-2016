require 'pry'
require 'cappie'
require 'capybara-screenshot/cucumber'

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

Cappie.start(
  command: 'gulp server',
  await: %r{http://localhost:8001/},
  host: 'http://localhost:8001',
  driver: :selenium,
  environment: { PORT: 8001 }
)
