import client from "prom-client";

export const register = new client.Registry();

// Métricas “default” de proceso/node
client.collectDefaultMetrics({ register });

// HTTP: latencia por método/ruta/código
export const httpDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request latency",
  labelNames: ["method", "route", "code"],
  buckets: [0.05, 0.1, 0.25, 0.5, 1, 2, 5],
});
register.registerMetric(httpDuration);

// DB: duración por operación (select/insert/…)
export const dbDuration = new client.Histogram({
  name: "db_query_duration_seconds",
  help: "DB query duration",
  labelNames: ["op"],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2],
});
register.registerMetric(dbDuration);

// S3: duración por operación (PutObject/GetObject/ListObjectsV2)
export const s3Duration = new client.Histogram({
  name: "s3_operation_duration_seconds",
  help: "S3 operation duration",
  labelNames: ["op"],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2],
});
register.registerMetric(s3Duration);

// Middleware que mide TODA request HTTP
export function metricsMiddleware(req, res, next) {
  const end = httpDuration.startTimer({ method: req.method });
  res.on("finish", () => {
    const route =
      (req.route && req.route.path) ||
      req.path ||
      "unknown";
    end({ route, code: res.statusCode });
  });
  next();
}

// Helper para medir funciones async (DB/S3)
export async function timeIt(hist, labels, fn) {
  const end = hist.startTimer(labels);
  try {
    return await fn();
  } finally {
    end();
  }
}
