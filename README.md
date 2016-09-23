# couchdb-search
Dockerfile for CouchDB 2.0 plus Cloudant Search

docker build -t couchdb:search .
docker run -p 5984:5984 couchdb:search
