import React, { useState, useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { FaMapMarkerAlt } from 'react-icons/fa';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { renderToString } from 'react-dom/server';

const OutbreakMap = ({ outbreaks, devices = [], title, mapId }) => {
    const { t } = useTranslation();
    const mapContainerRef = useRef(null);
    const mapInstanceRef = useRef(null);
    const markersLayerRef = useRef(null);
    const [shouldRender, setShouldRender] = useState(false);
    const [isInteractive, setIsInteractive] = useState(false);

    // Initial render delay to ensure client-side
    useEffect(() => {
        const timer = setTimeout(() => setShouldRender(true), 100);
        return () => clearTimeout(timer);
    }, []);

    // Initialize Map
    useEffect(() => {
        if (!shouldRender || !mapContainerRef.current) return;

        // CRITICAL FIX: Manually check and clean up any existing Leaflet instance on the container
        // This handles React Strict Mode's double-invocation behavior where cleanup might lag
        if (mapContainerRef.current._leaflet_id) {
            console.warn('Map container already has a Leaflet ID. Cleaning up...', mapContainerRef.current._leaflet_id);
            mapContainerRef.current._leaflet_id = null;
        }

        // Prevent double init if we track it in ref (though _leaflet_id check covers it)
        if (mapInstanceRef.current) {
            mapInstanceRef.current.remove();
            mapInstanceRef.current = null;
        }

        let mapCenter = [22.351114, 78.667742];
        let defaultZoom = 5;

        if (mapId === 'nearby') {
            mapCenter = [28.6139, 77.2090];
            defaultZoom = 12;
        }

        const map = L.map(mapContainerRef.current, {
            center: mapCenter,
            zoom: defaultZoom,
            zoomControl: false,
            attributionControl: false,
            scrollWheelZoom: false,
            dragging: false,
            touchZoom: false,
            doubleClickZoom: false
        });

        // Add Tile Layer
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);

        // Initialize Layer Group for markers
        const markersLayer = L.layerGroup().addTo(map);
        markersLayerRef.current = markersLayer;
        mapInstanceRef.current = map;

        // Cleanup
        return () => {
            if (map) {
                map.remove();
                mapInstanceRef.current = null;
            }
        };
    }, [shouldRender, mapId]);

    // Update Interactions
    useEffect(() => {
        const map = mapInstanceRef.current;
        if (!map) return;

        if (isInteractive) {
            map.dragging.enable();
            map.scrollWheelZoom.enable();
            map.touchZoom.enable();
            map.doubleClickZoom.enable();
            map.boxZoom.enable();
            map.keyboard.enable();
            if (map.tap) map.tap.enable();
        } else {
            map.dragging.disable();
            map.scrollWheelZoom.disable();
            map.touchZoom.disable();
            map.doubleClickZoom.disable();
            map.boxZoom.disable();
            map.keyboard.disable();
            if (map.tap) map.tap.disable();
        }
    }, [isInteractive, shouldRender]);

    // Update Markers
    useEffect(() => {
        const map = mapInstanceRef.current;
        const markersLayer = markersLayerRef.current;
        if (!map || !markersLayer) return;

        markersLayer.clearLayers();

        const getMarkerOptions = (outbreak) => {
            let color;
            switch (outbreak.severity) {
                case 'critical': color = '#ef4444'; break;
                case 'high': color = '#f97316'; break;
                case 'medium': color = '#3b82f6'; break;
                case 'low': color = '#10b981'; break;
                default: color = '#64748b';
            }
            return {
                radius: 5 + (outbreak.cases / 3000),
                fillColor: color,
                color: color,
                weight: 1,
                opacity: 1,
                fillOpacity: 0.6
            };
        };

        const getDeviceMarkerOptions = (device) => {
            let color = '#06b6d4'; // Cyan for devices
            if (device.status === 'alert') color = '#ef4444';

            return {
                radius: 8,
                fillColor: color,
                color: '#ffffff',
                weight: 2,
                opacity: 1,
                fillOpacity: 0.8
            };
        };

        // Add Outbreak Markers
        outbreaks.forEach(outbreak => {
            const popupContent = renderToString(
                <div style={{ color: 'black' }}>
                    <div className="fw-bold fs-6 mb-2">{outbreak.name}</div>
                    <div className="small mb-1"><FaMapMarkerAlt className="me-1" />{outbreak.state}</div>
                    <div className="mb-1"><strong>{t('cases')}:</strong> {outbreak.cases.toLocaleString()}</div>
                    <div className="mb-2"><strong className="text-capitalize">{t('severityLabel')}:</strong> <span style={{ color: getMarkerOptions(outbreak).fillColor }}>{t(`severity.${outbreak.severity}`)}</span></div>
                </div>
            );

            L.circleMarker(outbreak.position, getMarkerOptions(outbreak))
                .bindPopup(popupContent)
                .addTo(markersLayer);
        });

        // Add Device Markers
        devices.forEach(device => {
            const popupContent = renderToString(
                <div style={{ color: 'black' }}>
                    <div className="fw-bold fs-6 mb-1">{device.name}</div>
                    <div className="badge bg-primary mb-2">{device.type}</div>
                    <div className="small mb-1"><strong>{t('statusLabel')}:</strong> <span className={device.status === 'alert' ? 'text-danger fw-bold' : 'text-success'}>{t(`status.${device.status}`)}</span></div>
                    <div className="p-2 bg-light rounded border mt-2">
                        <div className="d-flex justify-content-between small mb-1"><span>{t('pH')}:</span> <strong>{device.readings.ph}</strong></div>
                        <div className="d-flex justify-content-between small mb-1"><span>{t('turbidity')}:</span> <strong>{device.readings.turbidity} NTU</strong></div>
                        <div className="d-flex justify-content-between small"><span>{t('battery')}:</span> <strong>{device.battery}</strong></div>
                    </div>
                </div>
            );

            L.circleMarker(device.position, getDeviceMarkerOptions(device))
                .bindPopup(popupContent)
                .addTo(markersLayer);
        });

    }, [outbreaks, devices, t, shouldRender]);


    if (!shouldRender) return <div className="p-5 text-center text-muted">Loading Map...</div>;

    return (
        <div
            className="jr-card mb-4 p-0 overflow-hidden h-100"
            onClick={() => setIsInteractive(true)}
            onMouseLeave={() => setIsInteractive(false)}
            style={{ cursor: isInteractive ? 'grab' : 'pointer' }}
        >
            <div className="p-3 border-bottom border-light border-opacity-10 bg-dark bg-opacity-25 d-flex justify-content-between align-items-center">
                <h5 className="mb-0 fs-6 fw-bold text-white"><FaMapMarkerAlt className="me-2 text-primary" />{title}</h5>
                {!isInteractive && <small className="text-white-50" style={{ fontSize: '0.7em' }}>{t('clickToInteract')}</small>}
            </div>
            {/* Raw Map Container */}
            <div
                ref={mapContainerRef}
                style={{
                    height: '400px',
                    width: '100%',
                    background: '#f8f9fa',
                }}
            />
        </div>
    );
};

export default OutbreakMap;
