// -----------------------------------------------------------------------------
//  Queries

//index db
CREATE INDEX ON :Movie(name); 
CREATE INDEX ON :Genre(name); 
CREATE INDEX ON :Movie(movieId);
CREATE INDEX ON :User(userId); 

//show indexes
CALL db.indexes

//explode movie genres into nodes
MATCH (m:Movie)
WITH m, split(m.genres, '|') AS genres
UNWIND genres as gen
	MERGE (g:Genre { name: gen })
	MERGE (m)-[:GENRE]->(g)

//copy user and movies ids to a string field
MATCH (m:Movie) SET m.movieId = toString(ID(m))
MATCH (u:User) SET u.userId = toString(ID(u))

//add new user
CREATE (u:User { userId: "1", gender: 'M', age: 35, occupation_code: 12, zipcode: '' })
	
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
WITH line[0] AS rating, toString(line[1]) AS movieid, "1" AS userid, toInteger(timestamp()/1000) as rTime
	MATCH (u:User { userId: userid }),
	      (m:Movie { movieId: movieid })
	MERGE (u)-[:RATED { rating: rating, t: rTime }]->(m)

//change rating time form 10 of the rates
MATCH (:User { userId: "1" })-[r:RATED]->(:Movie)
WITH r LIMIT 10
SET r.t = toInteger(timestamp()/1000)
  

//  Query single movie by name, with genre
MATCH (m:Movie {name: 'Toy Story (1995)'})-[:GENRE]->(g:Genre) RETURN m,g

// Query all genres for user "1"
MATCH (:User { userId: "1" })-[*..2]-(g:Genre) RETURN DISTINCT(g)

// Return only genres name as single list
MATCH (:User { userId: "1" })-[*..2]-(g:Genre) 
 WITH DISTINCT (g) 
 WITH collect(g.name) AS genres 
 RETURN genres

//  Find at most 3 movies associated with least 5 Genres
MATCH (m:Movie)-[:GENRE]->(:Genre)
WITH m, COUNT(*) as cnt
	WHERE cnt >= 5
	WITH m, cnt 
	LIMIT 3
		MATCH p=(m:Movie)-[:GENRE]->(:Genre)
		RETURN p, cnt
		ORDER BY cnt DESC

//  Find two users that share the same rating for a movie with user 1
MATCH (u1:User {userId: "1"})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating
RETURN u1, r1, r2, u2, m
LIMIT 2

//  Find all the movies that have been rated the same by user 1 and '541'
MATCH (u1:User {userId: "1"})
MATCH (u2:User {userId: "541"})
MATCH (u1)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2)
WHERE r1.rating = r2.rating
return u1, m, u2, r1, r2

//  Find all the movies that have been rated the same by user 1 and '245'
MATCH (u1:User {userId: "1"})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: "245"})
WHERE r1.rating = r2.rating
return u1, m, u2, r1, r2

//  Find at most 10 users that have rated at least 3 movies as user 1 did.
MATCH (u1:User { userId: "1" })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating // assures u1 and u2 has given the same rating to the movie
  AND u2 <> u1 //assures that we are not returning to u1 (no cycles)
  WITH u1, u2, COUNT(*) as cp //count the matches
  WHERE cp > 3 //take only users with at least 3 matched paths
  RETURN u2, cp //return matching users with relative matches count
  ORDER BY cp DESC // sort by matches count
  LIMIT 10 //take at most 10 matches

//  Find all the paths between user 1 to any other user that has rated
//  at least 3 movies as user 1 did.
MATCH (u1:User { userId: "1" })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating // assures u1 and u2 has given the same rating to the movie
  AND u2 <> u1 //assures that we are not returning to u1 (no cycles)
  WITH u1, u2, COUNT(*) as cp //count the matches
    WHERE cp > 3 //take only users with at least 3 matched paths
    WITH u1, u2, cp 
      LIMIT 10 //take at most 10 matches
      MATCH p=(u1)-[:RATED]->(:Movie)<-[:RATED]-(u2) // now recreate the paths between the users
      RETURN p, cp

//  Count rates and average rating per Genre for user id 1
// 
MATCH (u:User {userId: "1"})-[r:RATED]->(:Movie)-[:GENRE]->(g:Genre) // Starting from user 1, find all rated movies and their genre
RETURN count(r) AS ratesCount, 
       avg(toInteger(r.rating)) as ratesAvg, 
       g.name //now count rates, and average rating for each genre
 ORDER BY ratesCount DESC, //sort results by rates count and rating average descending
          ratesAvg DESC

