import { createClient } from '@supabase/supabase-js';

// Robust mock data generator
const generateMockNews = () => {
    const newsItems = [
        {
            title: "Rise in Waterborne Diseases in Flood-Hit Areas of Kerala",
            summary: "Health officials report a spike in Cholera cases following recent heavy rains.",
            detected_disease: "Cholera",
            country_scope: 'INDIA',
            source: "MoHFW",
            url: "https://mohfw.gov.in/news/cholera-alert-kerala",
            published_at: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString() // 2 hours ago
        },
        {
            title: "WHO warns of Typhoid outbreaks in South Asia",
            summary: "The World Health Organization has issued an alert regarding increasing spread due to sanitation issues.",
            detected_disease: "Typhoid",
            country_scope: 'GLOBAL',
            source: "WHO",
            url: "https://who.int/news/typhoid-south-asia",
            published_at: new Date(Date.now() - 1000 * 60 * 60 * 5).toISOString()
        },
        {
            title: "Contaminated water supply leads to Dysentery fears in Mumbai",
            summary: "Residents are advised to boil water as municipal supply compromise suspected in suburban areas.",
            detected_disease: "Dysentery",
            country_scope: 'INDIA',
            source: "Times of India",
            url: "https://timesofindia.indiatimes.com/city/mumbai/water-alert",
            published_at: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString()
        },
        {
            title: "New strain of Hepatitis E detected in Yemen",
            summary: "Researchers advise caution as new variant shows resistance to common treatments.",
            detected_disease: "Hepatitis E",
            country_scope: 'GLOBAL',
            source: "Reuters",
            url: "https://reuters.com/health/hepatitis-yemen",
            published_at: new Date(Date.now() - 1000 * 60 * 60 * 36).toISOString()
        },
        {
            title: "Clean water initiative launched to combat Gastroenteritis in Bihar",
            summary: "Government announces new funds to improve sanitation infrastructure in rural districts.",
            detected_disease: "Gastroenteritis",
            country_scope: 'INDIA',
            source: "India Today",
            url: "https://indiatoday.in/bihar/clean-water",
            published_at: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString()
        }
    ];
    return newsItems;
};

export default async function handler(req, res) {
    if (req.method !== 'GET') {
        return res.status(405).json({ message: 'Method not allowed' });
    }

    // Default to mock data
    let newsData = generateMockNews();

    try {
        const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
        const supabaseKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

        // If credentials are missing, log warning and return mock data immediately
        if (!supabaseUrl || !supabaseKey) {
            console.warn("Supabase credentials missing in API. Falling back to mock data.");
            return res.status(200).json(newsData);
        }

        const supabase = createClient(supabaseUrl, supabaseKey);

        // 1. Try fetching from DB
        try {
            const twelveHoursAgo = new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString();
            const { data: dbNews, error } = await supabase
                .from('public_health_news')
                .select('*')
                .gt('fetched_at', twelveHoursAgo)
                .order('published_at', { ascending: false });

            if (!error && dbNews && dbNews.length > 0) {
                // If we have DB data, use it!
                console.log("Serving news from Supabase cache.");
                newsData = dbNews;
                // Return immediately if DB read was successful
                return res.status(200).json(sortNews(newsData));
            }
        } catch (dbReadErr) {
            console.error("Supabase read failed:", dbReadErr);
            // Fallthrough to mock data logic
        }

        // 2. If we are here, we need to return fresh mock data AND try to save it
        console.log("Generating fresh mock data...");

        // Try to save to DB asynchronously (don't block response too long)
        try {
            const { error: insertError } = await supabase
                .from('public_health_news')
                .insert(newsData.map(item => ({ ...item, fetched_at: new Date().toISOString() })));

            if (insertError) {
                console.error("Supabase insert failed:", insertError.message);
            } else {
                console.log("Fresh news cached to Supabase.");
            }
        } catch (dbWriteErr) {
            console.error("Supabase write failed:", dbWriteErr);
        }

        // 3. Return the fresh data
        return res.status(200).json(sortNews(newsData));

    } catch (criticalErr) {
        console.error("Critical API Error:", criticalErr);
        // Absolute fallback - ensure we NEVER return 500 if we have data suitable for display
        return res.status(200).json(newsData);
    }
}

// Helper to sort: India first, then date
function sortNews(items) {
    return items.sort((a, b) => {
        if (a.country_scope === 'INDIA' && b.country_scope !== 'INDIA') return -1;
        if (a.country_scope !== 'INDIA' && b.country_scope === 'INDIA') return 1;
        return new Date(b.published_at) - new Date(a.published_at);
    });
}
