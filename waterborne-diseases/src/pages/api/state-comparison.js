import { supabase } from '../../supabaseClient';

export default async function handler(req, res) {
    if (req.method !== 'GET') {
        return res.status(405).json({ message: 'Method not allowed' });
    }

    // Aggregate stats: Total cases per state
    // Since we can't do complex group by easily with basic client without RPC, 
    // we might fetch raw data and aggregate in JS or use a view.
    // For now, let's assume we fetch all active reports and aggregate.

    const { data: reports, error } = await supabase
        .from('disease_reports')
        .select('state, total_cases, disease_name');

    if (error) {
        return res.status(500).json({ error: error.message });
    }

    // Aggregate in JS
    const stateStats = {};

    reports.forEach(report => {
        if (!stateStats[report.state]) {
            stateStats[report.state] = {
                state: report.state,
                total_cases: 0,
                cases_by_disease: {}
            };
        }
        stateStats[report.state].total_cases += report.total_cases;

        if (!stateStats[report.state].cases_by_disease[report.disease_name]) {
            stateStats[report.state].cases_by_disease[report.disease_name] = 0;
        }
        stateStats[report.state].cases_by_disease[report.disease_name] += report.total_cases;
    });

    const result = Object.values(stateStats).sort((a, b) => b.total_cases - a.total_cases);

    return res.status(200).json(result);
}
