import express from "express";
import cors from "cors";
import { Pool } from "pg";
import { S3Client, PutObjectCommand, GetObjectCommand, ListObjectsV2Command } from "@aws-sdk/client-s3";
import { Readable } from "node:stream";

import { register, metricsMiddleware, timeIt, dbDuration, s3Duration } from "./metrics.js"; // <-

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(metricsMiddleware); // <— mide todas las requests

// ------- Configuración via env -------
// DB: preferimos una DATABASE_URL (postgres://user:pass@host:5432/db?sslmode=require)
const DATABASE_URL = process.env.DATABASE_URL;
// Si no usas URL, podés setear separados:
// const DB_HOST = process.env.DB_HOST;
// const DB_USER = process.env.DB_USER;
// const DB_PASS = process.env.DB_PASS;
// const DB_NAME = process.env.DB_NAME;
// const DB_PORT = process.env.DB_PORT || 5432;

// S3
const AWS_REGION = process.env.AWS_REGION || "us-east-1";
const S3_BUCKET = process.env.S3_BUCKET;

// ------- Postgres Pool -------
let pool;
if (DATABASE_URL) {
  pool = new Pool({
    connectionString: DATABASE_URL,
    // Para RDS suele requerirse SSL; en dev aceptamos cert por defecto
    ssl: { rejectUnauthorized: false },
  });
} else {
  pool = new Pool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT ? Number(process.env.DB_PORT) : 5432,
    ssl: { rejectUnauthorized: false },
  });
}

// Test de conexión al levantar
pool.connect()
  .then(c => c.release())
  .then(() => console.log("✅ Connected to Postgres"))
  .catch(err => console.error("❌ Postgres connection error:", err.message));

// ------- S3 Client (IRSA) -------
const s3 = new S3Client({ region: AWS_REGION });

// Helpers
const streamToString = (stream) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data", (c) => chunks.push(c));
    stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf-8")));
    stream.on("error", reject);
  });

// ------- Rutas básicas -------
app.get("/api/ping", (req, res) => {
  res.json({ ok: true });
});

app.get("/api/hello", (req, res) => {
  res.json({ message: "Hello from API 👋" });
});

app.get("/api/time", (req, res) => {
  res.json({ now: new Date().toISOString() });
});

// ------- Rutas DB -------

// Ping DB
app.get("/api/db/ping", async (_req, res) => {
  try {
    const r = await timeIt(dbDuration, { op: "ping" }, () =>
      pool.query("SELECT 1 as ok")
    );
    res.json({ ok: r.rows[0].ok === 1 });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

// Init tabla simple
app.post("/api/db/init", async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS demo_users (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);
    res.json({ ok: true, table: "demo_users" });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

// Insert
app.post("/api/db/users", async (req, res) => {
  try {
    const name = req.body?.name || "john doe";
    const r = await timeIt(dbDuration, { op: "insert" }, () =>
      pool.query("INSERT INTO demo_users (name) VALUES ($1) RETURNING *", [name])
    );
    res.json({ inserted: r.rows[0] });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

// List
app.get("/api/db/users", async (req, res) => {
  try {
    const r = await pool.query("SELECT id, name, created_at FROM demo_users ORDER BY id DESC LIMIT 50");
    res.json({ users: r.rows });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

// ------- Rutas S3 -------

// PUT objeto de demo (texto)
app.post("/api/s3/put", async (req, res) => {
  try {
    if (!S3_BUCKET) throw new Error("Missing env S3_BUCKET");
    const key = req.query.key || `demo-${Date.now()}.txt`;
    const content = req.body?.content || `hello from api at ${new Date().toISOString()}`;

    await timeIt(s3Duration, { op: "PutObject" }, () =>
      s3.send(new PutObjectCommand({
        Bucket: S3_BUCKET,
        Key: String(key),
        Body: content,
        ContentType: "text/plain",
      }))
    );

    res.json({ ok: true, bucket: S3_BUCKET, key });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

// GET objeto
app.get("/api/s3/get", async (req, res) => {
  try {
    if (!S3_BUCKET) throw new Error("Missing env S3_BUCKET");
    const key = req.query.key;
    if (!key) return res.status(400).json({ error: "missing ?key=" });
    const out = await s3.send(new GetObjectCommand({ Bucket: S3_BUCKET, Key: String(key) }));
    const text = await streamToString(out.Body instanceof Readable ? out.Body : Readable.from(out.Body));
    res.setHeader("Content-Type", out.ContentType || "text/plain");
    res.send(text);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

// LIST objetos (máx 50)
app.get("/api/s3/list", async (req, res) => {
  try {
    if (!S3_BUCKET) throw new Error("Missing env S3_BUCKET");
    const prefix = (req.query.prefix || "").toString();
    const out = await s3.send(new ListObjectsV2Command({ Bucket: S3_BUCKET, Prefix: prefix, MaxKeys: 50 }));
    res.json({
      bucket: S3_BUCKET,
      prefix,
      keys: (out.Contents || []).map(o => ({ key: o.Key, size: o.Size, lastModified: o.LastModified })),
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

app.listen(PORT, () => {
  console.log(`API listening on port ${PORT}`);
});


// endpoint de salud
app.get("/api/healthz", (_req, res) => {
  res.status(200).send("ok");
});

// endpoint de métricas
app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});