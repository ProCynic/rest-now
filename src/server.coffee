# imports
restify = require 'restify'
node_static = require 'node-static'
mongo = require 'mongodb'
fs = require 'fs'

# static file server
static_server = null


# mongo setup
newConnection  = (options) -> new mongo.Db dbname, (new mongo.Server '127.0.0.1', 27017, {auto_reconnect: true}), options

# strict database decorator
strict = (func) -> (req, res, next) ->
  newConnection({strict:true}).open (err, db) ->
    return res.send 500, 'could not connect to database' if err?
    func req, res, next, db

# non strict database decorator
nostrict = (func) -> (req, res, next) ->
  newConnection({}).open (err, db) ->
    return res.send 500, 'could not connect to database' if err?
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

# controllers

# GET
collections = api strict (req, res, next, db) ->
  db.collectionNames (err, names) ->
    res.json 200, names.filter((e) -> return e.name.split('.')[1] != 'system').map (e, i, arr) -> '/' + e.name.split('.')[1]
    db.close()

collection = api strict (req, res, next, db) ->
  db.collection req.params.collection, (err, c) ->
    if err?
      db.close()
      return res.send 404, errors.collectionNotFound req.params.collection
    result = []
    cursor = c.find({})
    # memory inefficient version for testing
    cursor.toArray (err, docs) ->
      res.json 200, docs.map (e, i, arr) -> '/' + req.params.collection + '/' +  e._id.toHexString()
    db.close()

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
      res.json 201, result
      db.close()

#PUT
update = api nostrict (req, res, next, db) ->
  db.close()
  #TODO

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

# Sever start function
exports.start = (port, path, db) ->
  root = path ? root
  dbname = db ? dbname
  static_server = new node_static.Server root
  server.listen port

return exports