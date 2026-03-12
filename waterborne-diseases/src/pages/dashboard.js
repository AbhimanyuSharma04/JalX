import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import dynamic from 'next/dynamic';
import { supabase } from '../supabaseClient';

// Dynamically import Dashboard to avoid SSR issues with Leaflet
const Dashboard = dynamic(() => import('../Dashboard_copy'), {
    ssr: false,
});

const ProtectedDashboard = () => {
    const router = useRouter();
    const [session, setSession] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const checkSession = async () => {
            const { data: { session } } = await supabase.auth.getSession();
            if (!session) {
                router.replace('/login');
            } else {
                setSession(session);
            }
            setLoading(false);
        };

        checkSession();

        const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
            if (!session) {
                router.replace('/login');
            }
            setSession(session);
        });

        return () => subscription.unsubscribe();
    }, [router]);

    if (loading) {
        return <div className="d-flex justify-content-center align-items-center vh-100">Loading...</div>;
    }

    if (!session) return null;

    return <Dashboard />;
};

export default ProtectedDashboard;
