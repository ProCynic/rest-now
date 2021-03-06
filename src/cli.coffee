cluster = require 'cluster'
numcpus = require('os').cpus().length
server = require './server.js'
argv = require('optimist').argv

if argv.h? or argv.help?
  console.log """
    usage: rest-now [path] [options]

    options:
      -p                Port to use [8000]
      -d                Mongo Database name [-d 'test']
      -s                Mongo server [-s 127.0.0.1:27017]
      -h --help         Display this message and exit
    """
  process.exit()

port = argv.p ? 8000
root = argv._[0]
db = argv.d ? 'test'
dbserver = argv.s ? '127.0.0.1:27017'

if cluster.isMaster
  cluster.fork() for i in [1..numcpus]
  cluster.on 'online', (worker) -> console.log  'worker ' + worker.process.pid + ' started'
  cluster.on 'exit', (worker, code, signal) ->
    console.log 'worker ' + worker.process.pid + ' died'
    cluster.fork()
else server.start port, root, db, dbserver