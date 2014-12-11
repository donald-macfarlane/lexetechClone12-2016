require 'cappie'

Cappie.start(
  command: 'pogo server/server.pogo',
  await: %r{http://localhost:8001/},
  host: 'http://localhost:8001',
  driver: :selenium,
  environment: { PORT: 8001 }
)
