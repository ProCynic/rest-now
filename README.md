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
