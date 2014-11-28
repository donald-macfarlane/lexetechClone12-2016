require 'cappie'

Cappie.start(
  command: 'gulp server',
  await: /Webserver started/,
  host: 'http://localhost:8000',
  driver: :selenium
)
