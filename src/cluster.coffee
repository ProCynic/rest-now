cluster = require 'cluster'
numcpus = require('os').cpus().length
server = require './server.js'

if cluster.isMaster
  cluster.fork() for i in [1..numcpus]
  cluster.on 'online', (worker) -> console.log  'worker ' + worker.process.pid + ' started'
  cluster.on 'exit', (worker, code, signal) ->
    console.log 'worker ' + worker.process.pid + ' died'
    cluster.fork()
else server.start 8000