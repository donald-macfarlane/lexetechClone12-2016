require 'cappie'

Cappie.start(
  command: 'gulp server',
  await: /Listening/,
  host: 'http://localhost:8001',
  driver: :selenium,
  environment: { port: 8001 }
)
