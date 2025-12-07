import { useEffect, useState } from "react";

// join base and path ensuring single slash between them
const joinApi = (base, path = "") =>
  `${String(base).replace(/\/+$/, "")}/${String(path).replace(/^\/+/, "")}`;

export default function App() {
  // without trailing slash by default
  const [apiUrl, setApiUrl] = useState("/api");
  const [hello, setHello] = useState("");
  const [time, setTime] = useState("");

  useEffect(() => {
    // Read config from global variable set in config.js
    const cfg = window.__APP_CONFIG__ || {};
    // normalize URL (without trailing slash)
    setApiUrl(String(cfg.API_URL || "/api").replace(/\/+$/, ""));
  }, []);

  const fetchHello = async () => {
    const r = await fetch(joinApi(apiUrl, "hello"));
    const j = await r.json();
    setHello(j.message);
  };

  const fetchTime = async () => {
    const r = await fetch(joinApi(apiUrl, "time"));
    const j = await r.json();
    setTime(j.now);
  };

  return (
    <main style={{ fontFamily: "sans-serif", padding: 24 }}>
      <h1>App Web (React)</h1>
      <p>API URL: <code>{apiUrl}</code></p>

      <div style={{ display: "flex", gap: 12 }}>
        <button onClick={fetchHello}>/api/hello</button>
        <button onClick={fetchTime}>/api/time</button>
      </div>

      <div style={{ marginTop: 16 }}>
        {hello && <p>hello: {hello}</p>}
        {time && <p>time: {time}</p>}
      </div>

      <p style={{ marginTop: 24, color: "#666" }}>
        Configurable en runtime con la variable de entorno <code>APP_API_URL</code>.
      </p>
    </main>
  );
}
