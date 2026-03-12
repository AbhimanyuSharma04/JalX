import React, { useState } from 'react';
import { useRouter } from 'next/router';
import { supabase } from '../supabaseClient';
import { FaMapMarkerAlt } from 'react-icons/fa';
import { useTranslation } from 'react-i18next';

const LoginPage = ({ darkMode }) => {
    const { t } = useTranslation();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [name, setName] = useState('');
    const [location, setLocation] = useState('');
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');
    const [isRegistering, setIsRegistering] = useState(false);
    const [loading, setLoading] = useState(false);
    const [detectingLocation, setDetectingLocation] = useState(false);
    const router = useRouter();

    const handleLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setMessage('');

        try {
            const { data, error } = await supabase.auth.signInWithPassword({
                email,
                password,
            });

            if (error) throw error;

            setMessage(t('loginSuccess'));
            setTimeout(() => {
                router.push('/dashboard');
            }, 1000);

        } catch (error) {
            setError(error.message || t('loginFail'));
        } finally {
            setLoading(false);
        }
    };

    const handleRegister = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setMessage('');

        try {
            const { data, error } = await supabase.auth.signUp({
                email,
                password,
                options: {
                    data: {
                        full_name: name,
                        location: location,
                    },
                },
            });

            if (error) throw error;

            setMessage(t('registerSuccess'));
        } catch (error) {
            setError(error.message || t('registerFail'));
        } finally {
            setLoading(false);
        }
    };

    const detectLocation = () => {
        setDetectingLocation(true);
        setError('');

        if (!navigator.geolocation) {
            setError(t('locationError'));
            setDetectingLocation(false);
            return;
        }

        navigator.geolocation.getCurrentPosition(
            async (position) => {
                const { latitude, longitude } = position.coords;

                try {
                    const response = await fetch(`https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=en`);
                    const data = await response.json();

                    if (data && (data.city || data.locality || data.principalSubdivision)) {
                        const detectedLoc = data.city || data.locality || data.principalSubdivision;
                        setLocation(detectedLoc);
                        setMessage(t('locationDetected'));
                    } else {
                        setLocation(`${latitude}, ${longitude}`);
                        setMessage(t('locationDetected'));
                    }

                } catch (err) {
                    setLocation(`${latitude}, ${longitude}`);
                    console.error("Geocoding error:", err);
                } finally {
                    setDetectingLocation(false);
                }
            },
            (err) => {
                console.error("Geolocation error:", err);
                setError(t('locationError'));
                setDetectingLocation(false);
            }
        );
    };

    return (
        <div className="jr-app-wrapper d-flex align-items-center justify-content-center">
            <div className="jr-card p-4" style={{ maxWidth: '400px', width: '100%', backdropFilter: 'blur(16px)' }}>
                <div className="text-center mb-4">
                    <h2 className="fw-bold text-white">{isRegistering ? t('createAccount') : t('login')}</h2>
                    <p className="text-white-50 small">Welcome to Jal-Rakshak</p>
                </div>

                {error && <div className="alert alert-danger" role="alert">{error}</div>}
                {message && <div className="alert alert-success" role="alert">{message}</div>}

                <form onSubmit={isRegistering ? handleRegister : handleLogin}>
                    {isRegistering && (
                        <div className="mb-3">
                            <label className="jr-label">{t('name') || "Full Name"}</label>
                            <input
                                type="text"
                                className="jr-input"
                                placeholder={t('name') || "Full Name"}
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                required
                            />
                        </div>
                    )}

                    <div className="mb-3">
                        <label className="jr-label">{t('email')}</label>
                        <input
                            type="email"
                            className="jr-input"
                            placeholder="name@example.com"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                        />
                    </div>
                    <div className="mb-3">
                        <label className="jr-label">{t('password')}</label>
                        <input
                            type="password"
                            className="jr-input"
                            placeholder="********"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>

                    {isRegistering && (
                        <div className="mb-3">
                            <label className="jr-label">{t('location') || "Location"}</label>
                            <div className="input-group">
                                <input
                                    type="text"
                                    className="jr-input"
                                    placeholder={t('location') || "City, Country"}
                                    value={location}
                                    onChange={(e) => setLocation(e.target.value)}
                                    style={{ borderTopRightRadius: 0, borderBottomRightRadius: 0 }}
                                />
                                <button
                                    className="btn btn-outline-light"
                                    type="button"
                                    onClick={detectLocation}
                                    disabled={detectingLocation}
                                    title={t('detectingLocation')}
                                    style={{ borderColor: 'var(--jr-border)', borderTopLeftRadius: 0, borderBottomLeftRadius: 0 }}
                                >
                                    {detectingLocation ? <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> : <FaMapMarkerAlt />}
                                </button>
                            </div>
                            {detectingLocation && <div className="form-text text-white-50">{t('detectingLocation')}</div>}
                        </div>
                    )}

                    {!isRegistering && (
                        <div className="mb-3 text-end">
                            <button type="button" className="btn btn-link p-0 text-decoration-none text-info" style={{ fontSize: '0.9rem' }} onClick={() => alert(t('implementationPending'))}>{t('forgotPassword')}</button>
                        </div>
                    )}

                    <div className="d-grid gap-2 mt-4">
                        <button type="submit" className="jr-btn-submit" disabled={loading}>
                            {loading ? (
                                <>
                                    <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                                    {isRegistering ? t('registering') : t('loggingIn')}
                                </>
                            ) : (
                                isRegistering ? t('createAccount') : t('login')
                            )}
                        </button>
                    </div>
                </form>

                <div className="mt-4 text-center">
                    <p className="mb-0 text-white-50">
                        {isRegistering ? t('hasAccount') : t('noAccount')}
                        <button
                            className="btn btn-link text-decoration-none fw-bold text-info ms-2"
                            onClick={() => {
                                setIsRegistering(!isRegistering);
                                setError('');
                                setMessage('');
                            }}
                        >
                            {isRegistering ? t('login') : t('signup')}
                        </button>
                    </p>
                </div>
            </div>
        </div>
    );
};

export default LoginPage;
