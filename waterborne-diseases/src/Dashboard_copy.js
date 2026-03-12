import React, { useState, useEffect, useRef } from 'react';
import { sensorDB } from './firebase/config'; // Make sure this path is correct
import { supabase } from './supabaseClient';
import { ref, get } from "firebase/database";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { motion, AnimatePresence } from 'framer-motion';
import { FaBars, FaTimes, FaRobot, FaHome, FaDatabase, FaUsers, FaInfoCircle, FaComments, FaStethoscope, FaMapMarkerAlt, FaVideo, FaFlask, FaShieldAlt, FaMicrochip, FaBolt, FaChevronDown, FaSignOutAlt, FaExchangeAlt, FaClipboardList, FaTrash, FaEye, FaTint, FaFaucet } from 'react-icons/fa';
import { useTranslation } from 'react-i18next';
import { useRouter } from 'next/router';
import { MapContainer, TileLayer, CircleMarker, Popup, useMap } from 'react-leaflet';
import dynamic from 'next/dynamic';
import ReactMarkdown from 'react-markdown';
import SafetyScale from './Components/SafetyScale';
import PredictionGauge from './Components/PredictionGauge';
import CustomDropdown from './Components/CustomDropdown';
import NewsCard from './Components/NewsCard';


const CustomChartTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
        return (
            <div className="jr-chart-tooltip">
                <p className="jr-tooltip-label">{label}</p>
                {payload.map((entry, index) => (
                    <div key={index} className="jr-tooltip-item">
                        <span style={{ color: entry.color, display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: entry.color }}></span>
                            {entry.name}:
                        </span>
                        <span className="jr-tooltip-value">
                            {entry.value.toLocaleString()}
                        </span>
                    </div>
                ))}
            </div>
        );
    }
    return null;
};

// MapInteractionController and OutbreakMap have been moved to src/Components/OutbreakMap.js
const OutbreakMap = dynamic(() => import('./Components/OutbreakMap'), {
    ssr: false,
    loading: () => <div className="jr-card mb-4 p-0 d-flex align-items-center justify-content-center" style={{ height: '400px', background: '#f8f9fa' }}>
        <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading Map...</span>
        </div>
    </div>
});




