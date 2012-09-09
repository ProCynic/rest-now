REST Now
========

Start it running, dump some HTML/js in the public dir, and you've got a webapp.

This is an attempt to make a mongo / rest api backend as simple as [http-server](https://github.com/nodeapps/http-server/).

Requests that *explicitly* contain `application/json` in the `Accept` header are handled by the API.  All other requests are handled by the static file server.

Installing Globally
===================

`npm install -g rest-now`

Usage
-----

`rest-now [path] [options]`

[path] defaults to ./public if the folder exists, and ./ otherwise.

options:

    -p                Port to use [8000]
    -d                Mongo Database name [-d 'test']
    -s                Mongo server [-s 127.0.0.1:27017]
    -h --help         Display this message and exit

Installing Locally
==================

`npm install rest-now`

Usage
-----

    var server = require('rest-now');
    server.start([port, root, db, dbserver]);

* `port` is the port you want the server to run on.  Defaults to 8000.
* `root` is where it roots the static file server.  Defaults to `./public` if that exists and to `./` otherwise.
* `db` is the name of the mongoDB database you want it to use. Defaults to `test`.
* `dbserver` is the location of the mongoDB server.  Defaults to `127.0.0.1:27017`.


API
===

All URLs are realtive to server base (e.g. http://localhost:8000).
All requests to the API must **explicitly** contain `application/json` in the accept header.

Create
------

To insert a document into the database, send a POST request with `Content-Type: application/json` and a json representation of the document to `/[collection]`.
If the insert is successful, the newly created document will be returned.  If the collection does not exist yet, it will be created.

Read
----

A GET request to `/` will return a list of collection names in the form `["/[collection"]`.

A GET request to `/[collection]` will return a list of documents in the collection in the form `["/[collection]/[pk]"]`.
Pagination may be achieved by passing skip and limit variables in the query string.  For example, `/[collection]?skip=30&limit=10` will return 10 results skipping the first 30, making this the equivalent of asking for page 4 with a page size of 10.
Results may be filtered by passing in additional query parameters.  This request, `/[collection]?name=bob`, will return only records where the name field is "bob".  If multiple fields are provided, the results will be intersected.  Searching for fields named "limit" or "skip" is not possible.  Use POST queries instead.

A POST request to `/[collection]/query` will execute the query contained in the body of the POST request, allowing for arbitrarily complex queries.
See the [node-mongodb docs](https://github.com/mongodb/node-mongodb-native/blob/master/docs/queries.md) for information on formatting the queries.
Pagination works the same as for the GET requests above.

A GET request to `/[collection]/[pk]` will return a json representation of the document requested if it exists and an HTTP `404 Not Found` otherwise.

Update
------

A PUT request to `/[collection]/[pk]` will update the document with the body of the PUT request. If the document does not exist, an HTTP `404 Not Found` will be returned.
By default, the server will perform a merge update, overwriting only those fields which are supplied in the request.  If you would like to perform an overwrite update instead, for instance to remove a field, add `overwrite=true` to the query string (e.g. `/[collection]/[pk]?overwrite=true`).

Delete
------

A DELETE request to `/[collection]/[pk]` will remove the document from the database or return an HTTP `404 Not Found` if it does not exist.

A DELETE request to `/[collection]` will remove all documents from the collection.
