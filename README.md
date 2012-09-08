REST Now
========

Start it running, dump some HTML/js in the public dir, and you've got a webapp.

This is an attempt to make a mongo / rest api backend as simple as [http-server](https://github.com/nodeapps/http-server/).

Requests that *explicitly* contain `application/json` in the `Accept` header are handled by the API.  All other requests are handled by the static file server.