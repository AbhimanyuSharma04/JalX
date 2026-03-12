
import React, { useEffect, useState } from 'react';
import { FaNewspaper, FaExternalLinkAlt, FaGlobeAmericas, FaFlag } from 'react-icons/fa';
import { motion } from 'framer-motion';
import { useTranslation } from 'react-i18next';

const NewsCard = () => {
    const { t } = useTranslation();
    const [news, setNews] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const fetchNews = async () => {
            try {
                const response = await fetch('/api/health-news');
                if (!response.ok) throw new Error('Failed to fetch news');
                const data = await response.json();
                setNews(data);
            } catch (err) {
                console.error(err);
                setError('Unable to load latest health alerts.');
            } finally {
                setLoading(false);
            }
        };

        fetchNews();
    }, []);

    if (loading) {
        return (
            <div className="jr-card h-100 d-flex justify-content-center align-items-center" style={{ minHeight: '300px' }}>
                <div className="spinner-border text-primary" role="status">
                    <span className="visually-hidden">{t('newsCard.loading')}</span>
                </div>
            </div>
        );
    }

    return (
        <div className="jr-card h-100 d-flex flex-column">
            <div className="jr-card-header mb-3">
                <div className="jr-icon-wrapper">
                    <FaNewspaper />
                </div>
                <div>
                    {t('newsCard.title')}
                    <div className="text-white-50 small fw-normal mt-1" style={{ fontSize: '0.75rem' }}>
                        {t('newsCard.subtitle')}
                    </div>
                </div>
            </div>

            <div className="flex-grow-1 overflow-auto" style={{ maxHeight: '400px', scrollbarWidth: 'thin' }}>
                {error ? (
                    <div className="text-center text-white-50 p-4">
                        <p>{t('newsCard.error')}</p>
                    </div>
                ) : news.length === 0 ? (
                    <div className="text-center text-white-50 p-4">
                        <p>{t('newsCard.noAlerts')}</p>
                    </div>
                ) : (
                    <div className="d-flex flex-column gap-3">
                        {news.map((item, index) => {
                            const isIndia = item.country_scope === 'INDIA';
                            return (
                                <motion.div
                                    key={index}
                                    initial={{ opacity: 0, y: 10 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    whileHover={{ scale: 1.01, boxShadow: "0 8px 20px rgba(0,0,0,0.3)" }}
                                    transition={{ delay: index * 0.1 }}
                                    className="p-3 rounded mb-1 position-relative"
                                    style={{
                                        background: isIndia
                                            ? 'linear-gradient(135deg, rgba(249, 115, 22, 0.15) 0%, rgba(0, 0, 0, 0) 100%)'
                                            : 'linear-gradient(135deg, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0.01) 100%)',
                                        backdropFilter: 'blur(10px)',
                                        WebkitBackdropFilter: 'blur(10px)',
                                        border: '1px solid',
                                        borderColor: isIndia ? 'rgba(249, 115, 22, 0.5)' : 'rgba(255, 255, 255, 0.1)',
                                        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
                                    }}
                                >
                                    {/* Accent Line for India */}
                                    {isIndia && (
                                        <div
                                            className="position-absolute start-0 top-0 bottom-0 rounded-start"
                                            style={{ width: '4px', background: '#f97316' }}
                                        />
                                    )}

                                    <div className="d-flex justify-content-between align-items-start mb-2 ps-2">
                                        <div className="d-flex align-items-center gap-2 flex-wrap">
                                            {isIndia ? (
                                                <span
                                                    className="badge text-white d-flex align-items-center gap-1 shadow-sm"
                                                    style={{ background: 'linear-gradient(45deg, #f97316, #ea580c)' }}
                                                >
                                                    <FaFlag size={10} /> INDIA
                                                </span>
                                            ) : (
                                                <span
                                                    className="badge text-light d-flex align-items-center gap-1"
                                                    style={{ background: 'rgba(255, 255, 255, 0.15)', border: '1px solid rgba(255, 255, 255, 0.1)' }}
                                                >
                                                    <FaGlobeAmericas size={10} /> GLOBAL
                                                </span>
                                            )}
                                            <span
                                                className="badge text-white border border-opacity-25"
                                                style={{
                                                    background: 'rgba(220, 38, 38, 0.2)',
                                                    borderColor: 'rgba(220, 38, 38, 0.4)',
                                                    color: '#fca5a5'
                                                }}
                                            >
                                                {item.detected_disease}
                                            </span>
                                        </div>
                                        <small className="text-white-50" style={{ fontSize: '0.7rem' }}>
                                            {new Date(item.published_at).toLocaleDateString()}
                                        </small>
                                    </div>

                                    <div className="ps-2">
                                        <h6 className="fw-bold text-white mb-2" style={{ lineHeight: '1.4', fontSize: '0.95rem' }}>
                                            <a href={item.url} target="_blank" rel="noopener noreferrer" className="text-white text-decoration-none hover-highlight">
                                                {item.title}
                                            </a>
                                        </h6>

                                        <p className="text-white-50 small mb-2" style={{
                                            display: '-webkit-box',
                                            WebkitLineClamp: 2,
                                            WebkitBoxOrient: 'vertical',
                                            overflow: 'hidden',
                                            fontSize: '0.85rem'
                                        }}>
                                            {item.summary}
                                        </p>

                                        <div className="d-flex justify-content-between align-items-center mt-2 border-top border-light border-opacity-10 pt-2">
                                            <span className="text-info small" style={{ fontSize: '0.75rem', opacity: 0.8 }}>
                                                {t('newsCard.source')}: {item.source}
                                            </span>
                                            <a
                                                href={item.url}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="small text-decoration-none d-flex align-items-center gap-1 transition-all"
                                                style={{ color: isIndia ? '#fb923c' : '#60a5fa' }}
                                            >
                                                {t('newsCard.readMore')} <FaExternalLinkAlt size={10} />
                                            </a>
                                        </div>
                                    </div>
                                </motion.div>
                            );
                        })}
                    </div>
                )}
            </div>
            <div className="text-center text-white-50 small mt-3 pt-2 border-top border-secondary border-opacity-25">
                {t('newsCard.footer')}
            </div>
        </div>
    );
};

export default NewsCard;
