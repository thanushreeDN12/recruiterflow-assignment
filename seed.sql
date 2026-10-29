DROP DATABASE IF EXISTS recruiter_bot;
CREATE DATABASE recruiter_bot;
USE recruiter_bot;


CREATE TABLE candidates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    experience_years INT NOT NULL,
    availability VARCHAR(50),
    traits VARCHAR(255),
    quirk TEXT
);

CREATE TABLE jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    min_experience INT NOT NULL,
    culture_keywords VARCHAR(255),
    tagline TEXT
);

CREATE TABLE skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE candidate_skills (
    candidate_id INT,
    skill_id INT,
    PRIMARY KEY (candidate_id, skill_id),
    FOREIGN KEY (candidate_id) REFERENCES candidates(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
);

CREATE TABLE job_skills (
    job_id INT,
    skill_id INT,
    PRIMARY KEY (job_id, skill_id),
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
);


-- Insert Candidates
INSERT INTO candidates (name, experience_years, availability, traits, quirk) VALUES
('Sherlock H.', 8, 'Immediate', 'analytical, blunt', 'Solves problems by eliminating the impossible; occasionally insufferable in standups.'),
('Hermione G.', 4, '2 weeks', 'detail-oriented, overachiever', 'Reads the entire documentation before writing a single line of code.'),
('Tony S.', 12, 'Not looking', 'confident, innovative', 'Ships an MVP overnight, refuses to write tests.'),
('Leslie K.', 6, 'Immediate', 'tenacious, organized', 'Has a binder for everything, including the binder.'),
('Ron S.', 15, 'Not looking', 'stubborn, principled', 'None'),
('Rick S.', 20, 'Immediate', 'genius, reckless', 'Refuses to use more than one monitor. Solution works, mechanism deeply concerning.'),
('Elle W.', 3, 'Immediate', 'optimistic, sharp', 'Underestimated in every standup, correct in every retro.'),
('MacGyver', 10, '2 weeks', 'calm, improviser', 'Fixes production outages with duct tape and a paperclip metaphor.'),
('Sheldon C.', 9, 'Immediate', 'rigid, brilliant', 'Correct 95% of the time, insufferable 100% of the time.'),
('Katniss E.', 5, 'Immediate', 'resilient, decisive', 'Excellent under pressure, terrible with public speaking.'),
('Michael S.', 11, 'Not looking', 'enthusiastic, chaotic', 'World''s best boss, according to a mug he bought himself.'),
('Olivia P.', 13, '2 weeks', 'decisive, intense', 'Handles it. Whatever it is.'),
('Ted L.', 7, 'Immediate', 'empathetic, persistent', 'Turns every technical setback into a folksy metaphor.'),
('Miranda P.', 18, 'Not looking', 'demanding, decisive', 'Reviews every PR personally. Says nothing. Everyone panics.'),
('Dwight S.', 9, 'Immediate', 'intense, loyal', 'Assistant to the regional backend engineer.');

-- Insert Jobs
INSERT INTO jobs (title, min_experience, culture_keywords, tagline) VALUES
('Backend Detective', 3, 'analytical, autonomous', 'We have a bug. We have no leads. We have you.'),
('Rapid Prototyping Engineer', 2, 'innovative, fast-paced', 'Ship first, document never (kidding - please document).'),
('Developer Relations Lead', 2, 'energetic, curious', 'Explain complex things to confused humans, cheerfully.'),
('Engineering Manager, Chaos Team', 5, 'empathetic, organized', 'Herd cats. The cats are senior engineers.'),
('Incident Commander', 4, 'decisive, calm-under-pressure', '3am page. You''re the one who picks up.'),
('Sales Engineer', 3, 'enthusiastic, persistent', 'Sell the vision, then go build it.');

-- Insert Skills Dictionary
INSERT INTO skills (name) VALUES 
('deduction'), ('pattern-recognition'), ('forensics'), ('research'), 
('time-management'), ('public-speaking'), ('systems-design'), 
('rapid-prototyping'), ('leadership'), ('project-management'), 
('stakeholder-management'), ('woodworking'), ('minimalism'), 
('negotiation'), ('chemistry'), ('persuasion'), ('resourcefulness'), 
('theoretical-analysis'), ('precision'), ('strategy'), 
('crisis-management'), ('sales'), ('team-building'), ('optimism'), 
('mentorship'), ('security'), ('loyalty');

-- Map Candidate Skills
INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Sherlock H.' AND s.name IN ('deduction', 'pattern-recognition', 'forensics');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Hermione G.' AND s.name IN ('research', 'time-management', 'public-speaking');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Tony S.' AND s.name IN ('systems-design', 'rapid-prototyping', 'leadership');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Leslie K.' AND s.name IN ('project-management', 'stakeholder-management', 'public-speaking');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Ron S.' AND s.name IN ('woodworking', 'minimalism', 'negotiation');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Rick S.' AND s.name IN ('systems-design', 'rapid-prototyping', 'chemistry');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Elle W.' AND s.name IN ('persuasion', 'research', 'public-speaking');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'MacGyver' AND s.name IN ('rapid-prototyping', 'resourcefulness', 'chemistry', 'systems-design');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Sheldon C.' AND s.name IN ('theoretical-analysis', 'pattern-recognition', 'research');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Katniss E.' AND s.name IN ('precision', 'strategy', 'crisis-management');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Michael S.' AND s.name IN ('sales', 'public-speaking', 'team-building');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Olivia P.' AND s.name IN ('crisis-management', 'negotiation', 'strategy', 'leadership');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Ted L.' AND s.name IN ('team-building', 'optimism', 'mentorship', 'public-speaking');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Miranda P.' AND s.name IN ('leadership', 'negotiation', 'stakeholder-management', 'precision');

INSERT INTO candidate_skills (candidate_id, skill_id)
SELECT c.id, s.id FROM candidates c, skills s WHERE c.name = 'Dwight S.' AND s.name IN ('sales', 'negotiation', 'security', 'loyalty');

-- Map Job Skills
INSERT INTO job_skills (job_id, skill_id)
SELECT j.id, s.id FROM jobs j, skills s WHERE j.title = 'Backend Detective' AND s.name IN ('deduction', 'pattern-recognition', 'forensics');

INSERT INTO job_skills (job_id, skill_id)
SELECT j.id, s.id FROM jobs j, skills s WHERE j.title = 'Rapid Prototyping Engineer' AND s.name IN ('rapid-prototyping', 'systems-design');

INSERT INTO job_skills (job_id, skill_id)
SELECT j.id, s.id FROM jobs j, skills s WHERE j.title = 'Developer Relations Lead' AND s.name IN ('public-speaking', 'research');

INSERT INTO job_skills (job_id, skill_id)
SELECT j.id, s.id FROM jobs j, skills s WHERE j.title = 'Engineering Manager, Chaos Team' AND s.name IN ('team-building', 'stakeholder-management', 'leadership');

INSERT INTO job_skills (job_id, skill_id)
SELECT j.id, s.id FROM jobs j, skills s WHERE j.title = 'Incident Commander' AND s.name IN ('crisis-management', 'strategy', 'negotiation');

INSERT INTO job_skills (job_id, skill_id)
SELECT j.id, s.id FROM jobs j, skills s WHERE j.title = 'Sales Engineer' AND s.name IN ('sales', 'public-speaking', 'negotiation');