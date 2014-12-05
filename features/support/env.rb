require 'cappie'

Cappie.start(
  command: 'gulp server',
  await: /Finished 'server'/,
  host: 'http://localhost:8001',
  driver: :selenium,
  environment: { PORT: 8001 }
)
