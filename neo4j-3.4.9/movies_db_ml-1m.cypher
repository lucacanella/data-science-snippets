//-----------------------------------------------------------------------------
// Copy/paste Utils

MATCH (a) DETACH DELETE a; //Delete all nodes

MATCH (u:User), (m:Movies) DETACH DELETE u, m; //Delete users and movies

CREATE INDEX ON :Movie(name); //Create index on Movie.name
CREATE INDEX ON :Movie(id);   //Create index on Movie.id
CREATE INDEX ON :Genre(name); //Create index on Genre.name
CREATE INDEX ON :User(id);    //Create index on User.id


//-----------------------------------------------------------------------------
// Imports

// Import movies database

LOAD CSV FROM 'file:///ml-1m/movies.dat' AS line FIELDTERMINATOR '^'
MERGE (m:Movie { id: toInteger(line[0]), name: line[1] })
WITH m, split(line[2], '|') AS genres
UNWIND genres as gen
	MERGE (g:Genre { name: gen })
	MERGE (m)-[:GENRE]->(g)

	
// Import users database

LOAD CSV FROM 'file:///ml-1m/users.dat' AS line FIELDTERMINATOR '^'
CREATE (u:User { id: toInteger(line[0]), gender: line[1], age: toInteger(line[2]), occupation_code: toInteger(line[3]), zipcode: line[4] })


// Import ratings

USING PERIODIC COMMIT 1000
LOAD CSV FROM 'file:///ml-1m/ratings.dat' AS line FIELDTERMINATOR '^'
WITH toInteger(line[2]) AS rating, toInteger(line[3]) AS rTime, toInteger(line[0]) AS userid, toInteger(line[1]) as movieid
	MATCH (u:User { id: userid }),
	      (m:Movie { id: movieid })
	MERGE (u)-[:RATED { rating: rating, t: rTime }]->(m)

//-----------------------------------------------------------------------------
// Import fixes
// Datatype fixes with apoc (not needed anymore)

call apoc.periodic.iterate(
	'MATCH (:User)-[r:RATED]->(:Movie) RETURN r',
	'SET r.t = toInt(r.t), r.rating = toInt(r.rating)', 
	{ batchSize: 1000, parallel:true }
)

call apoc.periodic.iterate(
	'MATCH (m:Movie) RETURN u',
	'SET m.id = toInt(m.id)', 
	{ batchSize: 250, parallel:true }
)

call apoc.periodic.iterate(
	'MATCH (u:User) RETURN u',
	'SET u.id = toInt(u.id), u.age = toInt(u.age), u.occupation_code = toInt(u.occupation_code)', 
	{ batchSize: 250, parallel:true }
)

//-----------------------------------------------------------------------------
// Add new user with ratings

//add new user
CREATE (u:User { id: 99997, gender: 'M', age: 35, occupation_code: 12, zipcode: '' })
	
//add rates for new user
WITH [
	[ 4, 1 ], 
	[ 4, 2 ], 
	[ 5, 12 ], 
	[ 5, 18 ], 
	[ 5, 19 ], 
	[ 5, 32 ], 
	[ 4, 34 ], 
	[ 2, 44 ], 
	[ 5, 47 ], 
	[ 5, 110 ],
	[ 5, 1967 ],
	[ 5, 356 ],
	[ 5, 1732 ],
	[ 5, 344 ],
	[ 5, 1073 ],
	[ 5, 541 ],
	[ 5, 1210 ],
	[ 5, 1222 ],
	[ 5, 2712 ],
	[ 5, 2716 ],
	[ 5, 2571 ],
	[ 3, 1923 ],
	[ 5, 353 ],
	[ 3, 500 ],
	[ 5, 3578 ],
	[ 3, 2018 ],
	[ 5, 2959 ],
	[ 4, 1590 ],
	[ 4, 1721 ],
	[ 5, 1240 ],
	[ 5, 648 ],
	[ 5, 3863 ],
	[ 5, 2115 ],
	[ 5, 2139 ],
	[ 5, 1517 ],
	[ 5, 527 ],
	[ 5, 170 ],
	[ 5, 1676 ],
	[ 5, 3527 ],
	[ 5, 3703 ],
	[ 5, 3704 ],
	[ 5, 2916 ]
] as uRates
UNWIND uRates as line
WITH line[0] AS rating, line[1] AS movieid, 99997 AS userid, toInt(timestamp()/1000) as rTime
	MATCH (u:User { id: userid }),
	      (m:Movie { id: movieid })
	MERGE (u)-[:RATED { rating: rating, t: rTime }]->(m)

