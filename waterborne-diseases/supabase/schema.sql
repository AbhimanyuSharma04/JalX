-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: disease_reports (Current active outbreaks)
CREATE TABLE IF NOT EXISTS disease_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disease_name TEXT NOT NULL,
    state TEXT NOT NULL,
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    total_cases INTEGER DEFAULT 0,
    weekly_growth_rate FLOAT DEFAULT 0.0,
    severity TEXT CHECK (severity IN ('critical', 'high', 'medium', 'low')) DEFAULT 'low',
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: monthly_trends (Historical data)
CREATE TABLE IF NOT EXISTS monthly_trends (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disease_name TEXT NOT NULL,
    month TEXT NOT NULL,
    year INTEGER NOT NULL,
    cases INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: emergency_status (State-wise status)
CREATE TABLE IF NOT EXISTS emergency_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disease_name TEXT,
    state TEXT NOT NULL,
    severity TEXT CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    response_status TEXT DEFAULT 'monitoring',
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: public_health_news (Aggregated News)
CREATE TABLE IF NOT EXISTS public_health_news (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    summary TEXT,
    detected_disease TEXT,
    country_scope TEXT CHECK (country_scope IN ('INDIA', 'GLOBAL')) DEFAULT 'GLOBAL',
    source TEXT,
    url TEXT UNIQUE NOT NULL,
    published_at TIMESTAMP WITH TIME ZONE,
    fetched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: data_update_logs (Audit logs)
CREATE TABLE IF NOT EXISTS data_update_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source TEXT NOT NULL,
    update_type TEXT NOT NULL,
    records_affected INTEGER DEFAULT 0,
    run_status TEXT CHECK (run_status IN ('success', 'failed', 'partial')),
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_disease_reports_state ON disease_reports(state);
CREATE INDEX IF NOT EXISTS idx_disease_reports_severity ON disease_reports(severity);
CREATE INDEX IF NOT EXISTS idx_monthly_trends_disease ON monthly_trends(disease_name);
CREATE INDEX IF NOT EXISTS idx_health_news_scope ON public_health_news(country_scope);
CREATE INDEX IF NOT EXISTS idx_health_news_date ON public_health_news(published_at);

-- Row Level Security (RLS) Configuration
-- Enable RLS on all tables
ALTER TABLE disease_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_trends ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_health_news ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_update_logs ENABLE ROW LEVEL SECURITY;

-- Create Policies for Public Read Access
-- Allow anyone (even unauthenticated users) to select/view data
CREATE POLICY "Allow public read access" ON disease_reports FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON monthly_trends FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON emergency_status FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON public_health_news FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON data_update_logs FOR SELECT USING (true);

-- Create Policies for Authenticated Write Access
-- Only allow authenticated users to insert, update, or delete data
CREATE POLICY "Allow authenticated insert" ON disease_reports FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated update" ON disease_reports FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated delete" ON disease_reports FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated insert" ON monthly_trends FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated update" ON monthly_trends FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated delete" ON monthly_trends FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated insert" ON emergency_status FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated update" ON emergency_status FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated delete" ON emergency_status FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated insert" ON public_health_news FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated update" ON public_health_news FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated delete" ON public_health_news FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated insert" ON data_update_logs FOR INSERT WITH CHECK (auth.role() = 'authenticated');
