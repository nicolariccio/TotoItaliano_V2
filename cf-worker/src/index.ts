export interface Env {
  API_FOOTBALL_KEY: string;
  APP_PROXY_TOKEN: string;
}

const UPSTREAM_HOST = "v3.football.api-sports.io";
const CACHE_TTL_SECONDS = 300; // 5 minuti: sufficiente a ridurre le chiamate senza dati stantii.

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "X-Proxy-Token, Content-Type",
  "Access-Control-Max-Age": "86400",
};

/**
 * Reverse proxy verso api-football, per due motivi:
 * 1) api-sports.io non espone header CORS, quindi il client Flutter Web
 *    non può chiamarla direttamente da browser (TypeError: Failed to
 *    fetch, verificato) — questo worker sì, aggiungendo CORS lui stesso.
 * 2) la vera API key resta un secret di Cloudflare (mai nel client): il
 *    client manda solo APP_PROXY_TOKEN, un token nostro senza valore
 *    economico, revocabile in un secondo senza toccare l'abbonamento
 *    api-football.
 */
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    if (request.method !== "GET") {
      return jsonResponse({ error: "method not allowed" }, 405);
    }

    const token = request.headers.get("X-Proxy-Token");
    if (!token || token !== env.APP_PROXY_TOKEN) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    const incoming = new URL(request.url);
    const upstreamUrl = `https://${UPSTREAM_HOST}${incoming.pathname}${incoming.search}`;

    const cache = caches.default;
    const cacheKey = new Request(upstreamUrl, request);
    const cached = await cache.match(cacheKey);
    if (cached) {
      return withCors(cached);
    }

    const upstreamResponse = await fetch(upstreamUrl, {
      headers: { "x-apisports-key": env.API_FOOTBALL_KEY },
    });

    const response = new Response(upstreamResponse.body, upstreamResponse);
    response.headers.set("Cache-Control", `public, max-age=${CACHE_TTL_SECONDS}`);
    withCors(response);

    if (upstreamResponse.ok) {
      // ctx.waitUntil non è disponibile in questa firma minimale: cache
      // best-effort, senza bloccare la risposta al client.
      cache.put(cacheKey, response.clone());
    }

    return response;
  },
};

function withCors(response: Response): Response {
  for (const [key, value] of Object.entries(CORS_HEADERS)) {
    response.headers.set(key, value);
  }
  return response;
}

function jsonResponse(body: unknown, status: number): Response {
  return withCors(
    new Response(JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json" },
    }),
  );
}
