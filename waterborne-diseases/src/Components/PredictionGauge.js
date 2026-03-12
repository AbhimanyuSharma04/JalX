import React from 'react';
import { motion } from 'framer-motion';
import { useTranslation } from 'react-i18next';

const PredictionGauge = ({ prediction, confidence, isAnalyzing }) => {
    const { t } = useTranslation();
    // Normalize prediction string
    const normalizedPred = (prediction || "").toString().toLowerCase();

    // Determine angle based on prediction
    let angle = -90; // Starting point (Safe)
    let label = t('safe'); // Default to Safe key logic check below
    let color = "#10b981"; // Green

    if (['safe', 'good', 'low', 'normal'].includes(normalizedPred)) {
        angle = -60;
        label = t('safe');
        color = "#10b981";
    } else if (['moderate', 'medium', 'warning'].includes(normalizedPred)) {
        angle = 0;
        label = t('moderate');
        color = "#f59e0b";
    } else if (['unsafe', 'high risk', 'high', 'danger', 'critical', 'bad'].includes(normalizedPred)) {
        angle = 60;
        label = t('highRisk');
        color = "#ef4444";
    } else {
        // Default / Neutral
        angle = -90;
        label = t('ready', { defaultValue: 'Ready' });
        color = "#94a3b8";
    }

    // Analyzing state animation
    const needleVariant = {
        analyzing: {
            rotate: [-90, 90, -90],
            transition: { duration: 2, repeat: Infinity, ease: "easeInOut" }
        },
        result: {
            rotate: angle,
            transition: { type: "spring", stiffness: 50, damping: 10 }
        }
    };

    return (
        <div className="d-flex flex-column align-items-center justify-content-center p-3">
            {/* Gauge Container - Corrected Aspect Ratio */}
            <div style={{ position: 'relative', width: '220px', height: '120px', overflow: 'hidden', display: 'flex', justifyContent: 'center' }}>
                {/* Background Arc */}
                <svg width="220" height="110" viewBox="0 0 220 110">
                    <defs>
                        <linearGradient id="gaugeGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                            <stop offset="0%" stopColor="#10b981" />
                            <stop offset="50%" stopColor="#f59e0b" />
                            <stop offset="100%" stopColor="#ef4444" />
                        </linearGradient>
                    </defs>
                    {/* Track (Darker) */}
                    <path d="M 20 110 A 90 90 0 0 1 200 110" fill="none" stroke="#1e293b" strokeWidth="15" strokeLinecap="round" />

                    {/* Gradient Arc (Overlay) */}
                    <path d="M 20 110 A 90 90 0 0 1 200 110" fill="none" stroke="url(#gaugeGradient)" strokeWidth="15" strokeLinecap="round" />
                </svg>

                {/* Needle */}
                <motion.div
                    initial={{ rotate: -90 }}
                    animate={{ rotate: isAnalyzing ? [-90, 90, -90] : angle }}
                    transition={isAnalyzing ? { repeat: Infinity, duration: 2, ease: "linear" } : { type: "spring", stiffness: 50, damping: 10 }}
                    style={{
                        position: 'absolute',
                        bottom: '10px',
                        left: '50%',
                        width: '4px',
                        height: '90px',
                        backgroundColor: '#e2e8f0', // Lighter needle for contrast
                        transformOrigin: 'bottom center',
                        marginLeft: '-2px',
                        zIndex: 10,
                        boxShadow: '0 0 5px rgba(255,255,255,0.5)'
                    }}
                />
                {/* Hub */}
                <div style={{ position: 'absolute', bottom: '0px', left: '50%', transform: 'translateX(-50%)', width: '20px', height: '20px', borderRadius: '50%', backgroundColor: '#e2e8f0', zIndex: 11, boxShadow: '0 0 5px rgba(255,255,255,0.5)' }}></div>

            </div>

            <div className="text-center mt-3 w-100">
                <h4 className="fw-bold mb-0 text-white" style={{ textShadow: `0 0 15px ${color}` }}>
                    {isAnalyzing ? t('analyzing') : label}
                </h4>

                {!isAnalyzing && normalizedPred === "" && <small className="text-white-50">{t('predictedByAI')}</small>}
            </div>
        </div>
    );
};

export default PredictionGauge;
