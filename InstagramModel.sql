
CREATE TABLE status (
	id serial PRIMARY KEY,
	title VARCHAR(20)
)

CREATE TABLE users (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	username VARCHAR(30) UNIQUE NOT NULL,
	bio VARCHAR(400),
	avatar VARCHAR(200),
	phone VARCHAR(25),
	email VARCHAR(40) UNIQUE,
	password VARCHAR(50),
	status_id INTEGER REFERENCES status(id) ON DELETE CASCADE,
	CHECK(COALESCE(phone, email) IS NOT NULL)
);


CREATE TABLE posts (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	url VARCHAR(200) NOT NULL UNIQUE,
	caption VARCHAR(240),
	latitude REAL CHECK(latitude is NULL OR (latitude >= -90 and latitude <= 90)),
	longitude REAL CHECK(longitude is NULL OR (longitude >= -180 and longitude <= 180)),
	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
)

CREATE TABLE comments (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	contents VARCHAR(240) NOT NULL,
	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE
);

CREATE TABLE likes (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
	comment_id INTEGER REFERENCES comments(id) ON DELETE CASCADE,
	CHECK (
		COALESCE((post_id)::BOOLEAN::INTEGER, 0)
		+
		COALESCE((comment_id)::BOOLEAN::INTEGER, 0)
		= 1
	),
	UNIQUE(post_id, comment_id, user_id)
);

CREATE TABLE tagged_user (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
	UNIQUE(user_id, post_id)
); 

CREATE TABLE hashtags (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	title VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE post_hashtags (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	title VARCHAR(20) NOT NULL UNIQUE
);

ALTER TABLE post_hashtags ADD post_id int REFERENCES posts(id) ON DELETE CASCADE;
ALTER TABLE post_hashtags ADD hashtag_id int REFERENCES hashtags(id) ON DELETE CASCADE;

ALTER TABLE post_hashtags ADD CONSTRAINT ph_validation_check UNIQUE(post_id, user_id);

CREATE TABLE comment_hashtags (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	title VARCHAR(20) NOT NULL UNIQUE,
	hashtag_id int REFERENCES hashtags(id) ON DELETE CASCADE,
	post_id int REFERENCES posts(id) ON DELETE CASCADE,
	UNIQUE(post_id, user_id)
);


CREATE TABLE bio_hashtags (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	title VARCHAR(20) NOT NULL UNIQUE,
	hashtag_id int REFERENCES hashtags(id) ON DELETE CASCADE,
	post_id int REFERENCES posts(id) ON DELETE CASCADE,
	UNIQUE(post_id, user_id)
);

CREATE TABLE followers (
	id serial PRIMARY KEY,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	leader_id int NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	follower_id int NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	UNIQUE (leader_id, follower_id)
)

CREATE INDEX users_username_idx ON users(username);

-- Getting all indices in database

SELECT relname from pg_class where relkind='i';

-- 	Benchmarking using the index 

-- 		With index it took 0.046 ms
--		Without index it took 1.5 ms

EXPLAIN ANALYSE SELECT *
FROM users where username='Emil30';

-- Size consumed by the users table is 872 Kb

SELECT pg_size_pretty(pg_relation_size('users')) as size_consumed;

-- Size consumed by the index of the users table is 184 Kb

SELECT pg_size_pretty(pg_relation_size('users_username_idx')) as size_consumed;

-- Benchmarking

EXPLAIN SELECT username FROM users JOIN comments ON comments.id = users.id where users.username='Alyson14'; 	-- Explain alone will giveout statistics and not execute the query.

EXPLAIN ANALYSE SELECT username FROM users JOIN comments ON comments.id = users.id where users.username='Alyson14'; 	-- Explain analyse will giveout statistics and execute the query.

-- Simple Common Table Expression

WITH tags AS (
	SELECT user_id, created_at FROM caption_tags
	UNION ALL
	SELECT user_id, created_at FROM photo_tags
)
SELECT username, tags.created_at 
FROM users 
JOIN tags ON users.id = tags.user_id
WHERE tags.created_at < '2010-01-07';

-- Recursive Common Table Expression

WITH RECURSIVE countdown(val) AS (
	SELECT 5 AS val   							-- Initial value
	UNION
	SELECT val-1 FROM countdown WHERE val > 1 	-- Recursive function
)

SELECT * FROM COUNTDOWN;