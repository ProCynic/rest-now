# imports
restify = require 'restify'
node_static = require 'node-static'
mongo = require 'mongodb'
fs = require 'fs'

# static file server
static_server = null


# mongo setup

newConnection  = (options) -> new mongo.Db dbname, (new mongo.Server dbhost, dbport, {auto_reconnect: true}), options

# strict database decorator
strict = (func) -> (req, res, next) ->
  newConnection({strict:true}).open (err, db) ->
    return res.send 500, 'could not connect to database ' + dbname if err?
    func req, res, next, db

# non strict database decorator
nostrict = (func) -> (req, res, next) ->
  newConnection({}).open (err, db) ->
    return res.send 500, 'could not connect to database ' + dbname if err?
    func req, res, next, db


# restify server
server = restify.createServer
  name: 'teamconnect'
server.use restify.queryParser {mapParams:false}
server.use restify.bodyParser {mapParams:false}


# decorator to only call function if "Accept: application/json" is explicitly present
api = (func) -> (req, res, next) ->
  if req.header('Accept').indexOf('application/json') >= 0
    func req, res, next
    next false
  next()

# Error messages
errors =
  collectionNotFound: (coll) -> return '/' + coll + ' could not be found'
  docNotFound: (coll, pk) -> return '/' + coll + '/' + pk + ' could not be found'


find = (db, coll, query, res, limit, skip) ->
  db.collection coll, (err, c) ->
    if err?
      db.close()
      return res.send 404, errors.collectionNotFound coll
    result = []
    cursor = c.find query
    cursor.skip skip if skip?
    cursor.limit limit if limit?
    # memory inefficient version for testing
    cursor.toArray (err, docs) ->
      res.json 200, docs.map (e, i, arr) -> {href: '/' + coll + '/' +  e._id.toHexString()}
    db.close()

# controllers

# GET

collections = api strict (req, res, next, db) ->
  db.collectionNames (err, names) ->
    res.json 200, names.filter((e) -> return e.name.split('.')[1] != 'system').map (e, i, arr) -> {href: '/' + e.name.split('.')[1]}
    db.close()

collection = api strict (req, res, next, db) ->
  limit = parseInt req.query.limit
  skip = parseInt req.query.skip
  delete req.query.limit
  delete req.query.skip
  find db, req.params.collection, req.query, res, limit, skip

query = api strict (req, res, next, db) ->
  find db, req.params.collection, req.body, res, parseInt(req.query.limit), parseInt req.query.skip

document = api strict (req, res, next, db) ->
  db.collection req.params.collection, (err, c) ->
    if err?
      db.close()
      return res.send 404, errors.collectionNotFound req.params.collection
    c.findOne {_id: mongo.BSONPure.ObjectID.createFromHexString req.params.pk}, (err, doc) ->
      if err?
        db.close()
        return res.send 404, errors.docNotFound req.params.collection, req.params.pk
      res.json 200, doc
    db.close()

files = (req, res, next) ->
  if req.header('Accept').indexOf('application/json') is -1
    static_server.serve req, res, next
    next false
  next()

#POST
create = api nostrict (req, res, next, db) ->
  db.collection req.params.collection, (err, c) ->
    if err?
      db.close()
      return res.send err
    c.insert req.body, {safe:true}, (err, result) ->
      res.json 201, if result.length is 1 then result[0] else result
      db.close()

#PUT
update = api nostrict (req, res, next, db) ->
  db.collection req.params.collection, (err, c) ->
    if err?
      db.close()
      return res.send err
    update = if req.query.overwrite then req.body else {$set: req.body}
    id = mongo.BSONPure.ObjectID.createFromHexString req.params.pk
    c.update {_id: id}, update, {safe:true}, (err, count) ->
      db.close()
      return res.send err if err?
      document req, res, next

#DELETE
remove = api nostrict (req, res, next, db) ->
  db.collection req.params.collection, (err, c) ->
    if err?
      db.close()
      return res.send 404, errors.collectionNotFound req.params.collection
    c.remove {_id: mongo.BSONPure.ObjectID.createFromHexString req.params.pk}, (err, doc) ->
      if err?
        db.close()
        return res.send 404, errors.docNotFound req.params.collection, req.params.pk
      res.send 200, '/' + req.params.collection + '/' + req.params.pk + ' deleted'
    db.close()


removeAll = api nostrict (req, res, next, db) ->
  db.collection req.params.collection, (err, c) ->
    if err?
      db.close()
      return res.send 404, errors.collectionNotFound req.params.collection
    c.remove({})
    res.send 200, 'all records from /' + req.params.collection + ' deleted'
  db.close()

# NOT ACCEPTABLE
notAPI = (req, res, next) ->
  if req.header('Accept').indexOf('application/json') is -1
    res.send 406, "Must have explicit Accept: application/json to access api."
    next false

# Routes
server.get '/:collection', collection, files

server.post '/:collection/query', query, files

server.get '/:collection/:pk', document, files

server.get /^\/.*/, collections, files # catch all

server.post '/:collection', create, notAPI

server.put '/:collection/:pk', update, notAPI

server.del '/:collection', removeAll, notAPI

server.del '/:collection/:pk', remove, notAPI

root = null

try
  fs.lstatSync './public'
  root = './public'
catch err
  root = './'

dbname = 'test'
dbport = 27017
dbhost = '127.0.0.1'

# Sever start function
exports.start = (port, path, db, dbserver) ->
  p = port ? 8000
  root ?= path
  dbname ?= db
  [dbhost, dbport] = dbserver.split ':' if dbserver?
  dbport = parseInt dbport
  static_server = new node_static.Server root
  server.listen p, () ->
    console.log 'Server listening on port ' + p
    console.log 'db  host: ' + dbhost + ' port: ' + dbport + ' name: ' + dbname

return exports