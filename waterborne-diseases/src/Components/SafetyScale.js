import React from 'react';
import { useTranslation } from 'react-i18next';


const SafetyScale = ({ value, min, max, label, unit, name, onChange, trackType = 'default' }) => {
  const { t } = useTranslation();

  // Logic: If empty, treat as min/0 for display logic, but keep value='' for input
  const numVal = value === '' ? min : parseFloat(value);
  const isValid = !isNaN(numVal);

  let status = 'neutral';
  let badgeText = '';

  if (isValid) {
    if (trackType === 'ph') {
      if (numVal >= 6.5 && numVal <= 8.5) { status = 'safe'; badgeText = t('safe'); }
      else { status = 'unsafe'; badgeText = t('unsafe'); }
    } else {
      // Default low=good assumption (contaminants)
      // If min is 0 and max is 10, range is 10.
      // 0-3.3: Safe, 3.3-6.6: Moderate, >6.6: Unsafe
      const range = max - min;
      if (numVal < min + range * 0.33) { status = 'safe'; badgeText = t('safe'); }
      else if (numVal < min + range * 0.66) { status = 'moderate'; badgeText = t('moderate'); }
      else { status = 'unsafe'; badgeText = t('unsafe'); }
    }
  }

  // Dynamic Gradient Construction
  let gradientBackground;
  if (trackType === 'ph') {
    // Red -> Orange -> Green -> Orange -> Red
    // 0-14 scale. Safe is ~7.
    gradientBackground = 'linear-gradient(90deg, #ef4444 0%, #f97316 25%, #10b981 45%, #10b981 55%, #f97316 75%, #ef4444 100%)';
  } else {
    // Green -> Yellow -> Red
    gradientBackground = 'linear-gradient(90deg, #10b981 0%, #f59e0b 50%, #ef4444 100%)';
  }

  return (
    <div className="safety-scale-container" style={{ position: 'relative', width: '100%' }}>
      {/* Badge Absolute Top-Right */}
      {badgeText && (
        <span
          className={`glass-badge ${status === 'safe' ? 'glass-badge-safe' : status === 'moderate' ? 'glass-badge-moderate' : 'glass-badge-unsafe'}`}
          style={{
            position: 'absolute',
            top: '-10px',
            right: '0px',
            fontSize: '0.7rem',
            padding: '4px 8px',
            borderRadius: '20px',
            fontWeight: '700',
            letterSpacing: '0.05em',
            zIndex: 2,
            boxShadow: '0 2px 10px rgba(0,0,0,0.2)'
          }}>
          {badgeText.toUpperCase()}
        </span>
      )}

      {/* Label Row */}
      <div className="d-flex justify-content-between align-items-end mb-3">
        <label className="form-label mb-0 fw-semibold text-white" style={{ fontSize: '0.95rem' }}>{label}</label>
      </div>

      {/* Slider Row - EXACT REFERENCE STYLE */}
      <div className="position-relative w-100 mb-3" style={{ height: '30px', display: 'flex', alignItems: 'center' }}>
        <input
          type="range"
          className="custom-safety-slider"
          min={min}
          max={max}
          step={trackType === 'ph' ? 0.1 : 0.01}
          name={name}
          value={isValid ? numVal : min}
          onChange={onChange}
          style={{
            background: gradientBackground,
            height: '8px', /* Original LUNA Thickness */
            borderRadius: '4px',
            boxShadow: 'inset 0 1px 2px rgba(0, 0, 0, 0.3)',
            width: '100%',
            appearance: 'none',
            WebkitAppearance: 'none',
            cursor: 'pointer'
          }}
        />
        {/* Note: ::-webkit-slider-thumb styles are global in Dashboard.css and should apply here automatically if class is correct */}
      </div>

      {/* Data Row: Input + Unit + Min Value */}
      <div className="d-flex justify-content-between align-items-center">
        <span className="text-white-50 opacity-50 small font-monospace">{min}</span>

        {/* Input Box - Bottom Right Alignment */}
        <div className="d-flex align-items-center gap-2">
          <div className="safety-input-wrapper" style={{
            background: 'rgba(1, 28, 64, 0.6)',
            border: '1px solid rgba(167, 235, 242, 0.15)',
            borderRadius: '8px',
            padding: '4px 10px',
            display: 'flex',
            alignItems: 'center',
            gap: '4px'
          }}>
            <input
              type="number"
              className="safety-input-field"
              min={min}
              max={max}
              step={trackType === 'ph' ? 0.1 : 0.01}
              name={name}
              value={value}
              onChange={onChange}
              placeholder={min.toString()}
              style={{
                fontSize: '0.9rem',
                padding: '2px 0',
                background: 'transparent',
                border: 'none',
                color: 'white',
                width: '50px',
                textAlign: 'right',
                fontWeight: '600'
              }}
            />
            {unit && <span className="text-white-50 small" style={{ fontSize: '0.8rem' }}>{unit}</span>}
          </div>
        </div>
      </div>
    </div>
  );
};


export default SafetyScale;
