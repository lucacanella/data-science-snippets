//-----------------------------------------------------------------------------
// Copy/paste Utils

MATCH (a) DETACH DELETE a; //Delete all nodes

MATCH (u:User), (m:Movies) DETACH DELETE u, m; //Delete users and movies

CREATE INDEX ON :Movie(name); //Create index on Movie.name
CREATE INDEX ON :Movie(id);   //Create index on Movie.id
CREATE INDEX ON :Genre(name); //Create index on Genre.name
CREATE INDEX ON :Genre(id);   //Create index on Genre.name
CREATE INDEX ON :User(id);    //Create index on User.id


//-----------------------------------------------------------------------------
// Imports

// Import movies database

LOAD CSV FROM 'file:///ml-1m/movies.dat' AS line FIELDTERMINATOR '^'
MERGE (m:Movie { id: line[0], name: line[1] })
WITH m, split(line[2], '|') AS genres
UNWIND genres as gen
	MERGE (g:Genre { name: gen })
	MERGE (m)-[:GENRE]->(g)

	
// Import users database

LOAD CSV FROM 'file:///ml-1m/users.dat' AS line FIELDTERMINATOR '^'
CREATE (u:User { id: line[0], gender: line[1], age: line[2], occupation_code: line[3], zipcode: line[4] })


// Import ratings

USING PERIODIC COMMIT 1000
LOAD CSV FROM 'file:///ml-1m/ratings.dat' AS line FIELDTERMINATOR '^'
WITH line[2] AS rating, line[3] AS rTime, line[0] AS userid, line[1] as movieid
	MATCH (u:User { id: userid }),
	      (m:Movie { id: movieid })
	MERGE (u)-[:RATED { rating: rating, t: rTime }]->(m)

//-----------------------------------------------------------------------------
// Queries

// Query single movie by name, with genre
MATCH (m:Movie {name: 'Toy Story (1995)'})-[:GENRE]->(g:Genre) RETURN m,g

// Find two users that share the same rating for a movie with user '1'
MATCH (u1:User {id: '1'})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating
RETURN u1, r1, r2, u2, m
LIMIT 2

// Find all the movies that have been rated the same by user '1' and '541'
MATCH (u1:User {id: '1'})
MATCH (u2:User {id: '541'})
MATCH (u1)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2)
WHERE r1.rating = r2.rating
return u1, m, u2, r1, r2

// Find all hte movies that have been rated the same by user '1' and '245'
MATCH (u1:User {id: '1'})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {id: '245'})
WHERE r1.rating = r2.rating
return u1, m, u2, r1, r2

// Find at most 10 users that have rated at least 3 movies as user '1' did.
MATCH (u1:User { id: '1' })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating // assures u1 and u2 has given the same rating to the movie
  AND u2 <> u1 //assures that we are not returning to u1 (no cycles)
WITH u1, u2, COUNT(*) as cp //count the matches
WHERE cp > 3 //take only users with at least 3 matched paths
RETURN u2, cp //return matching users with relative matches count
ORDER BY cp DESC // sort by matches count
LIMIT 10 //take at most 10 matches

// Find all the paths between user '1' to any other user that has rated
// at least 3 movies as user '1' did.
MATCH (u1:User { id: '1' })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating // assures u1 and u2 has given the same rating to the movie
  AND u2 <> u1 //assures that we are not returning to u1 (no cycles)
WITH u1, u2, COUNT(*) as cp //count the matches
WHERE cp > 3 //take only users with at least 3 matched paths
WITH u1, u2, cp 
LIMIT 10 //take at most 10 matches
MATCH p=(u1)-[:RATED]->(:Movie)<-[:RATED]-(u2) // now recreate the paths between the users
RETURN p, cp

// Count rates and average rating per Genre for a user id '1'
//
MATCH (u:User {id: '1'})-[r:RATED]->(:Movie)-[:GENRE]->(g:Genre) // Starting from user '1', find all rated movies and their genre
RETURN count(r) AS ratesCount, avg(toInt(r.rating)) as ratesAvg, g.name //now count rates, and average rating for each genre
ORDER BY ratesCount DESC, ratesAvg DESC //sort results by rates count and rating average descending

// Same as before but with added "score" calculation.
//
MATCH (u:User {id: '1'})-[r:RATED]->(:Movie)-[:GENRE]->(g:Genre) // Starting from user '1', find all rated movies and their genre
WITH count(r) AS ratesCount, avg(toInt(r.rating)) as ratesAvg, g.name as genre //now count rates, and average rating for each genre
RETURN ratesCount, ratesAvg, genre //now count rates, and average rating for each genre
     , log10(ratesCount) * ratesAvg as score //calculate score
ORDER BY score DESC //sort results by rates count and rating average descending
