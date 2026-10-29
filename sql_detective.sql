-- 1. List all currently open job postings, along with the name of the recruiter who owns each one.
SELECT 
    j.title AS job_title, 
    j.department,
    r.name AS recruiter_name
FROM job_postings j
JOIN recruiters r ON j.recruiter_id = r.id
WHERE LOWER(TRIM(j.status)) = 'open';

-- 2. For each job posting, how many distinct applicants reached the Final interview stage?
SELECT 
    j.id AS job_id,
    j.title AS job_title, 
    COUNT(DISTINCT i.applicant_id) AS final_stage_applicants
FROM job_postings j
LEFT JOIN interviews i 
    ON j.id = i.job_posting_id 
    AND LOWER(TRIM(i.stage)) = 'final'
GROUP BY 
    j.id, 
    j.title;

-- 3. Find every person who applied to more than one job posting (handling dirty email/name data).
SELECT 
    MIN(a.full_name) AS canonical_name,
    REPLACE(LOWER(a.email), ' ', '') AS cleaned_email,
    COUNT(DISTINCT i.job_posting_id) AS distinct_jobs_applied
FROM applicants a
JOIN interviews i ON a.id = i.applicant_id
GROUP BY 
    cleaned_email
HAVING 
    COUNT(DISTINCT i.job_posting_id) > 1;

-- 4. For each recruiter, compute their Final-stage conversion rate (only counting resolved interviews).
SELECT 
    r.name AS recruiter_name,
    COUNT(i.id) AS resolved_final_interviews,
    SUM(CASE WHEN LOWER(TRIM(i.outcome)) = 'passed' THEN 1 ELSE 0 END) AS passed_final_interviews,
    ROUND(SUM(CASE WHEN LOWER(TRIM(i.outcome)) = 'passed' THEN 1.0 ELSE 0.0 END) / COUNT(i.id) * 100, 2) AS conversion_rate_percentage
FROM recruiters r
JOIN job_postings j ON r.id = j.recruiter_id
JOIN interviews i ON j.id = i.job_posting_id
WHERE 
    LOWER(TRIM(i.stage)) = 'final'
    AND i.outcome IS NOT NULL
GROUP BY 
    r.id, 
    r.name
HAVING 
    COUNT(i.id) >= 3;

-- 5. (Bonus) Using a window function, find the recruiter with the most successful placements per department.
WITH PlacementCounts AS (
    SELECT 
        j.department,
        r.name AS recruiter_name,
        COUNT(DISTINCT i.applicant_id) AS successful_placements,
        RANK() OVER (PARTITION BY j.department ORDER BY COUNT(DISTINCT i.applicant_id) DESC) as placement_rank
    FROM recruiters r
    JOIN job_postings j ON r.id = j.recruiter_id
    JOIN interviews i ON j.id = i.job_posting_id
    WHERE 
        LOWER(TRIM(i.stage)) = 'final' 
        AND LOWER(TRIM(i.outcome)) = 'passed'
    GROUP BY 
        j.department, 
        r.id, 
        r.name
)
SELECT 
    department, 
    recruiter_name, 
    successful_placements
FROM PlacementCounts
WHERE placement_rank = 1;