require 'pry'
require 'cappie'

Cappie.start(
  command: 'gulp server',
  await: %r{http://localhost:8001/},
  host: 'http://localhost:8001',
  driver: :selenium,
  environment: { PORT: 8001 }
)