//change rating time form 10 of the rates
MATCH (:User { id: 99997 })-[r:RATED]->(:Movie)
WITH r LIMIT 10
SET r.t = toInt(timestamp()/1000)

//Query user ratings
MATCH (u1:User { id: 99997 })-[r3:RATED]->(m:Movie)
RETURN m.name, r3.rating, datetime({epochSeconds: r3.t})
ORDER BY r3.rating DESC, r3.t DESC
LIMIT 50


//-----------------------------------------------------------------------------
// Queries

// Query single movie by name, with genre
MATCH (m:Movie {name: 'Toy Story (1995)'})-[:GENRE]->(g:Genre) RETURN m,g

// Find at most 3 movies associated with least 5 Genres
MATCH (m:Movie)-[:GENRE]->(:Genre)
WITH m, COUNT(*) as cnt
	WHERE cnt >= 5
	WITH m, cnt 
	LIMIT 3
		MATCH p=(m:Movie)-[:GENRE]->(:Genre)
		RETURN p, cnt
		ORDER BY cnt DESC

// Find two users that share the same rating for a movie with user 1
MATCH (u1:User {id: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating
RETURN u1, r1, r2, u2, m
LIMIT 2

// Find all the movies that have been rated the same by user 1 and '541'
MATCH (u1:User {id: 1})
MATCH (u2:User {id: 541})
MATCH (u1)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2)
WHERE r1.rating = r2.rating
return u1, m, u2, r1, r2

// Find all hte movies that have been rated the same by user 1 and '245'
MATCH (u1:User {id: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {id: 245})
WHERE r1.rating = r2.rating
return u1, m, u2, r1, r2

// Find at most 10 users that have rated at least 3 movies as user 1 did.
MATCH (u1:User { id: 1 })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating // assures u1 and u2 has given the same rating to the movie
  AND u2 <> u1 //assures that we are not returning to u1 (no cycles)
WITH u1, u2, COUNT(*) as cp //count the matches
WHERE cp > 3 //take only users with at least 3 matched paths
RETURN u2, cp //return matching users with relative matches count
ORDER BY cp DESC // sort by matches count
LIMIT 10 //take at most 10 matches

// Find all the paths between user 1 to any other user that has rated
// at least 3 movies as user 1 did.
MATCH (u1:User { id: 1 })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating // assures u1 and u2 has given the same rating to the movie
  AND u2 <> u1 //assures that we are not returning to u1 (no cycles)
WITH u1, u2, COUNT(*) as cp //count the matches
WHERE cp > 3 //take only users with at least 3 matched paths
WITH u1, u2, cp 
LIMIT 10 //take at most 10 matches
MATCH p=(u1)-[:RATED]->(:Movie)<-[:RATED]-(u2) // now recreate the paths between the users
RETURN p, cp

// Count rates and average rating per Genre for a user id 1
//
MATCH (u:User {id: 1})-[r:RATED]->(:Movie)-[:GENRE]->(g:Genre) // Starting from user 1, find all rated movies and their genre
RETURN count(r) AS ratesCount, avg(toInt(r.rating)) as ratesAvg, g.name //now count rates, and average rating for each genre
ORDER BY ratesCount DESC, ratesAvg DESC //sort results by rates count and rating average descending

// Same as before but with added "score" calculation.
//
MATCH (u:User {id: 1})-[r:RATED]->(:Movie)-[:GENRE]->(g:Genre) // Starting from user 1, find all rated movies and their genre
WITH count(r) AS ratesCount, max(r.t) as lastT, avg(toInt(r.rating)) as ratesAvg, g.name as genre //now count rates, and average rating for each genre
RETURN ratesCount, ratesAvg, genre, datetime({epochSeconds: lastT}), //now count rates, and average rating for each genre
       log10(ratesCount) * ratesAvg as score //calculate score
ORDER BY score DESC, lastT DESC //sort results by rates count and rating average descending


// Find the user with the most matches in ratings with user 1;
// then find 10 movies that user 2 rated the most, but user 1 hasn't rated yet.
// 
MATCH (u1:User { id: 1 })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating AND u2 <> u1
WITH u1, u2, COUNT(*) as cp
	WHERE cp > 1 //at least one 
	WITH u1, u2, cp ORDER BY cp DESC LIMIT 1 //Get user with most matching in movie ratings
		MATCH (m:Movie)<-[r3:RATED]-(u2)
		MATCH (m) WHERE NOT (u1)-[:RATED]->(m:Movie) //Get only movies that user 1 hasn't rated yet
		RETURN cp, u1.id, u2.id, m.id, m.name, r3.rating
		ORDER BY r3.rating DESC //sort by user 2 rating
		LIMIT 10

// Added a sort by rating time and output rating datetime
//
MATCH (u1:User { id: 1 })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating AND u2 <> u1
WITH u1, u2, COUNT(*) as cp
	WHERE cp > 1 //at least one 
	WITH u1, u2, cp ORDER BY cp DESC LIMIT 1 //Get user with most matching in movie ratings
		MATCH (m:Movie)<-[r3:RATED]-(u2)
		MATCH (m) WHERE NOT (u1)-[:RATED]->(m:Movie) //Get only movies that user 1 hasn't rated yet
		RETURN cp, u1.id, u2.id, m.id, m.name, r3.rating, datetime({epochSeconds: r3.t})
		ORDER BY r3.rating DESC, r3.t DESC //sort by user 2 rating
		LIMIT 10

//Datetime formatting with apoc.date.format
MATCH (u:User {id: 99997})-[r:RATED]->(:Movie)-[:GENRE]->(g:Genre)
WITH count(r) AS ratesCount, max(r.t) as lastT, avg(toInt(r.rating)) as ratesAvg, g.name as genre
RETURN ratesCount, ratesAvg, genre, apoc.date.format(lastT, 's', 'dd/MM/yyyy HH:mm') AS lastRated, //format date
       log10(ratesCount) * ratesAvg as score //calculate score
ORDER BY score DESC, lastT DESC //sort results by rates count and rating average descending

//Query top 10 users that rated Action movies.
MATCH (g:Genre { name: 'Action'})-[:GENRE]-(:Movie)-[r:RATED]-(u:User)
RETURN SUM(r.rating) as s, COUNT(*) AS c, AVG(r.rating) AS avg, u.id, u.age, u.gender
ORDER BY avg DESC, s DESC, c DESC
LIMIT 10

//Query top 10 users that rated specific genres: Movie genres with most ratings
MATCH (g:Genre)-[:GENRE]-(:Movie)-[r:RATED]-(u:User)
RETURN g.name, SUM(r.rating) as s, COUNT(*) AS c, AVG(r.rating) AS avg, u.id, u.age, u.gender
ORDER BY avg DESC, s DESC, c DESC
LIMIT 10

//Get rating statistics for genre by user gender 'F'
MATCH (:User { gender: 'F' })-[r:RATED]->(:Movie)-[:GENRE]-(g:Genre)
RETURN g.name, SUM(r.rating) as s, COUNT(*) AS c, AVG(r.rating) AS avg
ORDER BY avg DESC, s DESC, c DESC
LIMIT 10

//Find three possible "friends" of user id:1, by searching for users whose ratings match the most
MATCH (u1:User {id: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating
	WITH u1, count(m) as cm, u2
		ORDER BY cm desc
		LIMIT 3
			WITH u1, u2
			MATCH (u1:User)-[:RATED]->(m:Movie)<-[:RATED]-(u2:User)
			RETURN u1, m, u2
