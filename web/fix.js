const fs = require('fs');
let code = fs.readFileSync('src/app/admin/dashboard/page.tsx', 'utf8');

console.log("Original length:", code.length);

// 1. Update cardStyle definition
code = code.replace(
  'const cardStyle: React.CSSProperties = {\r\n  background: "#fff", borderRadius: 20, padding: 20,\r\n  boxShadow: "0 2px 12px rgba(0,0,0,0.05)", border: "1px solid #F3F4F6",\r\n};',
  'const cardStyle: React.CSSProperties = { padding: 20, borderRadius: 20 };'
);
code = code.replace(
  'const cardStyle: React.CSSProperties = {\n  background: "#fff", borderRadius: 20, padding: 20,\n  boxShadow: "0 2px 12px rgba(0,0,0,0.05)", border: "1px solid #F3F4F6",\n};',
  'const cardStyle: React.CSSProperties = { padding: 20, borderRadius: 20 };'
);

// 2. Wrap style={cardStyle} with the glassy classes
code = code.replace(/<([a-zA-Z]+)(.*?)style=\{cardStyle\}/g, '<$1$2className="auth-dynamo-glass match-dynamo-card match-card" style={cardStyle}');

// 3. Wrap style={{ ...cardStyle, ... }}
code = code.replace(/style=\{\{\s*\.\.\.cardStyle(.*?)\}\}/g, 'className="auth-dynamo-glass match-dynamo-card match-card" style={{$1}}');

// 4. Update StatCard inline styles
code = code.replace(
  'background: "#fff", borderRadius: 18, padding: "18px 20px", boxShadow: "0 2px 12px rgba(0,0,0,0.05)", border: "1px solid #F3F4F6"',
  'borderRadius: 18, padding: "18px 20px"'
);
code = code.replace(
  '<div style={{ borderRadius: 18, padding: "18px 20px"',
  '<div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 18, padding: "18px 20px"'
);

// 5. Update MetricCard inline styles
code = code.replace(
  /background: "#fff", borderRadius: 16, padding: 16, boxShadow: "0 2px 8px rgba(0,0,0,0.04)", border: "1px solid #F3F4F6"/g,
  'borderRadius: 16, padding: 16'
);
code = code.replace(
  /<div style=\{\{ borderRadius: 16, padding: 16/g,
  '<div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 16, padding: 16'
);

// 6. Update BookingCard inline styles
code = code.replace(
  /background: "#fff", borderRadius: 16, padding: "14px 16px", boxShadow: "0 1px 6px rgba(0,0,0,0.04)", border: "1px solid #F3F4F6"/g,
  'borderRadius: 16, padding: "14px 16px"'
);
code = code.replace(
  /<div style=\{\{ borderRadius: 16, padding: "14px 16px"/g,
  '<div className="auth-dynamo-glass match-dynamo-card match-card" style={{ borderRadius: 16, padding: "14px 16px"'
);

// 7. Update the main Wrapper and remove the welcome message
const oldWrapper1 = `  return (
    <div style={{ minHeight: "100vh", background: "#F3F4F6", display: "flex", flexDirection: "column" }}>
      <Navbar />
      <div style={{ maxWidth: 1100, width: "100%", margin: "0 auto", padding: "24px 16px 60px" }}>

        {/* Header */}
        <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 24, flexWrap: "wrap", gap: 16 }}>
          <div>
            <h1 style={{ fontSize: 26, fontWeight: 800, color: "#111827", margin: 0 }}>Hoş Geldiniz 👋</h1>
            <p style={{ fontSize: 14, color: "#9CA3AF", margin: "4px 0 0" }}>{todayFormatted()}</p>
          </div>`;

const newWrapper1 = `  return (
    <div className="page-wrapper" style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}>
      <Navbar />

      <div
        className="match-hero"
        style={{
          height: 280,
          background: "linear-gradient(180deg, #114B32 0%, #1A754E 100%)",
          position: "relative",
          zIndex: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <div style={{ position: "absolute", bottom: -118, left: 0, width: "100%", lineHeight: 0, zIndex: 0, pointerEvents: "none" }}>
          <svg data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 120" preserveAspectRatio="none" style={{ display: "block", width: "calc(100% + 1.3px)", height: 120, overflow: "visible" }}>
            <defs>
              <filter id="admin-wave-soft-shadow" x="-8%" y="-8%" width="116%" height="180%">
                <feGaussianBlur stdDeviation="7" />
              </filter>
            </defs>
            <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z" fill="rgba(0,0,0,0.22)" transform="translate(0, 14)" filter="url(#admin-wave-soft-shadow)" />
            <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z" fill="#1A754E" />
          </svg>
        </div>
      </div>

      <div className="content-container" style={{ position: "relative", zIndex: 2, marginTop: -150, paddingBottom: 60, maxWidth: 1100, width: "100%", margin: "-150px auto 0" }}>

        <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: 24 }}>`;

// Handle possible \r\n vs \n
let rOldWrapper1 = oldWrapper1.replace(/\n/g, '\r\n');
if (code.includes(rOldWrapper1)) {
  code = code.replace(rOldWrapper1, newWrapper1);
} else {
  code = code.replace(oldWrapper1, newWrapper1);
}

// Ensure "Tümü" and "Yönet" buttons have a slightly contrasting color since background is glassy now.
code = code.replace(/color: "#2E7D32"/g, 'color: "#1B5E20"');

fs.writeFileSync('src/app/admin/dashboard/page.tsx', code);
console.log("New length:", code.length);
console.log("Success");
