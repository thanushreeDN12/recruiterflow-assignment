# Recruiter Bot (Backend Take-Home Assignment)

This repository contains my submission for the Recruiterflow Backend Take-Home Assignment. It includes a custom-built API for matching candidates to jobs (Part 1) and raw SQL queries for the Detective Challenge (Part 2).

## 🚀 Setup & Installation

**Prerequisites:** Node.js (v18+) and MySQL.

1. **Clone the repository and install dependencies:**
```bash
git clone <your-repo-link>
cd recruiter-bot
npm install
```

2. **Configure Environment Variables:**
Copy the example config and add your MySQL password:
```bash
cp .env.example .env
```

3. **Initialize the Database:**
*Warning: The seed script drops the `recruiter_bot` database if it already exists.*
```bash
mysql -u root -p < seed.sql
```

4. **Start the Server:**
```bash
npm start
```
The API will be available at `http://localhost:3000`.

## 🧠 Matching Algorithm: Decisions & Trade-offs

Building a matching engine required balancing strict technical qualifications with softer, unstructured data like culture fit and availability. I designed the algorithm on a 100-point scale, broken down into four weighted categories: **Skills (50%)**, **Experience (25%)**, **Culture Fit (13%)**, and **Availability (12%)**.

**Key Decisions & Edge Cases Checked:**
*   **The "Skill Gate" Penalty:** I implemented a mathematical gate to ensure that a candidate with great "vibes" but zero skills cannot outrank a technical match. Zero-skill candidates are explicitly filtered out to reduce recruiter noise.
*   **Culture Synonym Mapping:** I used Sets to deduplicate messy input arrays, and created a `SYNONYMS` dictionary (e.g., "tenacious" -> "persistent") to catch overlapping traits.
*   **Availability Parsing:** Regex is used to accurately weigh "2 weeks" vs "1 month", and candidates who explicitly state "not looking" receive a massive penalty multiplier to tank their ranking.
*   **Deterministic Tie-Breaking:** Raw fractional scores are retained internally to prevent mass ties. If ties still occur, they are broken by total raw skills matched, followed by DB ID.

**Trade-offs:**
To strictly adhere to the "no ORMs/query builders" rule, I fetch entities using raw `GROUP_CONCAT` queries with a custom `|` separator. While this avoids the N+1 query problem by pushing aggregation to the database layer, it currently evaluates all matches in server memory. For a massive production dataset, this would need pagination pushed to the SQL layer via inverted index tables.

## 🤖 Note on AI Usage

I utilized AI tools (ChatGPT/Gemini) as a sounding board during this project. I primarily used them to sanity-check the regex for the availability parser, help structure the `RANK() OVER()` window function in Part 2, and catch logical edge cases (like how negative experience integers or zero-req jobs could skew the algorithm). All final implementations, DB designs, and architectural decisions are my own.

## 📁 Repository Structure
*   `app.js` - Main Express server and algorithmic logic.
*   `db.js` - MySQL connection pool configuration.
*   `seed.sql` - Raw DDL and insert statements.
*   `sql_detective.sql` - Solutions for Part 2.