const App = () => {
    const { t, i18n } = useTranslation();
    const [activeTab, setActiveTab] = useState('home');
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const [chatOpen, setChatOpen] = useState(false);
    const [userMessage, setUserMessage] = useState('');
    const [messages, setMessages] = useState([]);
    const [isTyping, setIsTyping] = useState(false);
    const [darkMode] = useState(true);
    const [selectedOutbreak, setSelectedOutbreak] = useState(null);
    const [dataError, setDataError] = useState(null);


    const [formData, setFormData] = useState({
        name: '',
        age: '',
        gender: '',
        location: '',
        symptoms: [],
    });

    // Mock Data for Nearby Map
    // Mock Data for Nearby Map
    const nearbyOutbreaks = [
        { id: 'n1', name: t('outbreaks.contamination.name'), state: t('states.sector4'), cases: 12, severity: 'high', position: [28.6139, 77.2090], healthContact: '108', nearbyHospitals: 2, latestNews: t('outbreaks.contamination.news') },
        { id: 'n2', name: t('outbreaks.safeZone.name'), state: t('states.connaughtPlace'), cases: 0, severity: 'low', position: [28.6270, 77.2180], healthContact: '108', nearbyHospitals: 5, latestNews: t('outbreaks.safeZone.news') }
    ];

    const nearbyDevices = [
        { id: 'd1', name: 'Jal-Rakshak Unit #102', type: t('deviceTypes.sensorBuoy'), status: 'active', position: [28.6100, 77.2000], readings: { ph: 7.2, turbidity: 4.5 }, battery: '85%' },
        { id: 'd2', name: 'Jal-Rakshak Unit #105', type: t('deviceTypes.pipelineMonitor'), status: 'alert', position: [28.6150, 77.2150], readings: { ph: 8.9, turbidity: 12.0 }, battery: '12%' }
    ];

    const [waterFormData, setWaterFormData] = useState({
        ph: '',
        turbidity: '',
        contaminantLevel: '',
        temperature: '',
        water_source_type: '',
        uv_sensor: '',
        guva_sensor: '',
        conductivity: '',
        dissolvedOxygen: '' // New Parameter
    });




    const [isAnalyzing, setIsAnalyzing] = useState(false);
    const [analysisResult, setAnalysisResult] = useState(null);
    const [isWaterAnalyzing, setIsWaterAnalyzing] = useState(false);
    const [waterAnalysisResult, setWaterAnalysisResult] = useState(null);
    const [waterAnalysisError, setWaterAnalysisError] = useState(null);
    const mainChatRef = useRef(null);

    const [isFetching, setIsFetching] = useState(false);
    const [fetchMessage, setFetchMessage] = useState('');
    const [userName, setUserName] = useState('');

    // Refs for click outside to close
    const profileDropdownRef = useRef(null);


    // Device Management State
    const [devices, setDevices] = useState([]);
    const [selectedDevice, setSelectedDevice] = useState(null);
    const [showDeviceDropdown, setShowDeviceDropdown] = useState(false);
    const [showAddDeviceModal, setShowAddDeviceModal] = useState(false);
    const [newDeviceData, setNewDeviceData] = useState({ id: '', name: '' });
    const [deviceLoading, setDeviceLoading] = useState(false);
    const [showContactModal, setShowContactModal] = useState(false);
    const [showProfileMenu, setShowProfileMenu] = useState(false);
    const [showLanguageDropdown, setShowLanguageDropdown] = useState(false);
    const [savedReadings, setSavedReadings] = useState([]);
    const [selectedReading, setSelectedReading] = useState(null);
    const router = useRouter();
    const navigate = (path) => router.push(path); // Adapter to minimize changes

    // New State for Dynamic Data
    const [outbreaks, setOutbreaks] = useState([]);
    const [stats, setStats] = useState([]);
    const [trends, setTrends] = useState([]);
    const [lastUpdated, setLastUpdated] = useState(null);
    const [emergencyStatus, setEmergencyStatus] = useState([]);

    // Fetch Data from APIs
    useEffect(() => {
        const processTrendsData = (data) => {
            const result = {};
            data.forEach(item => {
                const key = `${item.month}-${item.year}`; // Group by month-year
                if (!result[key]) {
                    result[key] = { month: item.month, year: item.year };
                }
                // Normalize disease name to key (e.g. 'Diarrhea' -> 'diarrhea')
                const diseaseKey = item.disease_name.toLowerCase().replace(/ /g, '');
                result[key][diseaseKey] = item.cases;
            });
            return Object.values(result);
        };

        const fetchDashboardData = async () => {
            try {
                const [outbreaksRes, statsRes, emergencyRes, trendsRes] = await Promise.all([
                    fetch('/api/outbreaks'),
                    fetch('/api/state-comparison'),
                    fetch('/api/emergency-status'),
                    fetch('/api/trends')
                ]);

                if (!outbreaksRes.ok) throw new Error(`Outbreaks API failed: ${outbreaksRes.status}`);
                if (!statsRes.ok) throw new Error(`Stats API failed: ${statsRes.status}`);
                if (!emergencyRes.ok) throw new Error(`Emergency API failed: ${emergencyRes.status}`);
                if (!trendsRes.ok) throw new Error(`Trends API failed: ${trendsRes.status}`);

                const outbreaksData = await outbreaksRes.json();
                const formattedOutbreaks = outbreaksData.map(item => ({
                    ...item,
                    position: [item.latitude, item.longitude],
                    name: item.disease_name,
                    cases: item.total_cases,
                    rate: item.weekly_growth_rate
                }));
                setOutbreaks(formattedOutbreaks);
                if (outbreaksData.length > 0) setLastUpdated(outbreaksData[0].last_updated);

                const statsData = await statsRes.json();
                setStats(statsData);

                const emergencyData = await emergencyRes.json();
                setEmergencyStatus(emergencyData);

                const trendsData = await trendsRes.json();
                const processedTrends = processTrendsData(trendsData);
                setTrends(processedTrends);

            } catch (error) {
                console.error("Failed to fetch dashboard data:", error);
                setDataError(error.message);
            }
        };

        fetchDashboardData();
    }, []);



    const fetchReadings = async () => {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return;

        const { data, error } = await supabase
            .from('user_readings')
            .select('*')
            .eq('user_id', user.id)
            .order('timestamp', { ascending: false });

        if (error) {
            console.error('Error fetching readings:', error);
        } else {
            setSavedReadings(data || []);
        }
    };

    useEffect(() => {
        if (activeTab === 'readings') {
            fetchReadings();
        }
    }, [activeTab]);

    const handleSaveReading = async () => {
        if (!waterAnalysisResult) return;

        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            alert("Please login to save readings.");
            return;
        }

        const readingData = {
            user_id: user.id,
            device_name: selectedDevice?.device_name || t('manualEntry'),
            device_id: selectedDevice?.device_id || null,
            ph: waterFormData.ph || null,
            turbidity: waterFormData.turbidity || null,
            contaminant_level: waterFormData.contaminantLevel || null,
            temperature: waterFormData.temperature || null,
            conductivity: waterFormData.conductivity || null,
            water_source: waterFormData.water_source_type || 'River',
            risk_level: waterAnalysisResult.risk_level,
            confidence: waterAnalysisResult.confidence,
            analysis_result: waterAnalysisResult
        };

        const { error } = await supabase.from('user_readings').insert([readingData]);

        if (error) {
            console.error('Error saving reading:', error);
            alert('Failed to save reading.');
        } else {
            alert('Reading saved successfully!');
            setActiveTab('readings'); // Switch to readings tab
        }
    };

    const handleLogout = async () => {
        await supabase.auth.signOut();
        navigate('/login');
    };

    useEffect(() => {
        const fetchUserNameAndDevices = async () => {
            const { data: { user } } = await supabase.auth.getUser();
            if (user) {
                // Try to get name from profiles table first
                const { data: profile } = await supabase
                    .from('profiles')
                    .select('full_name')
                    .eq('id', user.id)
                    .single();

                if (profile && profile.full_name) {
                    setUserName(profile.full_name);
                } else if (user.user_metadata && user.user_metadata.full_name) {
                    setUserName(user.user_metadata.full_name);
                } else {
                    setUserName(user.email.split('@')[0]);
                }

                // Fetch Devices
                const { data: userDevices } = await supabase
                    .from('devices')
                    .select('*')
                    .eq('user_id', user.id);

                if (userDevices) {
                    setDevices(userDevices);
                    if (userDevices.length > 0) {
                        setSelectedDevice(userDevices[0]); // Select first by default
                    }
                }
            }
        };
        fetchUserNameAndDevices();
    }, []);

    const handleAddDevice = async (e) => {
        e.preventDefault();
        setDeviceLoading(true);
        const { data: { user } } = await supabase.auth.getUser();

        if (!user) return; // Should handle error

        try {
            const { data, error } = await supabase
                .from('devices')
                .insert([
                    {
                        user_id: user.id,
                        device_id: newDeviceData.id,
                        device_name: newDeviceData.name
                    }
                ])
                .select();

            if (error) throw error;

            if (data) {
                const newDevice = data[0];
                setDevices([...devices, newDevice]);
                setSelectedDevice(newDevice); // Auto select new device
                setShowAddDeviceModal(false);
                setNewDeviceData({ id: '', name: '' });
                alert(t('alertDeviceAdded'));
            }
        } catch (error) {
            alert(t('alertDeviceError') + error.message);
        } finally {
            setDeviceLoading(false);
        }
    };


    useEffect(() => {
        setMessages([
            {
                id: 1,
                text: t('ai.initialGreeting'),
                sender: 'ai',
                timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            }
        ]);
    }, [i18n.language, t]);



    const handleSendMessage = async () => {
        if (!userMessage.trim()) return;

        const timestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        const newUserMessage = { id: Date.now(), text: userMessage, sender: 'user', timestamp };
        setMessages(prev => [...prev, newUserMessage]);

        const messageToSend = userMessage;
        setUserMessage(''); // Clear input immediately for better UX
        setIsTyping(true);

        try {
            // Call your backend's /api/chat endpoint
            const response = await fetch('http://localhost:4000/api/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message: messageToSend }),
            });

            if (!response.ok) {
                throw new Error('Network response was not ok');
            }

            const data = await response.json();
            const aiResponseText = data.reply; // Get the AI's reply

            // Add the AI's message to the chat
            const aiResponse = {
                id: Date.now() + 1,
                text: aiResponseText,
                sender: 'ai',
                timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            };
            setMessages(prev => [...prev, aiResponse]);

        } catch (error) {
            console.error("Error fetching AI response:", error);
            // Display an error message in the chat if the call fails
            const errorResponse = {
                id: Date.now() + 1,
                text: t('chatConnectionError'),
                sender: 'ai',
                timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            };
            setMessages(prev => [...prev, errorResponse]);
        } finally {
            setIsTyping(false);
        }
    };

    useEffect(() => {
        if (mainChatRef.current) {
            mainChatRef.current.scrollTop = mainChatRef.current.scrollHeight;
        }

    }, [messages]);

    const diseaseDatabase = {
        hepatitisA: { keywords: ["Fever", "Fatigue", "Nausea", "Jaundice", "Dark colored urine", "Abdominal Pain", "Vomiting"], },
        cholera: { keywords: ["Diarrhea", "Vomiting", "Dehydration", "Nausea"], },
        gastroenteritis: { keywords: ["Diarrhea", "Vomiting", "Nausea", "Abdominal Pain", "Fever", "Dehydration", "Headache"], },
        typhoid: { keywords: ["Fever", "Headache", "Fatigue", "Abdominal Pain", "Rose spots", "Diarrhea"], },
        giardiasis: { keywords: ["Diarrhea", "Fatigue", "Abdominal Pain", "Nausea", "Dehydration", "Bloating", "Weight loss"], },
        crypto: { keywords: ["Diarrhea", "Dehydration", "Weight loss", "Abdominal Pain", "Fever", "Nausea", "Vomiting"], }
    };

    const runAIAnalysis = (selectedSymptoms) => {
        const translatedSymptomsList = t('symptomsList', { returnObjects: true });
        const englishSelectedSymptoms = selectedSymptoms.map(symptom => {
            const index = translatedSymptomsList.indexOf(symptom);
            const enBundle = i18n.getResourceBundle('en', 'translation');
            return enBundle ? enBundle.symptomsList[index] : symptom;
        });
        let scores = [];
        for (const diseaseKey in diseaseDatabase) {
            const disease = diseaseDatabase[diseaseKey];
            const matchingSymptoms = disease.keywords.filter(keyword => englishSelectedSymptoms.includes(keyword));
            if (matchingSymptoms.length > 0) {
                const score = Math.round((matchingSymptoms.length / disease.keywords.length) * 100);
                if (score > 20) {
                    scores.push({
                        ...t(`diseases.${diseaseKey}`, { returnObjects: true }),
                        probability: score,
                    });
                }
            }
        }
        scores.sort((a, b) => b.probability - a.probability);
        return scores.length > 0 ? scores.slice(0, 3) : [];
    };

    const handleFormSubmit = (e) => {
        e.preventDefault();
        if (formData.symptoms.length === 0) {
            alert(t('alertSelectSymptom'));
            return;
        }
        setIsAnalyzing(true);
        setAnalysisResult(null);
        setTimeout(() => {
            const results = runAIAnalysis(formData.symptoms);
            setAnalysisResult(results);
            setIsAnalyzing(false);
        }, 2500);
    };

    const handleWaterFormSubmit = async (e) => {
        e.preventDefault();
        setIsWaterAnalyzing(true);
        setWaterAnalysisResult(null);
        setWaterAnalysisError(null);
        // Updated API URL
        const API_URL = 'https://karan0301-water-contamination-api.hf.space/predict';

        // Extract raw values from form
        const ph = parseFloat(waterFormData.ph) || 0;
        const turbidity = parseFloat(waterFormData.turbidity) || 0;
        const temperature = parseFloat(waterFormData.temperature) || 0;
        const conductivity = parseFloat(waterFormData.conductivity) || 0;
        const doVal = parseFloat(waterFormData.dissolvedOxygen) || 0;

        // Construct payload strictly matching WaterInput schema
        // We use raw values as proxies for 'roll_std' and set 'diff' to 0
        const submissionData = {
            DO_roll_std: doVal,
            DO_diff: 0,
            Conductivity_roll_std: conductivity,
            Conductivity_diff: 0,
            Temperature_roll_std: temperature,
            Temperature_diff: 0,
            Turbidity_roll_std: turbidity,
            Turbidity_diff: 0,
            pH_roll_std: ph,
            pH_diff: 0,
            stress_index: 0,
            stress_cum: 0,
            turb_cond_interaction: turbidity * conductivity,
            do_turb_interaction: doVal * turbidity
        };

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(submissionData),
            });
            if (!response.ok) {
                const errData = await response.json();
                throw new Error(errData.detail || `HTTP error! Status: ${response.status}`);
            }
            const result = await response.json();
            console.log("API Response:", result);

            // Normalize Result - The new API returns { "risk_probability": float, "risk_level": string }
            const normalizedResult = {
                ...result,
                risk_level: result.risk_level, // "High", "Moderate", "Low"
                confidence: (result.risk_probability).toFixed(1) // Convert probability to percentage string
            };

            setWaterAnalysisResult(normalizedResult);
            setWaterAnalysisError(null);

        } catch (error) {
            console.error("API call failed:", error);
            setWaterAnalysisError(`Failed to get analysis. ${error.message}`);
        } finally {
            setIsWaterAnalyzing(false);
        }
    };

    const handleFetchFromDevice = async () => {
        setIsFetching(true);
        setFetchMessage(''); // Clear any previous message

        const dataRef = ref(sensorDB, 'waterData');

        try {
            const snapshot = await get(dataRef);
            if (snapshot.exists()) {
                const sensorValues = snapshot.val();
                console.log("Fetched data:", sensorValues);

                setWaterFormData(prevData => ({
                    ...prevData,
                    ph: sensorValues.ph ? Number(sensorValues.ph).toFixed(2) : prevData.ph,
                    turbidity: sensorValues.turbidity ? Number(sensorValues.turbidity).toFixed(2) : prevData.turbidity,
                    temperature: sensorValues.temperature ? Number(sensorValues.temperature).toFixed(2) : prevData.temperature,
                    conductivity: sensorValues.conductivity ? Number(sensorValues.conductivity).toFixed(2) : prevData.conductivity,
                    contaminantLevel: sensorValues.tds ? Number(sensorValues.tds).toFixed(2) : prevData.contaminantLevel, // Map 'tds' from Firebase
                    uv_sensor: sensorValues.color || 'Green',                   // Map 'color' from Firebase
                    guva_sensor: sensorValues.uv ? Number(sensorValues.uv).toFixed(2) : prevData.guva_sensor,
                    dissolvedOxygen: sensorValues.do ? Number(sensorValues.do).toFixed(2) : (sensorValues.dissolved_oxygen ? Number(sensorValues.dissolved_oxygen).toFixed(2) : prevData.dissolvedOxygen)
                }));

                // Set a success message instead of an alert
                setFetchMessage(t('fetchSuccess'));
            } else {
                setFetchMessage(t('fetchError') || 'No data found');
                alert(t('fetchError') || 'No device data found in cloud.');
            }
        } catch (error) {
            console.error("Error fetching data:", error);
            setFetchMessage(t('fetchError') || 'Connection failed');
            alert(`Failed to fetch from device: ${error.message}`);
        } finally {
            setIsFetching(false);
        }
    };



    const handleWaterInputChange = (e) => {
        const { name, value } = e.target;
        setWaterFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSymptomChange = (symptom) => {
        setFormData(prev => {
            const symptoms = prev.symptoms.includes(symptom)
                ? prev.symptoms.filter(s => s !== symptom)
                : [...prev.symptoms, symptom];
            return { ...prev, symptoms };
        });
    };



    const toggleSidebar = () => setSidebarOpen(!sidebarOpen);

    useEffect(() => {
        if (darkMode) {
            document.body.classList.add('bg-dark', 'text-light');
        } else {
            document.body.classList.remove('bg-dark', 'text-light');
        }
    }, [darkMode]);

    useEffect(() => {
        const handleClickOutside = (event) => {
            // Close Sidebar
            if (sidebarOpen && !event.target.closest('.sidebar') && !event.target.closest('.hamburger-btn')) {
                setSidebarOpen(false);
            }

            // Close Profile Menu
            if (showProfileMenu && profileDropdownRef.current && !profileDropdownRef.current.contains(event.target)) {
                setShowProfileMenu(false);
            }


        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, [sidebarOpen, showProfileMenu]);

    const diseaseOutbreaks = outbreaks.length > 0 ? outbreaks : [];

    const communityEvents = [
        { id: 1, title: t('events.webinar.title'), type: 'online', platform: 'Zoom', date: 'October 20, 2025', time: '3:00 PM - 5:00 PM', description: t('events.webinar.desc'), attendees: 250, status: 'upcoming' },
        { id: 2, title: t('events.camp.title'), type: 'offline', venue: 'Tura Community Center, Meghalaya', date: 'November 5, 2025', time: '9:00 AM - 3:00 PM', description: t('events.camp.desc'), attendees: 85, status: 'upcoming' },
        { id: 3, title: t('events.workshop.title'), type: 'online', platform: 'Microsoft Teams', date: 'November 15, 2025', time: '11:00 AM - 1:00 PM', description: t('events.workshop.desc'), attendees: 180, status: 'upcoming' },
        { id: 4, title: t('events.screening.title'), type: 'offline', venue: 'Kohima School Complex, Nagaland', date: 'December 2, 2025', time: '8:00 AM - 2:00 PM', description: t('events.screening.desc'), attendees: 200, status: 'upcoming' },
        { id: 5, title: t('events.training.title'), type: 'offline', venue: 'Public Hall, Patna, Bihar', date: 'December 15, 2025', time: '10:00 AM - 1:00 PM', description: t('events.training.desc'), attendees: 120, status: 'upcoming' },
        { id: 6, title: t('events.seminar.title'), type: 'online', platform: 'Google Meet', date: 'January 10, 2026', time: '2:00 PM - 4:00 PM', description: t('events.seminar.desc'), attendees: 300, status: 'upcoming' },
    ];

    const allIndiaStats = stats.length > 0 ? stats.map(s => ({
        state: s.state,
        cases: s.total_cases,
        rate: 0 // We might need to compute rate if not provided by API
    })) : [];

    const diseaseTrends = trends.length > 0 ? trends : [];

    const teamMembers = [
        { name: "Abhimanyu" }, { name: "Siddharth" }, { name: "Rudra" },
    ];

    return (
        <div className="jr-app-wrapper" style={{ background: 'radial-gradient(circle at 50% 0%, #1e293b 0%, #0b1120 100%)', minHeight: '100vh', color: '#ffffff' }}>
            <header className="shadow sticky-top" style={{ background: 'rgba(11, 17, 32, 0.8)', backdropFilter: 'blur(10px)', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                <div className="container-fluid">
                    <div className="d-flex justify-content-between align-items-center py-3">
                        {dataError && <div className="alert alert-danger w-100">{dataError}</div>}
                        <div className="d-flex align-items-center">
                            <button
                                className="hamburger-btn btn me-3"
                                onClick={toggleSidebar}
                                aria-label={sidebarOpen ? "Close sidebar menu" : "Open sidebar menu"}
                                style={{ color: darkMode ? 'white' : 'black' }}
                            >
                                {sidebarOpen ? <FaTimes size={20} aria-hidden="true" /> : <FaBars size={20} aria-hidden="true" />}
                            </button>
                            <div className="me-2" style={{ width: '40px', height: '40px', background: 'linear-gradient(to right, #0D6EFD, #198754)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <svg className="text-white" width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                                </svg>
                            </div>
                            <h1 className="h4 fw-bold mb-0">JAL-RAKSHAK</h1>
                        </div>

                        <div className="d-flex align-items-center position-relative" ref={profileDropdownRef}>
                            <div
                                className="d-flex align-items-center cursor-pointer"
                                onClick={() => setShowProfileMenu(!showProfileMenu)}
                                style={{ cursor: 'pointer' }}
                            >
                                <span className="text-white me-3 d-none d-md-block">{t('welcomeUser')} <span className="fw-bold text-info">{userName || 'User'}</span></span>
                                <div className="rounded-circle bg-secondary d-flex align-items-center justify-content-center text-white fw-bold" style={{ width: '40px', height: '40px', fontSize: '1.2rem' }}>
                                    {userName ? userName.charAt(0).toUpperCase() : 'U'}
                                </div>
                            </div>

                            <AnimatePresence>
                                {showProfileMenu && (
                                    <motion.div
                                        initial={{ opacity: 0, y: 10 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        exit={{ opacity: 0, y: 10 }}
                                        className="jr-profile-dropdown"
                                    >
                                        <button onClick={handleLogout} className="jr-dropdown-item w-100 text-start">
                                            <FaExchangeAlt className="me-2 text-warning" /> {t('switchAccount')}
                                        </button>
                                        <button onClick={handleLogout} className="jr-dropdown-item w-100 text-start border-top border-secondary pt-2 mt-1">
                                            <FaSignOutAlt className="me-2 text-danger" /> {t('logout')}
                                        </button>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>
                    </div>
                </div>
            </header>

            <div className="d-flex">
                <aside
                    className="sidebar shadow position-fixed"
                    style={{
                        width: '280px',
                        height: '100vh',
                        top: '0',
                        left: sidebarOpen ? '0' : '-280px',
                        background: 'rgba(0, 0, 0, 0.8)', // Pure Black Glassmorphism
                        borderRight: '1px solid rgba(167, 235, 242, 0.1)',
                        transition: 'left 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                        zIndex: 2000,
                        paddingTop: '20px',
                        color: 'white',
                        backdropFilter: 'blur(10px)',
                        overflowY: 'auto',
                        scrollbarWidth: 'thin',
                        paddingBottom: '200px'
                    }}
                >
                    <div className="p-4 border-bottom border-secondary mb-3">
                        <div className="d-flex align-items-center justify-content-between">
                            <div className="d-flex align-items-center">
                                <div className="me-3 jr-icon-wrapper" style={{ boxShadow: '0 0 15px rgba(84, 172, 191, 0.3)' }}>
                                    <svg className="text-cyan" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                                    </svg>
                                </div>
                                <h2 className="h5 fw-bold mb-0 text-white" style={{ letterSpacing: '0.05em' }}>JAL-RAKSHAK</h2>
                            </div>
                            <button onClick={() => setSidebarOpen(false)} className="btn btn-sm btn-link text-white-50 p-0">
                                <FaTimes size={18} />
                            </button>
                        </div>
                    </div>
                    <nav className="px-3">
                        <ul className="list-unstyled d-flex flex-column gap-2">
                            <li>
                                <button
                                    onClick={() => { setActiveTab('home'); setSidebarOpen(false); }}
                                    className={`sidebar-link ${activeTab === 'home' ? 'active' : ''}`}
                                >
                                    <div className="sidebar-icon"><FaHome /></div> {t('home')}
                                </button>
                            </li>
                            <li>
                                <button
                                    onClick={() => { setActiveTab('waterData'); setSidebarOpen(false); }}
                                    className={`sidebar-link ${activeTab === 'waterData' ? 'active' : ''}`}
                                >
                                    <div className="sidebar-icon"><FaDatabase /></div> {t('submitWaterData')}
                                </button>
                            </li>
                            <li>
                                <button
                                    onClick={() => { setActiveTab('prediction'); setSidebarOpen(false); }}
                                    className={`sidebar-link ${activeTab === 'prediction' ? 'active' : ''}`}
                                >
                                    <div className="sidebar-icon"><FaStethoscope /></div> {t('diseasePrediction')}
                                </button>
                            </li>
                            <li>
                                <button
                                    onClick={() => { setActiveTab('community'); setSidebarOpen(false); }}
                                    className={`sidebar-link ${activeTab === 'community' ? 'active' : ''}`}
                                >
                                    <div className="sidebar-icon"><FaUsers /></div> {t('community')}
                                </button>
                            </li>
                            <li>
                                <button
                                    onClick={() => { setActiveTab('chat'); setSidebarOpen(false); }}
                                    className={`sidebar-link ${activeTab === 'chat' ? 'active' : ''}`}
                                >
                                    <div className="sidebar-icon"><FaRobot /></div> {t('aiAssistant')}
                                </button>
                            </li>

                            <li>
                                <button
                                    onClick={() => { setActiveTab('readings'); setSidebarOpen(false); }}
                                    className={`sidebar-link ${activeTab === 'readings' ? 'active' : ''}`}
                                >
                                    <div className="sidebar-icon"><FaClipboardList /></div> {t('readings') || 'Readings'}
                                </button>
                            </li>

                            {/* Devices Dropdown */}
                            <li>
                                <button
                                    onClick={() => setShowDeviceDropdown(!showDeviceDropdown)}
                                    className={`sidebar-link d-flex justify-content-between align-items-center w-100 ${activeTab === 'devices' ? 'active' : ''}`}
                                >
                                    <div className="d-flex align-items-center">
                                        <div className="sidebar-icon"><FaMicrochip /></div> {t('devices')}
                                    </div>
                                    <FaChevronDown style={{ transform: showDeviceDropdown ? 'rotate(180deg)' : 'rotate(0)', transition: 'transform 0.3s' }} size={12} />
                                </button>
                                <AnimatePresence>
                                    {showDeviceDropdown && (
                                        <motion.div
                                            initial={{ height: 0, opacity: 0 }}
                                            animate={{ height: 'auto', opacity: 1 }}
                                            exit={{ height: 0, opacity: 0 }}
                                            className="overflow-hidden"
                                        >
                                            <ul className="list-unstyled ps-4 py-2" style={{ borderLeft: '1px solid rgba(255,255,255,0.1)', marginLeft: '24px' }}>
                                                {devices.map(device => (
                                                    <li key={device.id} className="mb-2">
                                                        <button
                                                            onClick={() => { setSelectedDevice(device); }}
                                                            className="btn btn-sm text-start w-100 d-flex align-items-center"
                                                            style={{
                                                                color: selectedDevice?.id === device.id ? '#10b981' : '#cbd5e1', // Green if selected
                                                                fontWeight: selectedDevice?.id === device.id ? 'bold' : 'normal'
                                                            }}
                                                        >
                                                            <div style={{ width: 8, height: 8, borderRadius: '50%', background: selectedDevice?.id === device.id ? '#10b981' : 'rgba(255,255,255,0.2)', marginRight: '10px' }}></div>
                                                            {device.device_name}
                                                        </button>
                                                    </li>
                                                ))}
                                                <li>
                                                    <button
                                                        onClick={() => setShowAddDeviceModal(true)}
                                                        className="btn btn-sm text-info text-start w-100 mt-1"
                                                    >
                                                        {t('addDevice')}
                                                    </button>
                                                </li>
                                            </ul>
                                        </motion.div>
                                    )}
                                </AnimatePresence>
                            </li>

                            <li>
                                <button
                                    onClick={() => { setActiveTab('about'); setSidebarOpen(false); }}
                                    className={`sidebar-link ${activeTab === 'about' ? 'active' : ''}`}
                                >
                                    <div className="sidebar-icon"><FaInfoCircle /></div> {t('about')}
                                </button>
                            </li>

                            <li className="mt-4 pt-3 border-top border-secondary">
                                <small className="text-uppercase text-white-50 fw-bold mb-3 d-block px-2" style={{ fontSize: '0.7rem', letterSpacing: '0.1em' }}>{t('language')}</small>
                                <div className="px-0">
                                    <button
                                        onClick={() => setShowLanguageDropdown(!showLanguageDropdown)}
                                        className="sidebar-link d-flex justify-content-between align-items-center w-100"
                                        style={{ border: '1px solid rgba(255, 255, 255, 0.1)' }}
                                    >
                                        <div className="d-flex align-items-center">
                                            <div className="sidebar-icon"><FaExchangeAlt /></div>
                                            {
                                                {
                                                    en: 'English',
                                                    hi: 'हिंदी (Hindi)',
                                                    as: 'অসমীয়া (Assamese)',
                                                    bn: 'বাংলা (Bengali)',
                                                    mr: 'मराठी (Marathi)',
                                                    te: 'తెలుగు (Telugu)',
                                                    ta: 'தமிழ் (Tamil)',
                                                    gu: ' ગુજરાતી (Gujarati)',
                                                    ur: 'اردو (Urdu)',
                                                    kn: 'ಕನ್ನಡ (Kannada)'
                                                }[i18n.language] || 'Language'
                                            }
                                        </div>
                                        <FaChevronDown style={{ transform: showLanguageDropdown ? 'rotate(180deg)' : 'rotate(0)', transition: 'transform 0.3s' }} size={12} />
                                    </button>
                                    <AnimatePresence>
                                        {showLanguageDropdown && (
                                            <motion.div
                                                initial={{ height: 0, opacity: 0 }}
                                                animate={{ height: 'auto', opacity: 1 }}
                                                exit={{ height: 0, opacity: 0 }}
                                                className="overflow-hidden mt-1"
                                                style={{ background: 'rgba(0, 0, 0, 0.6)', borderRadius: '8px' }}
                                            >
                                                <div className="py-2 d-grid gap-1 px-2">
                                                    {[
                                                        { code: 'en', label: 'English' },
                                                        { code: 'hi', label: 'हिंदी (Hindi)' },
                                                        { code: 'as', label: 'অসমীয়া (Assamese)' },
                                                        { code: 'bn', label: 'বাংলা (Bengali)' },
                                                        { code: 'mr', label: 'मराठी (Marathi)' },
                                                        { code: 'te', label: 'తెలుగు (Telugu)' },
                                                        { code: 'ta', label: 'தமிழ் (Tamil)' },
                                                        { code: 'gu', label: 'ગુજરાતી (Gujarati)' },
                                                        { code: 'ur', label: 'اردو (Urdu)' },
                                                        { code: 'kn', label: 'ಕನ್ನಡ (Kannada)' }
                                                    ].map(lang => (
                                                        <button
                                                            key={lang.code}
                                                            onClick={() => {
                                                                i18n.changeLanguage(lang.code);
                                                                setShowLanguageDropdown(false);
                                                            }}
                                                            className={`btn btn-sm text-start w-100 ${i18n.language === lang.code ? 'text-info fw-bold' : 'text-white'}`}
                                                            style={{
                                                                padding: '8px 12px',
                                                                background: i18n.language === lang.code ? 'rgba(84, 172, 191, 0.1)' : 'transparent',
                                                                borderRadius: '6px',
                                                                fontSize: '0.9rem'
                                                            }}
                                                        >
                                                            {lang.label}
                                                        </button>
                                                    ))}
                                                </div>
                                            </motion.div>
                                        )}
                                    </AnimatePresence>
                                </div>
                            </li>
                        </ul>
                    </nav>
                </aside>

                <main
                    className="jr-main-content"
                    style={{
                        marginLeft: sidebarOpen ? '280px' : '0',
                    }}
                >
                    {activeTab === 'home' && (
                        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                            <div className="jr-hero-container mb-4 d-flex flex-column justify-content-center text-center p-3 p-md-5" style={{ minHeight: '300px' }}>
                                <div style={{ zIndex: 2 }}>
                                    <div className="jr-hero-sub-badge">{t('heroTitleBadge')}</div>
                                    <h1 className="jr-hero-title">{t('heroTitleMain')}</h1>
                                    <p className="jr-hero-subtitle">{t('heroSubtitle')}</p>

                                    <div className="d-flex justify-content-center gap-3 mt-4 flex-wrap">
                                        <span className="jr-hero-pill">{t('heroPill1')}</span>
                                        <span className="jr-hero-pill">{t('heroPill2')}</span>
                                        <span className="jr-hero-pill">{t('heroPill3')}</span>
                                    </div>
                                </div>
                            </div>



                            <div className="row g-4 mb-4">
                                <div className="col-lg-6 position-relative">
                                    <OutbreakMap
                                        outbreaks={diseaseOutbreaks}
                                        title={t('allIndiaMapTitle') || "All India Disease Outbreak Monitor"}
                                        mapId="india"
                                    />
                                </div>
                                <div className="col-lg-6">
                                    <OutbreakMap
                                        outbreaks={nearbyOutbreaks}
                                        devices={nearbyDevices}
                                        title={t('nearbyMapTitle') || "Nearby Disease Outbreak"}
                                        mapId="nearby"
                                    />
                                </div>
                            </div>

                            <div className="row mb-4">
                                <div className="col-lg-6 mb-3">
                                    <div className="jr-card">
                                        <div className="jr-card-header mb-0">
                                            <div className="jr-icon-wrapper"><FaDatabase /></div>
                                            <div>
                                                {t('statisticsTitle')}
                                                <div className="text-white-50 small fw-normal mt-1" style={{ fontSize: '0.75rem', letterSpacing: '0.02em' }}>
                                                    <FaInfoCircle className="me-1" size={10} /> {t('statisticsInfo')}
                                                </div>
                                            </div>
                                        </div>
                                        <div style={{ width: "100%", minHeight: "400px" }}>
                                            {allIndiaStats.length > 0 ? (
                                                <ResponsiveContainer width="100%" height={400}>
                                                    <BarChart data={allIndiaStats} barSize={20} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                                                        <defs>
                                                            <linearGradient id="colorCases" x1="0" y1="0" x2="0" y2="1">
                                                                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.9} />
                                                                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0.4} />
                                                            </linearGradient>
                                                            <linearGradient id="colorRate" x1="0" y1="0" x2="0" y2="1">
                                                                <stop offset="5%" stopColor="#10b981" stopOpacity={0.9} />
                                                                <stop offset="95%" stopColor="#10b981" stopOpacity={0.4} />
                                                            </linearGradient>
                                                        </defs>
                                                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                                                        <XAxis dataKey="state" stroke="#64748b" tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={{ stroke: 'rgba(255,255,255,0.1)' }} />
                                                        <YAxis stroke="#64748b" tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={{ stroke: 'rgba(255,255,255,0.1)' }} />
                                                        <Tooltip content={<CustomChartTooltip />} cursor={{ fill: 'rgba(255,255,255,0.03)' }} />
                                                        <Legend verticalAlign="top" height={36} wrapperStyle={{ color: '#cbd5e1', fontSize: '12px' }} iconType="circle" />
                                                        <Bar dataKey="cases" fill="url(#colorCases)" name={t('cases')} radius={[4, 4, 0, 0]} />
                                                        <Bar dataKey="rate" fill="url(#colorRate)" name={`${t('rate')} per 1000`} radius={[4, 4, 0, 0]} />
                                                    </BarChart>
                                                </ResponsiveContainer>
                                            ) : (
                                                <div className="d-flex flex-column justify-content-center align-items-center" style={{ height: '400px' }}>
                                                    <FaDatabase size={40} className="text-muted mb-3" style={{ opacity: 0.3 }} />
                                                    <p className="text-muted">No data available</p>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                                <div className="col-lg-6 mb-3">
                                    <div className="jr-card">
                                        <div className="jr-card-header mb-0">
                                            <div className="jr-icon-wrapper"><FaMapMarkerAlt /></div>
                                            <div>
                                                {t('trendsTitle')}
                                                <div className="text-muted small fw-normal mt-1" style={{ fontSize: '0.75rem', letterSpacing: '0.02em' }}>
                                                    <FaInfoCircle className="me-1" size={10} /> {t('trendsInfo')}
                                                </div>
                                            </div>
                                        </div>
                                        <div style={{ width: "100%", minHeight: "400px" }}>
                                            {diseaseTrends.length > 0 ? (
                                                <ResponsiveContainer width="100%" height={400}>
                                                    <AreaChart data={diseaseTrends} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                                                        <defs>
                                                            <linearGradient id="colorDiarrhea" x1="0" y1="0" x2="0" y2="1">
                                                                <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3} />
                                                                <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
                                                            </linearGradient>
                                                            <linearGradient id="colorCholera" x1="0" y1="0" x2="0" y2="1">
                                                                <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.3} />
                                                                <stop offset="95%" stopColor="#f59e0b" stopOpacity={0} />
                                                            </linearGradient>
                                                            <linearGradient id="colorTyphoid" x1="0" y1="0" x2="0" y2="1">
                                                                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                                                                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                                                            </linearGradient>
                                                        </defs>
                                                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                                                        <XAxis dataKey="month" stroke="#64748b" tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={{ stroke: 'rgba(255,255,255,0.1)' }} />
                                                        <YAxis stroke="#64748b" tick={{ fill: '#94a3b8', fontSize: 11 }} tickLine={false} axisLine={{ stroke: 'rgba(255,255,255,0.1)' }} />
                                                        <Tooltip content={<CustomChartTooltip />} />
                                                        <Legend verticalAlign="top" height={36} wrapperStyle={{ color: '#cbd5e1', fontSize: '12px' }} iconType="circle" />

                                                        <Area type="monotone" dataKey="diarrhea" stroke="#ef4444" strokeWidth={2} fill="url(#colorDiarrhea)" name={t('charts.diarrhea')} activeDot={{ r: 6, strokeWidth: 0 }} />
                                                        <Area type="monotone" dataKey="cholera" stroke="#f59e0b" strokeWidth={2} fill="url(#colorCholera)" name={t('charts.cholera')} activeDot={{ r: 6, strokeWidth: 0 }} />
                                                        <Area type="monotone" dataKey="typhoid" stroke="#3b82f6" strokeWidth={2} fill="url(#colorTyphoid)" name={t('charts.typhoid')} activeDot={{ r: 6, strokeWidth: 0 }} />
                                                    </AreaChart>
                                                </ResponsiveContainer>
                                            ) : (
                                                <div className="d-flex flex-column justify-content-center align-items-center" style={{ height: '400px' }}>
                                                    <FaMapMarkerAlt size={40} className="text-white-50 mb-3" style={{ opacity: 0.3 }} />
                                                    <p className="text-white-50">{t('dashboard.noTrendData')}</p>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="jr-card mb-4" style={{ overflow: 'hidden' }}>
                                <div className="jr-card-header">
                                    <div className="jr-icon-wrapper"><FaVideo /></div>
                                    {t('emergencyTitle')}
                                </div>
                                <div className="table-responsive">
                                    <table className="jr-table">
                                        <thead>
                                            <tr>
                                                <th scope="col">{t('disease')}</th>
                                                <th scope="col">{t('state')}</th>
                                                <th scope="col">{t('severityLabel')}</th>
                                                <th scope="col">{t('responseTeam')}</th>
                                                <th scope="col">{t('lastUpdate')}</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {emergencyStatus.length > 0 ? (
                                                emergencyStatus.map((status) => (
                                                    <tr key={status.id}>
                                                        <td className="fw-semibold text-white">{status.disease_name}</td>
                                                        <td className="text-white-50">{status.state}</td>
                                                        <td>
                                                            <span className={`jr-badge-cell ${status.severity === 'Critical' ? 'jr-badge-critical' : status.severity === 'High' ? 'jr-badge-high' : 'jr-badge-medium'}`}>
                                                                {status.severity ? status.severity.toUpperCase() : 'UNKNOWN'}
                                                            </span>
                                                        </td>
                                                        <td className="text-cyan">
                                                            <span className="d-flex align-items-center gap-2">
                                                                <div style={{ width: 6, height: 6, borderRadius: '50%', background: 'currentColor' }}></div>
                                                                {status.response_status || 'Deployed'}
                                                            </span>
                                                        </td>
                                                        <td className="text-white-50 small">
                                                            {status.last_updated ? new Date(status.last_updated).toLocaleDateString() : 'N/A'}
                                                        </td>
                                                    </tr>
                                                ))
                                            ) : (
                                                <tr><td colSpan="5" className="text-center text-white-50 py-4">{t('dashboard.noEmergencies')}</td></tr>
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <div className="row mb-4">
                                <div className="col-12">
                                    <NewsCard />
                                </div>
                            </div>

                            <div className="text-center text-white-50 small mt-4 pb-4">
                                <p className="mb-0" style={{ fontSize: '0.75rem', letterSpacing: '0.05em', opacity: 0.6 }}>
                                    {t('disclaimer') || 'Data sourced from mock simulations & IDSP public records (Verified via WHO/MoHFW norms).'}
                                </p>
                            </div>
                        </motion.div >
                    )}
                    {
                        activeTab === 'waterData' && (
                            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="container-fluid p-0">
                                <form onSubmit={handleWaterFormSubmit}>
                                    <div className="water-grid-container">
                                        {/* Card 1: Water Source */}
                                        <div className="water-card">
                                            <div className="water-card-title">{t('waterSourceType')}</div>
                                            <CustomDropdown
                                                name="water_source_type"
                                                value={waterFormData.water_source_type}
                                                onChange={handleWaterInputChange}
                                                options={['River', 'Well', 'Lake', 'Pond', 'Tap Water', 'Borewell', 'Rainwater'].map(opt => ({
                                                    value: opt,
                                                    label: t(`waterSources.${opt === 'Tap Water' ? 'tap' : opt.toLowerCase()}`)
                                                }))}
                                                placeholder={t('selectSource')}
                                            />
                                        </div>

                                        {/* Card 2: pH Level */}
                                        <div className="water-card">
                                            <SafetyScale
                                                label="PH Level"
                                                name="ph"
                                                value={waterFormData.ph}
                                                min={0} max={14}
                                                trackType="ph"
                                                onChange={handleWaterInputChange}
                                            />
                                        </div>

                                        {/* Card 3: Contaminant */}
                                        <div className="water-card">
                                            <SafetyScale
                                                label={`${t('contaminant')} (ppm)`}
                                                name="contaminantLevel"
                                                value={waterFormData.contaminantLevel}
                                                min={0} max={1000}
                                                unit="ppm"
                                                onChange={handleWaterInputChange}
                                            />
                                        </div>

                                        {/* Card 4: Turbidity */}
                                        <div className="water-card">
                                            <SafetyScale
                                                label="Turbidity (NTU)"
                                                name="turbidity"
                                                value={waterFormData.turbidity}
                                                min={0} max={10}
                                                unit="NTU"
                                                onChange={handleWaterInputChange}
                                            />
                                        </div>

                                        {/* Card 5: Temperature */}
                                        <div className="water-card">
                                            <SafetyScale
                                                label="Temp Level (°C)"
                                                name="temperature"
                                                value={waterFormData.temperature}
                                                min={0} max={50}
                                                unit="°C"
                                                onChange={handleWaterInputChange}
                                            />
                                        </div>

                                        {/* Card 6: RGB Sensor */}
                                        <div className="water-card">
                                            <div className="water-card-title">RGB Sensor</div>
                                            <CustomDropdown
                                                name="uv_sensor"
                                                value={waterFormData.uv_sensor}
                                                onChange={handleWaterInputChange}
                                                options={['Red', 'Green', 'Blue']}
                                                placeholder="Select Color"
                                            />
                                        </div>

                                        {/* Card 7: UV Sensor */}
                                        <div className="water-card">
                                            <SafetyScale
                                                label="UV Sensor"
                                                name="guva_sensor"
                                                value={waterFormData.guva_sensor}
                                                min={0} max={15}
                                                unit="Index"
                                                onChange={handleWaterInputChange}
                                            />
                                        </div>

                                        {/* Card 8: Conductivity */}
                                        <div className="water-card">
                                            <SafetyScale
                                                label={`${t('conductivity')} (µS/cm)`}
                                                name="conductivity"
                                                value={waterFormData.conductivity}
                                                min={0} max={1000}
                                                unit="µS/cm"
                                                onChange={handleWaterInputChange}
                                            />
                                        </div>

                                        {/* Card 9: Dissolved Oxygen (NEW) */}
                                        <div className="water-card">
                                            <SafetyScale
                                                label="Dissolved Oxygen (mg/L)"
                                                name="dissolvedOxygen"
                                                value={waterFormData.dissolvedOxygen}
                                                min={0} max={20}
                                                unit="mg/L"
                                                onChange={handleWaterInputChange}
                                            />
                                        </div>
                                        {/* Prediction & Actions Card (Sidebar) */}
                                        <div className="water-card prediction-card">
                                            <div className="d-flex flex-column align-items-center justify-content-center h-100">
                                                <h3 className="h6 text-white mb-4 opacity-100 fw-bold">{t('initialPrediction')}</h3>

                                                <div style={{ transform: 'scale(1.1)', marginBottom: 'auto' }}>
                                                    <PredictionGauge
                                                        isAnalyzing={isWaterAnalyzing}
                                                        prediction={waterAnalysisResult?.risk_level}
                                                        confidence={waterAnalysisResult?.confidence}
                                                    />
                                                </div>

                                                <div className="d-flex flex-column gap-4 w-100 mt-4">
                                                    <div className="prediction-actions d-flex flex-column gap-3">
                                                        <button type="submit" className="btn-grid-submit" disabled={isWaterAnalyzing}>
                                                            {isWaterAnalyzing ? 'Analyzing...' : t('submitButton')}
                                                        </button>

                                                        <button
                                                            type="button"
                                                            className="btn-grid-fetch"
                                                            onClick={handleFetchFromDevice}
                                                            disabled={isFetching}
                                                        >
                                                            <FaDatabase size={14} /> {isFetching ? t('fetching') : t('fetchFromDevice')}
                                                        </button>
                                                    </div>

                                                    {fetchMessage && (
                                                        <div className="text-center small text-info">{fetchMessage}</div>
                                                    )}
                                                    {waterAnalysisError && (
                                                        <div className="text-center small text-danger bg-danger bg-opacity-10 p-2 rounded">{waterAnalysisError}</div>
                                                    )}

                                                    {waterAnalysisResult && (
                                                        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
                                                            <button
                                                                type="button"
                                                                onClick={handleSaveReading}
                                                                className="btn-grid-save"
                                                            >
                                                                <FaClipboardList className="me-2" /> {t('saveReading') || 'Save Readings'}
                                                            </button>
                                                        </motion.div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </form>
                            </motion.div>
                        )
                    }

                    {
                        activeTab === 'prediction' && (
                            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                                <div className="jr-card" style={{ width: '100%', margin: '0 auto' }}>
                                    <h2 className="card-title h3 fw-bold mb-4">{t('predictionTitle')}</h2>
                                    <p className="mb-4 text-muted">{t('predictionSubtitle')}</p>
                                    <div className="row">
                                        <div className="col-lg-6">
                                            <h3 className="h5 fw-bold mb-3">{t('patientInfo')}</h3>
                                            <form onSubmit={handleFormSubmit}>
                                                <div className="mb-3">
                                                    <label className="jr-label">{t('fullName')}</label>
                                                    <input
                                                        type="text"
                                                        className="jr-input w-100"
                                                        name="name"
                                                        value={formData.name}
                                                        onChange={handleInputChange}
                                                        placeholder={t('fullName')}
                                                        style={{ height: '45px' }}
                                                    />
                                                </div>
                                                <div className="row">
                                                    <div className="col-md-6 mb-3">
                                                        <label className="jr-label">{t('age')}</label>
                                                        <input
                                                            type="number"
                                                            className="jr-input w-100"
                                                            name="age"
                                                            value={formData.age}
                                                            onChange={handleInputChange}
                                                            placeholder={t('age')}
                                                            style={{ height: '45px' }}
                                                        />
                                                    </div>
                                                    <div className="col-md-6 mb-3">
                                                        <label className="jr-label">{t('gender')}</label>
                                                        <CustomDropdown
                                                            name="gender"
                                                            value={formData.gender}
                                                            onChange={handleInputChange}
                                                            placeholder={t('gender')}
                                                            options={[
                                                                { value: 'male', label: t('genderOptions.male') },
                                                                { value: 'female', label: t('genderOptions.female') },
                                                                { value: 'other', label: t('genderOptions.other') }
                                                            ]}
                                                        />
                                                    </div>
                                                </div>
                                                <div className="mb-3">
                                                    <label className="jr-label">{t('location')}</label>
                                                    <input
                                                        type="text"
                                                        className="jr-input w-100"
                                                        name="location"
                                                        value={formData.location}
                                                        onChange={handleInputChange}
                                                        placeholder={t('location')}
                                                        style={{ height: '45px' }}
                                                    />
                                                </div>
                                                <div className="mb-3">
                                                    <label className="jr-label">{t('symptoms')}</label>
                                                    <div className="p-3" style={{ maxHeight: '300px', overflowY: 'auto', background: 'rgba(15, 23, 42, 0.4)', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.05)' }}>
                                                        <div className="row">
                                                            {t('symptomsList', { returnObjects: true }).map((symptom, index) => (
                                                                <div key={index} className="col-md-6 mb-2">
                                                                    <div className="form-check">
                                                                        <input
                                                                            className="form-check-input"
                                                                            type="checkbox"
                                                                            checked={formData.symptoms.includes(symptom)}
                                                                            onChange={() => handleSymptomChange(symptom)}
                                                                            id={`symptom-${index}`}
                                                                            style={{ backgroundColor: formData.symptoms.includes(symptom) ? '#3b82f6' : 'transparent', borderColor: '#475569' }}
                                                                        />
                                                                        <label className="form-check-label text-white small" htmlFor={`symptom-${index}`}>
                                                                            {symptom}
                                                                        </label>
                                                                    </div>
                                                                </div>
                                                            ))}
                                                        </div>
                                                    </div>
                                                </div>
                                                <button type="submit" className="jr-btn-submit mt-3" disabled={isAnalyzing}>
                                                    {isAnalyzing ? t('analyzingPlaceholder') : t('submitButton')}
                                                </button>
                                            </form>
                                        </div>
                                        <div className="col-lg-6 mt-4 mt-lg-0">
                                            <h3 className="h5 fw-bold mb-3">{t('analysisTitle')}</h3>
                                            <div className="jr-card d-flex flex-column justify-content-center align-items-center text-center p-4" style={{ minHeight: '400px', border: '1px dashed rgba(255,255,255,0.2)', background: 'transparent' }}>
                                                {analysisResult ? (
                                                    <div className="w-100">
                                                        {analysisResult.length === 0 ? (
                                                            <div>
                                                                <FaInfoCircle className="text-warning mb-3" size={40} />
                                                                <h4 className="h6 fw-bold">{t('noDiseaseDetectedTitle')}</h4>
                                                                <p className="small text-muted">{t('noDiseaseDetectedDescription')}</p>
                                                            </div>
                                                        ) : (
                                                            <div className="d-flex flex-column gap-3">
                                                                {analysisResult.map((result, idx) => (
                                                                    <div key={idx} className="p-3 rounded text-start" style={{ background: 'rgba(59, 130, 246, 0.1)', borderLeft: '4px solid #3b82f6' }}>
                                                                        <div className="d-flex justify-content-between mb-1">
                                                                            <strong className="text-white">{result.name}</strong>
                                                                            <span className="badge bg-primary">{result.probability}% {t('match')}</span>
                                                                        </div>
                                                                        <p className="small text-muted mb-2">{result.description}</p>
                                                                        <div className="small">
                                                                            <strong className="text-white-50">{t('remedies')}</strong>
                                                                            <ul className="mb-0 ps-3">
                                                                                {result.remedies.map((remedy, rIdx) => (
                                                                                    <li key={rIdx} className="text-muted">{remedy}</li>
                                                                                ))}
                                                                            </ul>
                                                                        </div>
                                                                    </div>
                                                                ))}
                                                            </div>
                                                        )}
                                                    </div>
                                                ) : (
                                                    <>
                                                        <FaRobot className="text-muted mb-3" size={48} style={{ opacity: 0.3 }} />
                                                        <p className="text-muted">{isAnalyzing ? t('analyzingPlaceholder') : t('analysisPlaceholder')}</p>
                                                    </>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </motion.div>
                        )
                    }



                    {
                        activeTab === 'community' && (
                            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                                <div className="jr-card" style={{ maxWidth: '1200px', margin: '0 auto' }}>
                                    <div className="jr-card-header mb-0">
                                        <div className="jr-icon-wrapper"><FaUsers /></div>
                                        {t('communityTitle')}
                                    </div>
                                    <p className="mb-4 text-muted ps-3">{t('communitySubtitle')}</p>

                                    <div className="row p-3">
                                        <div className="col-lg-8">
                                            <h3 className="h5 fw-bold mb-3 text-white">{t('eventsTitle')}</h3>
                                            <div className="row row-cols-1 row-cols-md-2 g-4">
                                                {communityEvents.map(event => (
                                                    <div key={event.id} className="col">
                                                        <motion.div whileHover={{ scale: 1.03 }} className="jr-card h-100 p-0" style={{ background: 'rgba(255,255,255,0.03)' }}>
                                                            <div className="p-3 d-flex flex-column h-100">
                                                                <div className="d-flex justify-content-between align-items-start mb-2">
                                                                    <div className="d-flex align-items-center">
                                                                        {event.type === 'online' ? (
                                                                            <FaVideo size={20} className="text-primary me-2" />
                                                                        ) : (
                                                                            <FaMapMarkerAlt size={20} className="text-info me-2" />
                                                                        )}
                                                                        <div>
                                                                            <h4 className="h6 fw-bold mb-0 text-white">{event.title}</h4>
                                                                            <p className="small mb-0 text-muted">{event.type === 'online' ? event.platform : event.venue}</p>
                                                                        </div>
                                                                    </div>
                                                                    <span className="jr-badge jr-badge-safe">{t('upcoming')}</span>
                                                                </div>
                                                                <p className="mb-2 small flex-grow-1 text-white-50">{event.description}</p>
                                                                <div className="d-flex justify-content-between align-items-center mt-auto pt-2 border-top border-secondary">
                                                                    <small className="text-muted">{event.date}</small>
                                                                    <button className="jr-btn-fetch py-1 px-3" style={{ fontSize: '0.8rem' }}>{t('registerNow')}</button>
                                                                </div>
                                                            </div>
                                                        </motion.div>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>
                                        <div className="col-lg-4 mt-4 mt-lg-0">
                                            <h3 className="h5 fw-bold mb-3 text-white">{t('programHighlights')}</h3>
                                            <div className="d-flex flex-column gap-3">
                                                <motion.div whileHover={{ scale: 1.02 }} className="jr-card p-3 d-flex align-items-center text-center">
                                                    <div className="jr-icon-wrapper mb-2"><FaVideo /></div>
                                                    <h5 className="h6 fw-bold text-white">{t('onlinePrograms')}</h5>
                                                    <p className="small mb-0 text-muted">{t('highlights.online')}</p>
                                                </motion.div>
                                                <motion.div whileHover={{ scale: 1.02 }} className="jr-card p-3 d-flex align-items-center text-center">
                                                    <div className="jr-icon-wrapper mb-2"><FaUsers /></div>
                                                    <h5 className="h6 fw-bold text-white">{t('offlineEvents')}</h5>
                                                    <p className="small mb-0 text-muted">{t('highlights.offline')}</p>
                                                </motion.div>
                                                <motion.div whileHover={{ scale: 1.02 }} className="jr-card p-3 d-flex align-items-center text-center">
                                                    <div className="jr-icon-wrapper mb-2"><FaFlask /></div>
                                                    <h5 className="h6 fw-bold text-white">{t('waterTesting')}</h5>
                                                    <p className="small mb-0 text-muted">{t('highlights.testing')}</p>
                                                </motion.div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </motion.div>
                        )
                    }

                    {
                        activeTab === 'chat' && (
                            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="h-100">
                                <div className="jr-chat-page-container">
                                    {/* Main Chat Area */}
                                    <div className="jr-chat-main-area">
                                        {/* Header */}
                                        <div className="jr-chat-header">


                                            <div className="d-flex align-items-center gap-3">
                                                <div className="jr-icon-wrapper" style={{ width: 48, height: 48 }}><FaRobot size={24} /></div>
                                                <div>
                                                    <h2 className="h5 fw-bold text-white mb-0">{t('chatTitle')}</h2>
                                                    <div className="d-flex align-items-center gap-2">
                                                        <span className="bg-success rounded-circle" style={{ width: 8, height: 8 }}></span>
                                                        <span className="text-white-50 small">{t('onlineAI')}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Messages */}
                                        <div className="jr-chat-main-body" ref={mainChatRef}>
                                            {messages.map((msg) => (
                                                <div key={msg.id} className={`d-flex mb-4 ${msg.sender === 'user' ? 'justify-content-end' : 'justify-content-start'}`}>
                                                    {msg.sender === 'ai' && (
                                                        <div className="me-3 d-flex align-items-end mb-1">
                                                            <div className="jr-icon-wrapper" style={{ width: 36, height: 36 }}><FaRobot size={16} /></div>
                                                        </div>
                                                    )}
                                                    <div className={msg.sender === 'user' ? 'jr-chat-bubble-user' : 'jr-chat-bubble-ai'}>
                                                        <ReactMarkdown>{msg.text}</ReactMarkdown>
                                                        <div className={`mt-2 small opacity-50 ${msg.sender === 'user' ? 'text-end' : 'text-start'}`}>
                                                            {msg.timestamp}
                                                        </div>
                                                    </div>
                                                </div>
                                            ))}
                                            {isTyping && (
                                                <div className="d-flex justify-content-start mb-4">
                                                    <div className="me-3 d-flex align-items-end mb-1">
                                                        <div className="jr-icon-wrapper" style={{ width: 36, height: 36 }}><FaRobot size={16} /></div>
                                                    </div>
                                                    <div className="jr-chat-bubble-ai">
                                                        <div className="d-flex gap-1 py-1">
                                                            <div className="jr-typing-dot"></div>
                                                            <div className="jr-typing-dot"></div>
                                                            <div className="jr-typing-dot"></div>
                                                        </div>
                                                    </div>
                                                </div>
                                            )}
                                        </div>

                                        {/* Input Area */}
                                        <div className="jr-chat-fullscreen-input">
                                            <div className="jr-chat-input-group">
                                                <input
                                                    type="text"
                                                    value={userMessage}
                                                    onChange={(e) => setUserMessage(e.target.value)}
                                                    onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
                                                    placeholder={t('chatPlaceholder')}
                                                    className="jr-chat-input"
                                                    autoFocus
                                                />
                                                <button
                                                    onClick={handleSendMessage}
                                                    disabled={!userMessage.trim()}
                                                    className="jr-chat-send"
                                                >
                                                    <svg width="20" height="20" fill="currentColor" viewBox="0 0 16 16">
                                                        <path d="M15.854.146a.5.5 0 0 1 .11.54l-5.819 14.547a.75.75 0 0 1-1.329.124l-3.178-4.995L.643 7.184a.75.75 0 0 1 .124-1.33L15.314.037a.5.5 0 0 1 .54.11ZM6.636 10.07l2.761 4.338L14.13 2.576 6.636 10.07Zm6.787-8.201L1.591 6.602l4.339 2.76 7.494-7.493Z" />
                                                    </svg>
                                                </button>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Sidebar Info Panels */}
                                    <div className="jr-chat-sidebar d-none d-lg-flex">
                                        <div className="jr-info-card">
                                            <h4 className="h6 fw-bold text-white mb-3 d-flex align-items-center gap-2">
                                                <FaInfoCircle className="text-cyan" /> {t('quickHelp')}
                                            </h4>
                                            <div className="d-flex flex-column gap-2">
                                                <button onClick={() => setUserMessage(t('diseaseSymptoms'))} className="btn btn-sm btn-outline-light text-start border-0 bg-white bg-opacity-10 hover-bg-opacity-20 rounded-pill px-3">
                                                    🤒 {t('diseaseSymptoms')}
                                                </button>
                                                <button onClick={() => setUserMessage(t('preventionTips'))} className="btn btn-sm btn-outline-light text-start border-0 bg-white bg-opacity-10 hover-bg-opacity-20 rounded-pill px-3">
                                                    🛡️ {t('preventionTips')}
                                                </button>
                                                <button onClick={() => setUserMessage(t('waterTesting2'))} className="btn btn-sm btn-outline-light text-start border-0 bg-white bg-opacity-10 hover-bg-opacity-20 rounded-pill px-3">
                                                    🧪 {t('waterTesting2')}
                                                </button>
                                            </div>
                                        </div>

                                        <div className="jr-info-card">
                                            <h4 className="h6 fw-bold text-white mb-3">{t('chatFeatures')}</h4>
                                            <ul className="list-unstyled small text-muted mb-0 d-flex flex-column gap-2">
                                                <li className="d-flex gap-2"><span className="text-success">✔</span> {t('chatFeaturesList.aiSupport')}</li>
                                                <li className="d-flex gap-2"><span className="text-success">✔</span> {t('chatFeaturesList.multiLang')}</li>
                                                <li className="d-flex gap-2"><span className="text-success">✔</span> {t('chatFeaturesList.symptomAnalysis')}</li>
                                            </ul>
                                        </div>

                                        <div className="jr-info-card mt-auto" style={{ background: 'linear-gradient(135deg, rgba(1, 28, 64, 0.8) 0%, transparent 100%)' }}>
                                            <div className="d-flex align-items-center gap-2 mb-2">
                                                <FaShieldAlt className="text-cyan" size={20} />
                                                <span className="fw-bold text-white">Jal-Rakshak</span>
                                            </div>
                                            <p className="small text-white-50 mb-0">
                                                {t('footerSlogan')}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </motion.div>
                        )
                    }

                    {
                        activeTab === 'about' && (
                            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                                <div className="jr-card" style={{ maxWidth: '1000px', margin: '0 auto' }}>
                                    <div className="jr-card-header mb-4">
                                        <div className="jr-icon-wrapper"><FaInfoCircle /></div>
                                        {t('aboutTitle')}
                                    </div>
                                    <div className="row">
                                        <div className="col-lg-6">
                                            <h3 className="h5 fw-bold mb-3 text-white">{t('missionTitle')}</h3>
                                            <p className="mb-4 text-white-50">{t('missionText')}</p>

                                            <h3 className="h5 fw-bold mb-3 text-white">{t('visionTitle')}</h3>
                                            <p className="mb-4 text-white-50">{t('visionText')}</p>

                                            <h3 className="h5 fw-bold mb-3 text-white">{t('techStack')}</h3>
                                            <ul className="list-group list-group-flush bg-transparent">
                                                <li className="list-group-item bg-transparent text-white-50 border-secondary"><FaRobot className="me-2 text-primary" /> {t('techStackItems.aiModels')}</li>
                                                <li className="list-group-item bg-transparent text-white-50 border-secondary"><FaMicrochip className="me-2 text-success" /> {t('techStackItems.iotSensors')}</li>
                                                <li className="list-group-item bg-transparent text-white-50 border-secondary"><FaBolt className="me-2 text-warning" /> {t('techStackItems.alertSystem')}</li>
                                            </ul>
                                        </div>
                                        <div className="col-lg-6 mt-4 mt-lg-0">
                                            <h3 className="h5 fw-bold mb-3 text-white">{t('teamTitle')}</h3>
                                            <div className="d-flex flex-wrap justify-content-start gap-4 mt-4">
                                                {teamMembers.map((member, index) => (
                                                    <div key={index} className="text-center">
                                                        <div className="mb-2 position-relative" style={{ width: '80px', height: '80px' }}>
                                                            <img
                                                                src={`https://placehold.co/80x80/${['4ade80', '60a5fa', 'f59e0b', 'ef4444', '8b5cf6', '10b981'][index]}/ffffff?text=${member.name.charAt(0)}`}
                                                                alt={member.name}
                                                                className="rounded-circle w-100 h-100"
                                                                style={{ objectFit: 'cover', border: '2px solid rgba(255,255,255,0.2)' }}
                                                            />
                                                            <div className="position-absolute bottom-0 end-0 bg-success rounded-circle" style={{ width: '15px', height: '15px', border: '2px solid #0f172a' }}></div>
                                                        </div>
                                                        <div className="fw-bold small text-white">{t(`team.${member.name.toLowerCase()}`)}</div>
                                                        <div className="small text-muted" style={{ fontSize: '0.75rem' }}>{t('coreMember')}</div>
                                                    </div>
                                                ))}
                                            </div>

                                            <div className="mt-5 p-4 rounded bg-dark bg-opacity-50 border border-secondary">
                                                <h5 className="h6 fw-bold text-white mb-2">{t('joinCause')}</h5>
                                                <p className="small text-white-50 mb-3">{t('joinCauseText')}</p>
                                                <button className="jr-btn-fetch w-100" onClick={() => setShowContactModal(true)}>{t('contactUs')}</button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </motion.div>
                        )
                    }
                </main >
            </div >
            {
                selectedOutbreak && (
                    <div className="modal show d-block" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }} onClick={() => setSelectedOutbreak(null)}>
                        <div className="modal-dialog modal-lg" onClick={e => e.stopPropagation()}>
                            <div className={`modal-content ${darkMode ? 'bg-dark text-light' : ''}`}>
                                <div className="modal-header">
                                    <h5 className="modal-title">{selectedOutbreak.name}</h5>
                                    <button type="button" className="btn-close" onClick={() => setSelectedOutbreak(null)}></button>
                                </div>
                                <div className="modal-body">
                                    <div className="row">
                                        <div className="col-md-8">
                                            <p><strong>{t('state')}:</strong> {selectedOutbreak.state}</p>
                                            <p><strong>{t('cases')}:</strong> {selectedOutbreak.cases.toLocaleString()}</p>
                                            <p><strong>{t('rate')}:</strong> {selectedOutbreak.rate}/1000</p>
                                            <p><strong>{t('description')}:</strong> {t(`diseases.${selectedOutbreak.diseaseKey || 'gastroenteritis'}.description`)}</p>
                                        </div>
                                        <div className="col-md-4">
                                            <div className={`p-3 rounded ${darkMode ? 'bg-secondary' : 'bg-light'}`}>
                                                <h6>{t('statistics')}</h6>
                                                <div className="text-center my-3">
                                                    <div className="display-6 fw-bold text-danger">{selectedOutbreak.cases.toLocaleString()}</div>
                                                    <div className={`small ${darkMode ? 'text-light' : 'text-muted'}`}>{t('reportedCases')}</div>
                                                </div>
                                                <div className="progress mb-3" style={{ height: '8px' }}>
                                                    <div className="progress-bar bg-danger" role="progressbar" style={{ width: `${(selectedOutbreak.rate / 20) * 100}%` }}></div>
                                                </div>
                                                <div className="d-flex justify-content-between">
                                                    <span className={`small ${darkMode ? 'text-light' : 'text-muted'}`}>{t('rate')}: {selectedOutbreak.rate}/1000</span>
                                                    <span className={`small ${darkMode ? 'text-light' : 'text-muted'}`}>{t('location2')}: {selectedOutbreak.state}</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }

            {
                activeTab === 'readings' && (
                    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                        <div className="jr-card" style={{ maxWidth: '1000px', margin: '0 auto' }}>
                            <div className="jr-card-header mb-4 d-flex justify-content-between align-items-center">
                                <div className="d-flex align-items-center gap-2">
                                    <div className="jr-icon-wrapper"><FaClipboardList /></div>
                                    {t('savedReadings') || 'Saved Readings'}
                                </div>
                                <button className="jr-btn-fetch" style={{ width: 'auto' }} onClick={fetchReadings}>Refresh</button>
                            </div>

                            {savedReadings.length === 0 ? (
                                <div className="text-center py-5">
                                    <div className="text-white-50 mb-3" style={{ fontSize: '3rem' }}>
                                        <FaClipboardList />
                                    </div>
                                    <h5 className="text-white">No saved readings yet</h5>
                                    <p className="text-white-50 small">Submit water data to generate and save reports.</p>
                                </div>
                            ) : (
                                <div className="jr-readings-grid">
                                    {savedReadings.map((reading) => (
                                        <div key={reading.id} className="jr-reading-card">
                                            <div className="jr-reading-card-header" onClick={() => setSelectedReading(reading)}>
                                                <div className="d-flex align-items-center gap-2">
                                                    <div className="jr-source-icon">
                                                        {reading.water_source === 'River' || reading.water_source === 'Lake' ? <FaTint /> : <FaFaucet />}
                                                    </div>
                                                    <div>
                                                        <h6 className="mb-0 text-white fw-bold">{reading.device_name || t('manualEntry')}</h6>
                                                        <small className="text-white-50" style={{ fontSize: '0.75rem' }}>
                                                            {new Date(reading.timestamp).toLocaleDateString()}
                                                        </small>
                                                    </div>
                                                </div>
                                                <span className={`jr-reading-badge ${reading.risk_level === 'Safe' ? 'safe' : reading.risk_level === 'Unsafe' ? 'unsafe' : 'moderate'}`}>
                                                    {reading.risk_level}
                                                </span>
                                            </div>

                                            <div className="jr-reading-card-body" onClick={() => setSelectedReading(reading)}>
                                                <div className="d-flex justify-content-between align-items-center mb-2">
                                                    <span className="text-white-50 small">{t('source')}</span>
                                                    <span className="text-white small">{reading.water_source}</span>
                                                </div>
                                            </div>

                                            <div className="jr-reading-card-footer" style={{ position: 'relative', zIndex: 2 }}>
                                                <button
                                                    className="btn btn-sm btn-link text-white-50 p-0 text-decoration-none"
                                                    onClick={() => setSelectedReading(reading)}
                                                    style={{ position: 'relative', zIndex: 3 }}
                                                >
                                                    View Details
                                                </button>
                                                <button
                                                    className="btn btn-sm btn-icon text-danger"
                                                    onClick={async (e) => {
                                                        e.stopPropagation();
                                                        e.preventDefault();
                                                        console.log("Attempting to delete reading:", reading.id);
                                                        if (window.confirm(t('deleteReadingConfirm') || 'Delete this reading?')) {
                                                            try {
                                                                const { error } = await supabase.from('user_readings').delete().eq('id', reading.id);

                                                                if (error) {
                                                                    console.error("Delete error:", error);
                                                                    alert((t('deleteReadingError') || 'Error deleting: ') + error.message);
                                                                } else {
                                                                    console.log("Delete successful for ID:", reading.id);
                                                                    // Update local state immediately for better UI response
                                                                    setSavedReadings(prev => prev.filter(r => r.id !== reading.id));
                                                                    // Optional: still fetch to sync, but local update is crucial
                                                                    // fetchReadings(); 
                                                                }
                                                            } catch (err) {
                                                                console.error("Unexpected error deleting:", err);
                                                                alert("An unexpected error occurred while deleting.");
                                                            }
                                                        }
                                                    }}
                                                    style={{ position: 'relative', zIndex: 3 }}
                                                >
                                                    <FaTrash />
                                                </button>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </motion.div>
                )
            }

            {/* Selected Reading Details Modal */}
            {
                selectedReading && (
                    <div className="modal show d-block" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1055, backdropFilter: 'blur(5px)' }}>
                        <div className="modal-dialog modal-lg modal-dialog-centered">
                            <div className="jr-modal-glass">
                                <div className="jr-modal-header">
                                    <h5 className="modal-title d-flex align-items-center gap-2 text-white">
                                        <FaClipboardList className="text-primary" />
                                        {t('readingDetails')}
                                    </h5>
                                    <button type="button" className="jr-btn-close-glass" onClick={() => setSelectedReading(null)}>
                                        <FaTimes />
                                    </button>
                                </div>
                                <div className="jr-modal-body">
                                    <div className="row g-4">
                                        {/* General Info Section */}
                                        <div className="col-md-6">
                                            <div className="jr-info-section">
                                                <h6 className="jr-section-title">{t('generalInfo')}</h6>
                                                <div className="d-flex flex-column gap-3">
                                                    <div>
                                                        <div className="jr-modal-label">{t('deviceName')}</div>
                                                        <div className="jr-modal-value">{selectedReading.device_name || t('manualEntry')}</div>
                                                    </div>
                                                    <div>
                                                        <div className="jr-modal-label">{t('timestamp')}</div>
                                                        <div className="jr-modal-value fs-6">{new Date(selectedReading.timestamp).toLocaleString()}</div>
                                                    </div>
                                                    <div>
                                                        <div className="jr-modal-label">{t('source')}</div>
                                                        <div className="d-flex align-items-center gap-2 mt-1">
                                                            <span className="text-white fs-5">{selectedReading.water_source}</span>
                                                            <span className="jr-source-icon-small">
                                                                {selectedReading.water_source === 'River' || selectedReading.water_source === 'Lake' ? <FaTint /> : <FaFaucet />}
                                                            </span>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Analysis Section */}
                                        <div className="col-md-6">
                                            <div className="jr-info-section h-100">
                                                <h6 className="jr-section-title">{t('analysisResults')}</h6>
                                                <div className="d-flex flex-column gap-4">
                                                    <div>
                                                        <div className="jr-modal-label mb-2">{t('overallStatus')}</div>
                                                        <span className={`jr-reading-badge ${selectedReading.risk_level === 'Safe' ? 'safe' : selectedReading.risk_level === 'Unsafe' ? 'unsafe' : 'moderate'} fs-6 px-3 py-2`}>
                                                            {selectedReading.risk_level}
                                                        </span>
                                                    </div>
                                                    <div>
                                                        <div className="jr-modal-label mb-2">{t('predictionModel')}</div>
                                                        <div className="d-flex align-items-center gap-3">
                                                            <span className={`jr-reading-badge ${selectedReading.analysis_result?.risk_level === 'Safe' ? 'safe' : 'unsafe'} opacity-75`}>
                                                                {selectedReading.analysis_result?.risk_level || selectedReading.risk_level}
                                                            </span>
                                                            <div>
                                                                <div className="jr-modal-label">{t('confidence')}</div>
                                                                <div className="text-white fw-bold">{(selectedReading.confidence * 100).toFixed(1)}%</div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Water Parameters Grid */}
                                        <div className="col-12">
                                            <div className="jr-info-section">
                                                <h6 className="jr-section-title mb-4">{t('waterParameters')}</h6>
                                                <div className="jr-parameters-grid">
                                                    <div className="jr-parameter-item">
                                                        <div className="jr-modal-label">{t('phLevel')}</div>
                                                        <div className="jr-modal-large-value text-info">{selectedReading.ph}</div>
                                                    </div>
                                                    <div className="jr-parameter-item">
                                                        <div className="jr-modal-label">{t('turbidity')}</div>
                                                        <div className="jr-modal-large-value text-warning">{selectedReading.turbidity} <span className="fs-6 text-muted">NTU</span></div>
                                                    </div>
                                                    <div className="jr-parameter-item">
                                                        <div className="jr-modal-label">{t('contaminants')}</div>
                                                        <div className="jr-modal-large-value text-danger">{selectedReading.contaminant_level} <span className="fs-6 text-muted">ppm</span></div>
                                                    </div>
                                                    <div className="jr-parameter-item">
                                                        <div className="jr-modal-label">{t('temperature')}</div>
                                                        <div className="jr-modal-large-value text-primary">{selectedReading.temperature}<span className="fs-6 text-muted">°C</span></div>
                                                    </div>
                                                    <div className="jr-parameter-item">
                                                        <div className="jr-modal-label">{t('conductivity')}</div>
                                                        <div className="jr-modal-large-value text-success">{selectedReading.conductivity} <span className="fs-6 text-muted">µS/cm</span></div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div className="jr-modal-footer">
                                    <button type="button" className="jr-btn-glass" onClick={() => setSelectedReading(null)}>{t('close')}</button>
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }

            {/* Add Device Modal - Global */}
            {
                showAddDeviceModal && (
                    <div className="modal d-block" style={{ backgroundColor: 'rgba(0,0,0,0.7)', zIndex: 1060 }}>
                        <div className="modal-dialog modal-dialog-centered">
                            <div className="modal-content text-white" style={{ background: '#1e293b', border: '1px solid rgba(255,255,255,0.1)' }}>
                                <div className="modal-header border-secondary">
                                    <h5 className="modal-title">{t('addNewDevice')}</h5>
                                    <button type="button" className="btn-close btn-close-white" onClick={() => setShowAddDeviceModal(false)}></button>
                                </div>
                                <div className="modal-body">
                                    <form onSubmit={handleAddDevice}>
                                        <div className="mb-3">
                                            <label className="form-label text-muted">{t('deviceName')}</label>
                                            <input
                                                type="text"
                                                className="form-control bg-dark text-white border-secondary"
                                                value={newDeviceData.name}
                                                onChange={e => setNewDeviceData({ ...newDeviceData, name: e.target.value })}
                                                required
                                            />
                                        </div>
                                        <div className="mb-3">
                                            <label className="form-label text-muted">{t('deviceId')}</label>
                                            <input
                                                type="text"
                                                className="form-control bg-dark text-white border-secondary"
                                                value={newDeviceData.id}
                                                onChange={e => setNewDeviceData({ ...newDeviceData, id: e.target.value })}
                                                required
                                            />
                                        </div>
                                        <div className="d-grid">
                                            <button type="submit" className="btn btn-primary" disabled={deviceLoading}>
                                                {deviceLoading ? t('adding') : t('addNewDevice')}
                                            </button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }

            {/* Contact Us Modal */}
            {
                showContactModal && (
                    <div className="modal d-block" style={{ backgroundColor: 'rgba(0,0,0,0.7)', zIndex: 1060 }} onClick={() => setShowContactModal(false)}>
                        <div className="modal-dialog modal-dialog-centered" onClick={e => e.stopPropagation()}>
                            <div className="modal-content text-white" style={{ background: '#1e293b', border: '1px solid rgba(255,255,255,0.1)' }}>
                                <div className="modal-header border-secondary">
                                    <h5 className="modal-title">{t('contactUs')}</h5>
                                    <button type="button" className="btn-close btn-close-white" onClick={() => setShowContactModal(false)}></button>
                                </div>
                                <div className="modal-body">
                                    <div className="d-flex flex-column gap-3">
                                        <div className="p-3 rounded bg-dark bg-opacity-50 border border-secondary">
                                            <div className="d-flex align-items-center mb-1">
                                                <div className="bg-primary rounded-circle d-flex align-items-center justify-content-center me-2" style={{ width: '32px', height: '32px' }}>
                                                    <span className="fw-bold text-white">A</span>
                                                </div>
                                                <h6 className="fw-bold mb-0 text-white">Abhimanyu</h6>
                                            </div>
                                            <a href="mailto:abhimanyusharma.xi@gmail.com" className="text-decoration-none ms-5 d-block text-info small">abhimanyusharma.xi@gmail.com</a>
                                        </div>
                                        <div className="p-3 rounded bg-dark bg-opacity-50 border border-secondary">
                                            <div className="d-flex align-items-center mb-1">
                                                <div className="bg-warning rounded-circle d-flex align-items-center justify-content-center me-2" style={{ width: '32px', height: '32px' }}>
                                                    <span className="fw-bold text-white">R</span>
                                                </div>
                                                <h6 className="fw-bold mb-0 text-white">Rudra</h6>
                                            </div>
                                            <a href="mailto:rudrarana02006@gmail.com" className="text-decoration-none ms-5 d-block text-info small">rudrarana02006@gmail.com</a>
                                        </div>
                                        <div className="p-3 rounded bg-dark bg-opacity-50 border border-secondary">
                                            <div className="d-flex align-items-center mb-1">
                                                <div className="bg-info rounded-circle d-flex align-items-center justify-content-center me-2" style={{ width: '32px', height: '32px' }}>
                                                    <span className="fw-bold text-white">S</span>
                                                </div>
                                                <h6 className="fw-bold mb-0 text-white">Siddharth</h6>
                                            </div>
                                            <a href="mailto:siddharthjaspal@gmail.com" className="text-decoration-none ms-5 d-block text-info small">siddharthjaspal@gmail.com</a>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }
        </div >
    );
};

export default App;
