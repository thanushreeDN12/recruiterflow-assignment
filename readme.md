Recruiter Bot

A candidate ↔ job matching API built for the Recruiterflow Backend Take-Home Assignment.

Part 1: REST API that ranks candidates for a job (and jobs for a candidate) using a weighted scoring algorithm.
Part 2: Raw SQL solutions for the Detective Challenge.

Stack: Node.js · Express · MySQL (raw SQL, no ORMs or query builders)

Table of Contents
Setup & Installation
API Reference
Matching Algorithm
Architecture & Trade-offs
Note on AI Usage
Repository Structure
Setup & Installation

Prerequisites: Node.js v18+ and MySQL.

1. Clone the repository and install dependencies

bash
git clone https://github.com/thanushreeDN12/recruiterflow-assignment.git
cd recruiterflow-assignment
npm install

2. Configure environment variables

Copy the example config and add your MySQL password:

bash
cp .env.example .env

3. Initialize the database

Warning: the seed script drops the recruiter_bot database if it already exists.

bash
mysql -u root -p < seed.sql

4. Start the server

bash
npm start

The API is now available at http://localhost:3000.

API Reference

Test with the included Postman collection (recruiterbot.postman_collection.json) or with curl.

Method	Endpoint	Description
GET	/jobs/:id/matches	Top candidates for a job
GET	/candidates/:id/matches	Top open jobs for a candidate
1. Top candidates for a job

Returns the best-matched candidates for a job (example: Job ID 4).

bash
curl -X GET http://localhost:3000/jobs/4/matches

Get Matches for Job
![Get Matches for Job](https://raw.githubusercontent.com/thanushreeDN12/recruiterflow-assignment/main/assets/job-match.png)

2. Top jobs for a candidate

Returns the best-matched open roles for a candidate (example: Candidate ID 14).

bash
curl -X GET http://localhost:3000/candidates/14/matches

Get Matches for Candidate
![Get Matches for Candidate](https://raw.githubusercontent.com/thanushreeDN12/recruiterflow-assignment/main/assets/candidate-match.png)

Matching Algorithm

Matching balances hard technical qualifications against softer, unstructured signals like culture fit and availability. Every match is scored on a 100-point scale:

Category	Weight
Skills	50%
Experience	25%
Culture Fit	13%
Availability	12%
Key decisions & edge cases
Skill gate: a candidate with great "vibes" but zero matching skills can never outrank a technical match. Zero-skill matches are filtered out entirely to cut recruiter noise.
Culture synonym mapping: Sets deduplicate messy input arrays, and a canonical dictionary (e.g. "tenacious" → "persistent") normalizes traits, checked safely with Object.hasOwn().
Availability parsing: regex distinguishes "2 weeks" from "1 month", and candidates who state they are "not looking" receive a heavy penalty multiplier that sinks their ranking.
Deterministic tie-breaking: raw fractional scores are kept internally to avoid mass ties. Remaining ties are broken by total raw skills matched, then by DB ID.

Architecture & Trade-offs

Given the "no ORMs or query builders" constraint, these were the deliberate choices:

1. In-memory scoring vs. database scoring
Chosen: pull entity data from MySQL and run the matching algorithm (weights, regex parsing, synonym mapping) in Node.js memory.
Why: regex-based availability parsing and dictionary synonym mapping are verbose and brittle in raw SQL. Node.js handles unstructured string manipulation far more cleanly.
Trade-off: loading the entire counterpart table into memory works at this dataset size but doesn't scale indefinitely. With millions of candidates, I would add an inverted index table in MySQL to pre-filter by hard requirements (e.g. minimum experience) and pass a paginated subset to Node.js for final weighted scoring.
2. Single query with GROUP_CONCAT vs. multiple queries
Chosen: GROUP_CONCAT(DISTINCT s.name SEPARATOR '|') fetches a job/candidate and all associated skills in one round-trip.
Why: avoids the classic N+1 trap (e.g. 50 candidates → 50 extra skill queries). Aggregating in the database keeps the API fast.
Trade-off: MySQL's default group_concat_max_len is 1024 bytes and silently truncates beyond it. Accepted for this scope; in production I would raise the session limit or use two queries (entities + a flattened skill list).
3. O(N) filtering over object cleanliness
Chosen: temporarily attach a helper property (totalRequiredSkills) to each match so zero-skill matches can be filtered in a single flat O(N) pass.
Why: looking up required skills with a nested .find() during filtering made it O(N²).
Trade-off: this temporarily pollutes the object with backend-only data. Before responding, I map over the final array and set totalRequiredSkills: undefined so it never reaches the API consumer. A little memory overhead buys a large CPU saving.
Note on AI Usage

I used AI tool as a sounding board. Specifically, to:

sanity-check the regex for the availability parser and
catch logical edge cases (e.g. negative experience values or zero-requirement jobs skewing the algorithm).

All final implementations, database designs, and architectural decisions are my own.

Repository Structure
text
.
├── app.js                                  # Express server + matching algorithm
├── db.js                                   # MySQL connection pool config
├── seed.sql                                # DDL and seed data
├── sql_detective.sql                       # Part 2 solutions
├── recruiterbot.postman_collection.json    # Ready-to-import Postman collection
├── assets/                                 # README screenshots
│   ├── job-match.png
│   └── candidate-match.png
├── .env.example
├── package.json
└── README.md