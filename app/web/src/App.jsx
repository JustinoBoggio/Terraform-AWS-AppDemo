import { useEffect, useState } from "react";

export default function App() {
  const [apiUrl, setApiUrl] = useState("/api");
  const [hello, setHello] = useState("");
  const [time, setTime] = useState("");

  useEffect(() => {
    // lee config generada en runtime por entrypoint.sh
    const cfg = window.__APP_CONFIG__ || {};
    setApiUrl(cfg.API_URL || "/api");
  }, []);

  const fetchHello = async () => {
    const r = await fetch(`${apiUrl}/hello`);
    const j = await r.json();
    setHello(j.message);
  };

  const fetchTime = async () => {
    const r = await fetch(`${apiUrl}/time`);
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
