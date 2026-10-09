// Elegant stand-in when a cake has no photo yet.
export default function Placeholder({ label }) {
  return (
    <div className="placeholder" role="img" aria-label={label || "Cake illustration"}>
      <svg viewBox="0 0 120 120" width="46%" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
        <path d="M60 14c4 6 4 10 0 14-4-4-4-8 0-14z" />
        <path d="M60 30v10" />
        <rect x="30" y="40" width="60" height="22" rx="8" />
        <rect x="18" y="62" width="84" height="30" rx="10" />
        <path d="M30 76c6 6 12 6 18 0s12-6 18 0 12 6 18 0" />
        <path d="M12 100h96" />
      </svg>
    </div>
  );
}
