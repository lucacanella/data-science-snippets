# Data Science Snippets

A collection of notes and code snippets for various Data Science tools.

## Open Refine
Open refine snippets and notes.
* *open-refine-notes.py*: Utility snippets for data refinement with OpenRefine (Python and GREL).

[Open Refine](http://openrefine.org/)

## Neo4j - 3.4.9
Neo4j 3.4.9 queries and utils used for a little POC (tested on docker for Windows 10).
* *neo4j-3.4.9/movies_db_ml-1m.cypher*: A list of queries to import and explore Movielens 1m dataset; exploring recommendation systems with Neo4j.
* *neo4j-3.4.9/neo4j-import-example.sh*: neo4j-admin import example
* *neo4j-3.4.9/run-neo4j.sh*: run Neo4j 3.4.9 on docker

## Neo4j - 4.0.0
Neo4j 4.0.0 queries and utils that evolved from the 3.4.9 scripts (tested on docker on Debian 9 virtual machine)
* *neo4j-4.0.0/shell.sh*: Some commands you have to run before you can make some queries
* *neo4j-4.0.0/queries.cypher*: Some queries

[MovieLens 1M Dataset](https://grouplens.org/datasets/movielens/1m/)

## DGraph - 1.2.1
DGraph v1.2.1 queries and utils, a very simple usage example.
* *dgraph-1.2.1/shell.sh*: Commands to run the DGraph standalone container
* *dgraph-1.2.1/queries.nq*: Some queries

### Disclaimer
This snippets are meant to be notes and utils, sometimes reminder of what I've been experimenting on different pieces of software, they are not meant to always work out-of-the-box. Use at your own risk!