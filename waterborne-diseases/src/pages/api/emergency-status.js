import { supabase } from '../../supabaseClient';

export default async function handler(req, res) {
    if (req.method === 'GET') {
        const { state } = req.query;

        let query = supabase
            .from('emergency_status')
            .select('*');

        if (state) {
            query = query.eq('state', state);
        }

        const { data, error } = await query;

        if (error) {
            return res.status(500).json({ error: error.message });
        }

        return res.status(200).json(data);
    }

    if (req.method === 'POST') {
        // Admin or system update
        // In a real app, check auth/role here
        const { disease_name, state, severity, response_status } = req.body;

        const { data, error } = await supabase
            .from('emergency_status')
            .upsert({
                disease_name,
                state,
                severity,
                response_status,
                last_updated: new Date()
            })
            .select();

        if (error) {
            return res.status(500).json({ error: error.message });
        }

        return res.status(200).json(data);
    }

    return res.status(405).json({ message: 'Method not allowed' });
}
