import { supabase } from '../../supabaseClient';

export default async function handler(req, res) {
    if (req.method !== 'GET') {
        return res.status(405).json({ message: 'Method not allowed' });
    }

    const { state, severity, limit } = req.query;

    let query = supabase
        .from('disease_reports')
        .select('*')
        .order('total_cases', { ascending: false });

    if (state) {
        query = query.eq('state', state);
    }

    if (severity) {
        query = query.eq('severity', severity);
    }

    if (limit) {
        query = query.limit(parseInt(limit));
    }

    const { data, error } = await query;

    if (error) {
        return res.status(500).json({ error: error.message });
    }

    return res.status(200).json(data);
}
