# Recruiter Bot

This repository contains my submission for the Recruiterflow Backend Take-Home Assignment. It includes a custom-built API for matching candidates to jobs (Part 1) and raw SQL queries for the Detective Challenge (Part 2).

## Setup & Installation

**Prerequisites:** Node.js (v18+) and MySQL.

1. **Clone the repository and install dependencies:**
```bash
git clone <your-repo-link>
cd recruiter-bot
npm install
Configure Environment Variables:
Copy the example config and add your MySQL password:

Bash
cp .env.example .env
Initialize the Database:Warning: The seed script drops the recruiter_bot database if it already exists.

Bash
mysql -u root -p < seed.sql
Start the Server:

Bash
npm start
The API will be available at http://localhost:3000.

⚡ Testing the API
You can test the endpoints using the provided Postman collection (recruiterbot.postman_collection.json) or directly from your terminal using curl.

1. Get Top Candidates for a Job
Finds the best-matched candidates for a specific job (e.g., Job ID 4).

Bash
curl -X GET http://localhost:3000/jobs/4/matches
Postman Response Example:
![Get Matches for Job](./job-match.png)

2. Get Top Jobs for a Candidate
Finds the best-matched open roles for a specific candidate (e.g., Candidate ID 14).

Bash
curl -X GET http://localhost:3000/candidates/14/matches
Postman Response Example:
![Get Matches for Candidate](./candidate-match.png)

 Architecture & Trade-offs: What I Chose and Why
To strictly adhere to the "no ORMs or query builders" constraint while building a performant and readable application, I had to make several deliberate architectural choices:

1. In-Memory Scoring vs. Database Scoring

What I chose: I pull the entity data from MySQL and run the matching algorithm (weights, regex parsing, synonym mapping) entirely in Node.js memory.

Why: Writing complex business logic—especially regex-based availability parsing and dictionary synonym mapping—is incredibly verbose and brittle in raw SQL. Node.js is much better suited for handling this unstructured string manipulation cleanly.

The Trade-off: Fetching the entire counterpart table into memory works perfectly for a dataset of this size, but it does not scale infinitely. In a massive production environment with millions of candidates, this would cause memory bottlenecks. To scale this, I would implement an inverted index table in MySQL to pre-filter candidates by hard requirements (like minimum experience) before passing a paginated subset to Node.js for the final weighted scoring.

2. Single Query with GROUP_CONCAT vs. Multiple Queries

What I chose: I used GROUP_CONCAT(DISTINCT s.name SEPARATOR '|') to fetch a job/candidate and all their associated skills in a single database round-trip.

Why: The most common trap when avoiding ORMs is accidentally creating an N+1 query problem (e.g., looping through 50 candidates and firing 50 separate queries to fetch their skills). Pushing the aggregation to the database layer keeps the API lightning-fast.

The Trade-off: MySQL has a default group_concat_max_len limit of 1024 bytes. If a candidate had an absurdly long list of skills, MySQL would silently truncate the string. I accepted this limitation for the scope of this assignment, noting that in production, we would either increase the session limit or switch to a two-query approach (one for entities, one for a flattened list of all matched skills).

3. O(N) Filtering over Object Cleanliness

What I chose: Inside the algorithm, I temporarily attach a helper property (totalRequiredSkills) to every match object so that I can filter out zero-skill matches in a single, flat O(N) loop later.

Why: Initially, checking if a job required skills during the filtering phase required a nested .find() lookup, creating an O(N²) time complexity bottleneck.

The Trade-off: I am temporarily polluting the JavaScript object with backend-only data. To ensure the frontend consumer doesn't see this messy internal logic, I map over the final array and explicitly set totalRequiredSkills: undefined before sending the JSON response. I traded a tiny bit of memory overhead for a massive gain in CPU time complexity.

Matching Algorithm: Decisions & Edge Cases
Building a matching engine required balancing strict technical qualifications with softer, unstructured data like culture fit and availability. I designed the algorithm on a 100-point scale, broken down into four weighted categories: Skills (50%), Experience (25%), Culture Fit (13%), and Availability (12%).

Key Decisions & Edge Cases Checked:

The "Skill Gate" Penalty: I implemented a mathematical gate to ensure that a candidate with great "vibes" but zero skills cannot outrank a technical match. Zero-skill candidates are explicitly filtered out to reduce recruiter noise.

Culture Synonym Mapping: I used Sets to deduplicate messy input arrays, and created a robust canon dictionary (e.g., "tenacious" -> "persistent") checking with Object.hasOwn() to catch overlapping traits safely.

Availability Parsing: Regex is used to accurately weigh "2 weeks" vs "1 month", and candidates who explicitly state "not looking" receive a massive penalty multiplier to tank their ranking.

Deterministic Tie-Breaking: Raw fractional scores are retained internally to prevent mass ties. If ties still occur, they are broken by total raw skills matched, followed by DB ID.

Note on AI Usage
I utilized AI tools (ChatGPT/Gemini) as a sounding board during this project. I primarily used them to sanity-check the regex for the availability parser, help structure the RANK() OVER() window function in Part 2, and catch logical edge cases (like how negative experience integers or zero-req jobs could skew the algorithm). All final implementations, DB designs, and architectural decisions are my own.

Repository Structure
app.js - Main Express server and algorithmic logic.

db.js - MySQL connection pool configuration.

seed.sql - Raw DDL and insert statements.

sql_detective.sql - Solutions for Part 2.

recruiterbot.postman_collection.json - Ready-to-import Postman workspace.