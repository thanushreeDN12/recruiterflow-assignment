import 'dotenv/config'; // Load env first
import express from 'express';
import pool from './db.js';

const app = express();

// Synonym mapping extended based on reviewer feedback
const SYNONYMS = {
    tenacious: 'persistent', resilient: 'persistent',
    enthusiastic: 'energetic', optimistic: 'energetic',
    brilliant: 'analytical', 'detail-oriented': 'organized',
    'calm-under-pressure': 'calm',
    autonomous: 'proactive', 'self-starter': 'proactive',
    'fast-paced': 'agile', curious: 'inquisitive'
};

const canon = (word) => SYNONYMS[word] || word;
const splitStr = (str) => (str ? str.split(',').map(w => w.trim().toLowerCase()).filter(Boolean) : []);
const isId = (value) => /^\d+$/.test(value);

function getAvailabilityScore(availText) {
    if (!availText) return 0.5;
    const text = availText.toLowerCase().trim();
    
    if (text.includes('not looking')) return 0;
    if (text.includes('immediate')) return 1.0;
    
    const match = text.match(/(\d+)\s*(week|month)/);
    if (match) {
        const days = match[2] === 'week' ? parseInt(match[1]) * 7 : parseInt(match[1]) * 30;
        if (days <= 14) return 0.85;
        if (days <= 30) return 0.70;
        if (days <= 60) return 0.50;
        return 0.30;
    }
    return 0.5;
}

function scoreMatch(candidate, job) {
    // 1. Skills (50%)
    const cSkills = candidate.skills || [];
    const jSkills = job.skills || [];
    const matched = jSkills.filter(s => cSkills.includes(s));
    const missing = jSkills.filter(s => !cSkills.includes(s));
    const skillScore = jSkills.length ? matched.length / jSkills.length : 1; // Neutral if no skills required

    // 2. Experience (25%) - Clamp negative years to 0
    let expScore = 1;
    const validExp = Math.max(0, candidate.experience_years || 0);
    if (job.min_experience > 0 && validExp < job.min_experience) {
        expScore = validExp / job.min_experience; 
    }

    // 3. Culture (13%) - Deduplicate using Sets
    const cTraits = [...new Set(splitStr(candidate.traits).map(canon))];
    const jCulture = [...new Set(splitStr(job.culture_keywords))];
    const shared = jCulture.filter(w => cTraits.includes(canon(w)));
    const cultureScore = (cTraits.length && jCulture.length) ? (shared.length / jCulture.length) : 0.5;

    // 4. Availability (12%)
    const availText = (candidate.availability || '').toLowerCase().trim();
    const availScore = getAvailabilityScore(availText);

    // Final weighted score calculation
    let baseTotal = (skillScore * 0.5) + (expScore * 0.25) + (cultureScore * 0.13) + (availScore * 0.12);
    let finalScore = (baseTotal * (0.3 + 0.7 * skillScore)) * 100;
    
    // Hard penalty: If they are explicitly not looking, tank their score
    if (availText.includes('not looking')) finalScore *= 0.2;

    // Keep precision for tie-breaking internally
    const rawScore = finalScore;
    const displayScore = Math.round(finalScore);

    // Human-readable reason
    let reason = `Matched ${matched.length}/${jSkills.length} skills`;
    if (missing.length) reason += ` (missing: ${missing.join(', ')})`;
    reason += `, ${validExp} vs ${job.min_experience} yrs`;
    if (availText === 'not looking') reason += ', not looking right now';
    else if (availText) reason += `, available: ${candidate.availability}`;
    if (shared.length) reason += `, culture fit: ${shared.join('/')}`;
    reason += '.';

    return { 
            rawScore, 
            score: displayScore, 
            reason, 
            skillsMatched: matched.length, 
            totalRequiredSkills: jSkills.length 
        };
}

// Fixed duplicated SQL and GROUP_CONCAT limits/delimiters
// Database helper to fetch entities and aggregate skills
// Uses '|' separator to safely split skill names that might contain commas.
// Note: Assumes skills list fits within MySQL's default 1024-byte group_concat_max_len.
async function getEntities(type, id = null) {
    const isCand = type === 'candidates';
    const idCol = isCand ? 'candidate_id' : 'job_id';
    const sql = `
        SELECT t.*, GROUP_CONCAT(DISTINCT s.name SEPARATOR '|') AS skills
        FROM ${type} t
        LEFT JOIN ${isCand ? 'candidate_skills' : 'job_skills'} ts ON ts.${idCol} = t.id
        LEFT JOIN skills s ON s.id = ts.skill_id
        ${id ? 'WHERE t.id = ?' : ''}
        GROUP BY t.id
    `;
    const [rows] = await pool.query(sql, id ? [id] : []);
    return rows.map(r => ({ ...r, skills: r.skills ? r.skills.toLowerCase().split('|') : [] }));
}

app.get('/jobs/:id/matches', async (req, res) => {
    try {
        if (!isId(req.params.id)) return res.status(400).json({ error: 'Invalid job id' });

        const jobs = await getEntities('jobs', req.params.id);
        if (!jobs.length) return res.status(404).json({ error: 'Job not found' });
        const job = jobs[0];

        const candidates = await getEntities('candidates');
        let matches = candidates.map(c => ({
            candidate_id: c.id,
            name: c.name,
            ...scoreMatch(c, job)
        }));

        // Filter out zero-skill matches unless the job requires no skills
        matches = matches.filter(m => m.totalRequiredSkills === 0 || m.skillsMatched > 0);

        // Sort by raw decimal score, then skills matched, then ID
        matches.sort((a, b) => b.rawScore - a.rawScore || b.skillsMatched - a.skillsMatched || a.candidate_id - b.candidate_id);

        res.json({
            job_title: job.title,
            matches: matches.map((m, i) => ({ 
                rank: i + 1, 
                ...m, 
                rawScore: undefined, 
                skillsMatched: undefined,
                totalRequiredSkills: undefined // Fixed: Moved inside the mapped object
            }))
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Database error occurred during matching.' });
    }
});

app.get('/candidates/:id/matches', async (req, res) => {
    try {
        if (!isId(req.params.id)) return res.status(400).json({ error: 'Invalid candidate id' });

        const candidates = await getEntities('candidates', req.params.id);
        if (!candidates.length) return res.status(404).json({ error: 'Candidate not found' });
        const candidate = candidates[0];

        const jobs = await getEntities('jobs');
        let matches = jobs.map(j => ({
            job_id: j.id,
            title: j.title,
            ...scoreMatch(candidate, j)
        }));

        // O(N) Filter: out zero-skill matches unless the job requires no skills
        matches = matches.filter(m => m.totalRequiredSkills === 0 || m.skillsMatched > 0);

        matches.sort((a, b) => b.rawScore - a.rawScore || b.skillsMatched - a.skillsMatched || a.job_id - b.job_id);

        res.json({
            candidate_name: candidate.name,
            matches: matches.map((m, i) => ({ 
                rank: i + 1, 
                ...m, 
                rawScore: undefined, 
                skillsMatched: undefined,
                totalRequiredSkills: undefined // Hide the helper variable
            }))
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Database error occurred during matching.' });
    }
});

// Startup check
pool.query('SELECT 1').then(() => {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => console.log(`Recruiter Bot API running on port ${PORT}`));
}).catch(err => {
    console.error('Failed to connect to MySQL database. Check your .env file.', err);
    process.exit(1);
});