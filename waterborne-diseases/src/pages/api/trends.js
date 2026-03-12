import { supabase } from '../../supabaseClient';

export default async function handler(req, res) {
    if (req.method !== 'GET') {
        return res.status(405).json({ message: 'Method not allowed' });
    }

    const { disease, year } = req.query;

    let query = supabase
        .from('monthly_trends')
        .select('*')
        .order('created_at', { ascending: true }); // Assuming 'month' ordering logic needs to be handled or verify 'created_at'

    if (disease) {
        query = query.eq('disease_name', disease);
    }

    if (year) {
        query = query.eq('year', parseInt(year));
    }

    const { data, error } = await query;

    if (error) {
        return res.status(500).json({ error: error.message });
    }

    return res.status(200).json(data);
}
