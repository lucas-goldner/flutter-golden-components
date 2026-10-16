// The Golden Components mark: a Flutter-style chevron in gold on a dark tile.
// Shared by render.js (app icons + favicon) so every icon comes from one shape.

/** Gold strokes on a 64x64 grid. */
const MARK = `
  <defs>
    <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FDE68A"/>
      <stop offset="0.5" stop-color="#F5C451"/>
      <stop offset="1" stop-color="#C98A12"/>
    </linearGradient>
  </defs>
  <g stroke="url(#gold)" stroke-width="8.5" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <path d="M41 13 L19 35"/>
    <path d="M41 31 L29.5 42.5 L40 53"/>
  </g>`;

const TILE_BG = `
  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#1C1A16"/>
    <stop offset="1" stop-color="#0A0A0C"/>
  </linearGradient>`;

/**
 * SVG for the icon.
 * - `rounded`: dark rounded tile (favicon, web icons).
 * - `full`: full-bleed square, mark inside the safe zone (iOS, maskable).
 * - `mac`: macOS-style tile with transparent margin.
 */
function iconSvg(variant = 'rounded') {
  if (variant === 'full') {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs>${TILE_BG}</defs>
      <rect width="64" height="64" fill="url(#bg)"/>
      <g transform="translate(32 33) scale(0.72) translate(-32 -33)">${MARK}</g></svg>`;
  }
  if (variant === 'mac') {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs>${TILE_BG}
      <filter id="s" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="0.8" stdDeviation="1.2" flood-opacity="0.35"/></filter></defs>
      <rect x="6" y="6" width="52" height="52" rx="11.7" fill="url(#bg)" filter="url(#s)"/>
      <rect x="6.3" y="6.3" width="51.4" height="51.4" rx="11.4" fill="none" stroke="#F5C451" stroke-opacity="0.18" stroke-width="0.6"/>
      <g transform="translate(32 33) scale(0.68) translate(-32 -33)">${MARK}</g></svg>`;
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs>${TILE_BG}</defs>
    <rect width="64" height="64" rx="14" fill="url(#bg)"/>
    <rect x="0.75" y="0.75" width="62.5" height="62.5" rx="13.25" fill="none" stroke="#F5C451" stroke-opacity="0.22" stroke-width="1.5"/>
    <g transform="translate(32 33) scale(0.86) translate(-32 -33)">${MARK}</g></svg>`;
}

module.exports = { iconSvg };
