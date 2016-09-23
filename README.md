# couchdb-search
Dockerfile for CouchDB 2.0 plus Cloudant Search

    docker build --no-cache -t couchdb:search .
    docker run -t -i -p 5984:5984 couchdb:search