//  Same as before with some additional score calculation.
// 
MATCH (u:User {userId: "1"})-[r:RATED]->(:Movie)-[:GENRE]->(g:Genre) // Starting from user 1, find all rated movies and their genre
 WITH u, 
      count(r) AS ratesCount, //now count rates, and average rating for each genre
      max(r.time) as lastT, 
      avg(toInteger(r.rating)) as ratesAvg, 
      g.name as genre
RETURN u.age, ratesCount, ratesAvg, genre, datetime({epochSeconds: lastT}), //return some values...
       log10(ratesCount) * ratesAvg as score //and calculate score
ORDER BY score DESC, lastT DESC //sort results by rates count and rating average descending

//  Find the user with the most matches in ratings with user 1;
//  then find 10 movies that user 2 rated the most, but user 1 hasn't rated yet.
//  
MATCH (u1:User { userId: "1" })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating AND u2 <> u1
WITH u1, u2, COUNT(*) as cp
	WHERE cp > 1 //at least one 
	WITH u1, u2, cp ORDER BY cp DESC LIMIT 1 //Get user with most matching in movie ratings
		MATCH (m:Movie)<-[r3:RATED]-(u2)
		MATCH (m) WHERE NOT (u1)-[:RATED]->(m:Movie) //Get only movies that user 1 hasn't rated yet
		RETURN cp, u1.userId, u2.userId, m.movieId, m.name, r3.rating
		ORDER BY r3.rating DESC //sort by user 2 rating
		LIMIT 10

//  Added a sort by rating time and output rating datetime
// 
MATCH (u1:User { userId: "1" })-[r1:RATED]->(:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating AND u2 <> u1
WITH u1, u2, COUNT(*) as cp
	WHERE cp > 1 //at least one 
	WITH u1, u2, cp ORDER BY cp DESC LIMIT 1 //Get user with most matching in movie ratings
		MATCH (m:Movie)<-[r3:RATED]-(u2)
		MATCH (m) WHERE NOT (u1)-[:RATED]->(m:Movie) //Get only movies that user 1 hasn't rated yet
		RETURN cp, u1.userId, u2.userId, m.movieId, m.name, r3.rating, datetime({epochSeconds: r3.time})
		ORDER BY r3.rating DESC, r3.time DESC //sort by user 2 rating
		LIMIT 10

// Datetime formatting with apoc.date.format
MATCH (u:User {userId: "99997"})-[r:RATED]->(:Movie)-[:GENRE]->(g:Genre)
WITH count(r) AS ratesCount, max(r.time) as lastT, avg(toInteger(r.rating)) as ratesAvg, g.name as genre
RETURN ratesCount, ratesAvg, genre, apoc.date.format(lastT, 's', 'dd/MM/yyyy HH:mm') AS lastRated, //format date
       log10(ratesCount) * ratesAvg as score //calculate score
ORDER BY score DESC, lastT DESC //sort results by rates count and rating average descending

// Query top 10 users that rated Action movies.
MATCH (g:Genre { name: 'Action'})-[:GENRE]-(:Movie)-[r:RATED]-(u:User)
RETURN SUM(r.rating) as s, COUNT(*) AS c, AVG(r.rating) AS avg, u.userId, u.age, u.gender
ORDER BY avg DESC, s DESC, c DESC
LIMIT 10

// Query top 10 users that rated specific genres: Movie genres with most ratings
MATCH (g:Genre)-[:GENRE]-(:Movie)-[r:RATED]-(u:User)
RETURN g.name, SUM(r.rating) as s, COUNT(*) AS c, AVG(r.rating) AS avg, u.userId, u.age, u.gender
ORDER BY avg DESC, s DESC, c DESC
LIMIT 10

// Get rating statistics for genre by user gender 'F'
MATCH (:User { gender: 'F' })-[r:RATED]->(:Movie)-[:GENRE]-(g:Genre)
RETURN g.name, SUM(r.rating) as s, COUNT(*) AS c, AVG(r.rating) AS avg
ORDER BY avg DESC, s DESC, c DESC
LIMIT 10

// Find three possible "friends" of user id:1, by searching for users whose ratings match the most
MATCH (:User {userId: "1"})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating
	WITH count(m) as cm, u2
		ORDER BY cm desc
		LIMIT 3
		RETURN u2, cm

// Same query, but get also the movies they rated the same
MATCH (u1:User {userId: "1"})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = r2.rating
	WITH u1, count(m) as cm, u2
		ORDER BY cm desc
		LIMIT 3
			WITH u1, u2
			MATCH (u1)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2)
      WHERE r1.rating = r2.rating
			RETURN u1, m, u2
