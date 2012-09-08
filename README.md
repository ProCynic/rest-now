API-In-A-Box
============

Start it running, dump some HTML/js in the public dir, and you've got a webapp.

Requests that *explicitly* contain `application/json` in the `Accept` header are handled by the API.  All other requests are handled by the static file server.