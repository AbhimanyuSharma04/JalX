const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Read .env file manually since dotenv might not be installed
const envPath = path.join(__dirname, '../.env');
const envContent = fs.readFileSync(envPath, 'utf8');
const envConfig = {};
envContent.split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) {
        envConfig[key.trim()] = value.trim();
    }
});

const supabaseUrl = envConfig['REACT_APP_SUPABASE_URL'];
const supabaseKey = envConfig['REACT_APP_SUPABASE_ANON_KEY'];

if (!supabaseUrl || !supabaseKey) {
    console.error('Supabase credentials not found in .env');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

const diseaseReportsRaw = [
    { disease_name: 'Gastroenteritis', state: 'Uttar Pradesh', latitude: 26.8467, longitude: 80.9462, total_cases: 95000, weekly_growth_rate: 25.5 },
    { disease_name: 'Cholera', state: 'West Bengal', latitude: 22.5726, longitude: 88.3639, total_cases: 88000, weekly_growth_rate: 22.1 },
    { disease_name: 'Typhoid', state: 'Maharashtra', latitude: 19.0760, longitude: 72.8777, total_cases: 75000, weekly_growth_rate: 20.8 },
    { disease_name: 'Hepatitis A', state: 'Bihar', latitude: 25.0961, longitude: 85.3131, total_cases: 62000, weekly_growth_rate: 18.2 },
    { disease_name: 'Gastroenteritis', state: 'Gujarat', latitude: 23.0225, longitude: 72.5714, total_cases: 55000, weekly_growth_rate: 16.5 },
    { disease_name: 'Typhoid', state: 'Punjab', latitude: 30.7333, longitude: 76.7794, total_cases: 48000, weekly_growth_rate: 15.3 }
];

function computeSeverity(cases, growthRate) {
    if (cases > 50000 || growthRate > 30) return 'critical';
    if (cases > 20000) return 'high';
    if (cases > 5000) return 'medium';
    return 'low';
}

const diseaseReports = diseaseReportsRaw.map(report => ({
    ...report,
    severity: computeSeverity(report.total_cases, report.weekly_growth_rate),
    last_updated: new Date()
}));

const monthlyTrends = [
    { disease_name: 'Diarrhea', month: 'Jan', year: 2025, cases: 12000 },
    { disease_name: 'Cholera', month: 'Jan', year: 2025, cases: 8500 },
    { disease_name: 'Typhoid', month: 'Jan', year: 2025, cases: 6500 },
    { disease_name: 'Hepatitis A', month: 'Jan', year: 2025, cases: 4500 },

    { disease_name: 'Diarrhea', month: 'Feb', year: 2025, cases: 15000 },
    { disease_name: 'Cholera', month: 'Feb', year: 2025, cases: 9500 },
    { disease_name: 'Typhoid', month: 'Feb', year: 2025, cases: 7500 },
    { disease_name: 'Hepatitis A', month: 'Feb', year: 2025, cases: 5500 },

    { disease_name: 'Diarrhea', month: 'Mar', year: 2025, cases: 20000 },
    { disease_name: 'Cholera', month: 'Mar', year: 2025, cases: 12000 },
    { disease_name: 'Typhoid', month: 'Mar', year: 2025, cases: 10000 },
    { disease_name: 'Hepatitis A', month: 'Mar', year: 2025, cases: 7000 },
    // Add more months as needed based on the hardcoded data in Dashboard_copy.js
];

const emergencyStatus = [
    { disease_name: 'Gastroenteritis', state: 'Uttar Pradesh', severity: 'critical', response_status: 'active' },
    { disease_name: 'Cholera', state: 'West Bengal', severity: 'high', response_status: 'monitoring' },
    { disease_name: 'Typhoid', state: 'Maharashtra', severity: 'medium', response_status: 'monitoring' },
    { disease_name: 'Hepatitis A', state: 'Bihar', severity: 'low', response_status: 'resolved' }
];

async function seed() {
    console.log('Seeding disease_reports...');
    const { error: error1 } = await supabase.from('disease_reports').upsert(diseaseReports, { onConflict: 'state,disease_name' }); // Assuming unique constraint or just insert
    // Note: upsert requires a unique constraint. If not present, we should delete then insert or just insert. 
    // Since schema doesn't strictly define unique constraint on state+disease, ID is primary key. Clean table first?
    // Let's delete all first for idempotent seed.
    await supabase.from('disease_reports').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await supabase.from('disease_reports').insert(diseaseReports);

    console.log('Seeding monthly_trends...');
    await supabase.from('monthly_trends').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await supabase.from('monthly_trends').insert(monthlyTrends);

    console.log('Seeding emergency_status...');
    await supabase.from('emergency_status').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await supabase.from('emergency_status').insert(emergencyStatus);

    console.log('Seeding completed.');
}

seed();
