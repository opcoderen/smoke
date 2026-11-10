// 抽烟记录 · Cloudflare Worker（网页端单文件版）
// 页面 HTML 内嵌在下方 HTML 常量里，无需上传静态文件
// 需要一个 D1 绑定：变量名 DB
// 可选口令：在 Worker 设置里加环境变量 APP_KEY 后生效
// 2026-11-02 新增：GET /api/tap?k=口令 —— 服务端打时间戳的快速记录接口（供快捷指令/手表用）
// 2026-11-08 新增：标签页 favicon（🚬 emoji，深色圆角底，data URI 内嵌，无需上传图片）
const HTML = "<!DOCTYPE html>\n<html lang=\"zh-CN\">\n<head>\n<meta charset=\"UTF-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, viewport-fit=cover\">\n<title>\u62bd\u70df\u8bb0\u5f55</title>\n<link rel=\"icon\" href=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Crect width='100' height='100' rx='22' fill='%230f1115'/%3E%3Ctext x='50' y='75' font-size='60' text-anchor='middle'%3E%F0%9F%9A%AC%3C/text%3E%3C/svg%3E\">\n<meta name=\"theme-color\" content=\"#0f1115\">\n<style>\n  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }\n  body {\n    margin: 0; min-height: 100vh; background: #0f1115; color: #e8e6e1;\n    font-family: -apple-system, \"PingFang SC\", \"Microsoft YaHei\", sans-serif;\n    font-size: 15px; line-height: 1.5;\n  }\n  .wrap { max-width: 420px; margin: 0 auto; padding: 26px 20px calc(28px + env(safe-area-inset-bottom)); }\n\n  .head { font-size: 14px; color: #8a877f; text-align: center; margin-bottom: 22px; letter-spacing: .04em; }\n\n  .tap {\n    width: 100%; aspect-ratio: 1 / 1; max-width: 300px; margin: 0 auto;\n    display: flex; flex-direction: column; align-items: center; justify-content: center;\n    background: #181b21; border: 1px solid #2a2f38; border-radius: 50%;\n    cursor: pointer; user-select: none; transition: transform .12s, background .18s;\n  }\n  .tap:active { transform: scale(.97); background: #20242c; }\n  .tap .num { font-size: 76px; font-weight: 700; line-height: 1; color: #D85A30; font-variant-numeric: tabular-nums; }\n  .tap .unit { font-size: 13px; color: #8a877f; margin-top: 6px; }\n  .tap .last { font-size: 12px; color: #5f646d; margin-top: 14px; min-height: 16px; }\n  .hint { text-align: center; font-size: 12px; color: #5f646d; margin: 16px 0 26px; }\n\n  .stats { display: flex; gap: 10px; margin-bottom: 22px; }\n  .stat { flex: 1; background: #181b21; border-radius: 12px; padding: 12px 10px; text-align: center; }\n  .stat .v { font-size: 24px; font-weight: 700; line-height: 1.1; font-variant-numeric: tabular-nums; }\n  .stat .k { font-size: 11.5px; color: #8a877f; margin-top: 3px; }\n\n  .sec { display: flex; align-items: baseline; justify-content: space-between; margin-bottom: 8px; }\n  .sec h2 { font-size: 13px; font-weight: 500; color: #8a877f; margin: 0; }\n  .items { display: flex; flex-direction: column; }\n  .item {\n    display: flex; align-items: center; gap: 10px;\n    padding: 11px 2px; border-bottom: 1px solid #1e222a;\n    font-variant-numeric: tabular-nums;\n  }\n  .item:last-child { border-bottom: none; }\n  .item .t { flex: 1; font-size: 15px; }\n  .item .x {\n    background: none; border: none; color: #555a63; font-size: 20px; line-height: 1;\n    padding: 2px 8px; cursor: pointer;\n  }\n  .item .x:active { color: #D85A30; }\n  .empty { color: #555a63; font-size: 13px; padding: 14px 2px; }\n\n  .toast {\n    position: fixed; left: 50%; bottom: 34px; transform: translateX(-50%) translateY(8px);\n    background: #262b34; color: #fff; padding: 10px 16px; border-radius: 10px;\n    font-size: 13px; opacity: 0; transition: opacity .2s, transform .2s; pointer-events: none;\n    z-index: 9; display: flex; align-items: center; gap: 12px; max-width: 88vw;\n  }\n  .toast.show { opacity: 1; transform: translateX(-50%) translateY(0); pointer-events: auto; }\n  .toast button {\n    background: none; border: none; color: #D85A30; font-size: 13px; font-weight: 600;\n    padding: 0; cursor: pointer;\n  }\n\n  .gate {\n    position: fixed; inset: 0; background: #0f1115; z-index: 10;\n    display: none; flex-direction: column; align-items: center; justify-content: center;\n    padding: 24px;\n  }\n  .gate.show { display: flex; }\n  .gate .lock { font-size: 34px; margin-bottom: 10px; }\n  .gate h1 { font-size: 15px; font-weight: 500; color: #c9c6bf; margin: 0 0 22px; }\n  .gate input {\n    width: 100%; max-width: 280px; background: #181b21; border: 1px solid #2a2f38;\n    border-radius: 10px; color: #e8e6e1; font-size: 16px; padding: 12px 14px;\n    text-align: center; outline: none;\n  }\n  .gate input:focus { border-color: #D85A30; }\n  .gate button {\n    margin-top: 14px; width: 100%; max-width: 280px; background: #D85A30; border: none;\n    border-radius: 10px; color: #fff; font-size: 15px; font-weight: 600; padding: 12px;\n    cursor: pointer;\n  }\n  .gate button:active { opacity: .85; }\n  .gate .err { min-height: 18px; margin-top: 12px; font-size: 12.5px; color: #e0684a; }\n  .gate .tip { margin-top: 26px; font-size: 12px; color: #5f646d; }\n</style>\n</head>\n<body><div class=\"wrap\">\n  <div class=\"head\" id=\"head\">\u4eca\u5929</div>\n\n  <div class=\"tap\" id=\"tapBtn\">\n    <div class=\"num\" id=\"todayNum\">\u2013</div>\n    <div class=\"unit\">\u6839 \u00b7 \u4eca\u5929</div>\n    <div class=\"last\" id=\"lastTime\"></div>\n  </div>\n  <p class=\"hint\">\u8f7b\u70b9\u4e00\u4e0b = \u8bb0\u4e00\u6839</p>\n\n  <div class=\"stats\">\n    <div class=\"stat\"><div class=\"v\" id=\"weekNum\">\u2013</div><div class=\"k\">\u672c\u5468</div></div>\n    <div class=\"stat\"><div class=\"v\" id=\"monthNum\">\u2013</div><div class=\"k\">\u672c\u6708</div></div>\n  </div>\n\n  <div class=\"sec\"><h2>\u4eca\u5929\u7684\u8bb0\u5f55</h2></div>\n  <div class=\"items\" id=\"list\"></div>\n</div>\n\n<div class=\"toast\" id=\"toast\"></div>\n\n<div class=\"gate\" id=\"gate\">\n  <div class=\"lock\">\ud83d\udd12</div>\n  <h1>\u62bd\u70df\u8bb0\u5f55 \u00b7 \u8f93\u5165\u5bc6\u7801</h1>\n  <input type=\"password\" id=\"pwd\" placeholder=\"\u5bc6\u7801\" autocomplete=\"current-password\">\n  <button id=\"pwdBtn\">\u8fdb\u5165</button>\n  <div class=\"err\" id=\"pwdErr\"></div>\n  <div class=\"tip\">\u5bc6\u7801\u53ea\u4fdd\u5b58\u5728\u8fd9\u53f0\u8bbe\u5907\u4e0a\uff0c\u4e0b\u6b21\u4e0d\u7528\u518d\u8f93</div>\n</div>\n\n<script>\nconst $ = (id) => document.getElementById(id);\n\n// \u5bc6\u7801\uff1a\u9996\u6b21\u8f93\u5165\u540e\u4fdd\u5b58\u5728\u672c\u8bbe\u5907 localStorage\uff0c\u4e4b\u540e\u81ea\u52a8\u5e26\u4e0a\nlet KEY = (() => {\n  const fromUrl = new URLSearchParams(location.search).get(\"k\");\n  if (fromUrl) { localStorage.setItem(\"smoke_key\", fromUrl); return fromUrl; }\n  return localStorage.getItem(\"smoke_key\") || \"\";\n})();\n\nfunction pad(n) { return String(n).padStart(2, \"0\"); }\nfunction fmtDate(d) { return d.getFullYear() + \"-\" + pad(d.getMonth() + 1) + \"-\" + pad(d.getDate()); }\nfunction fmtTime(d) { return pad(d.getHours()) + \":\" + pad(d.getMinutes()); }\nfunction todayStr() { return fmtDate(new Date()); }\nfunction mondayStr() {\n  const d = new Date();\n  d.setDate(d.getDate() - ((d.getDay() + 6) % 7));\n  return fmtDate(d);\n}\nfunction monthStartStr() {\n  const d = new Date();\n  return fmtDate(new Date(d.getFullYear(), d.getMonth(), 1));\n}\n\nasync function api(path, options = {}) {\n  const headers = Object.assign({ \"content-type\": \"application/json\" }, options.headers || {});\n  if (KEY) headers[\"x-app-key\"] = KEY;\n  const res = await fetch(path, Object.assign({}, options, { headers }));\n  if (!res.ok) {\n    if (res.status === 401) throw new Error(\"\u9700\u8981\u53e3\u4ee4\");\n    let msg = \"\u7f51\u7edc\u95ee\u9898 \" + res.status;\n    try { const j = await res.json(); if (j && j.error) msg = j.error; } catch {}\n    throw new Error(msg);\n  }\n  return res.json();\n}\n\nlet toastTimer = null;\nfunction toast(msg, undoId) {\n  const t = $(\"toast\");\n  t.innerHTML = \"\";\n  const span = document.createElement(\"span\");\n  span.textContent = msg;\n  t.appendChild(span);\n  if (undoId != null) {\n    const b = document.createElement(\"button\");\n    b.textContent = \"\u64a4\u9500\";\n    b.addEventListener(\"click\", () => { hideToast(); remove(undoId, true); });\n    t.appendChild(b);\n  }\n  t.classList.add(\"show\");\n  clearTimeout(toastTimer);\n  toastTimer = setTimeout(hideToast, undoId != null ? 4000 : 2000);\n}\nfunction hideToast() { $(\"toast\").classList.remove(\"show\"); }\n\nfunction parseTime(s) {\n  const str = String(s || \"\");\n  const d = new Date(str.endsWith(\"Z\") || str.includes(\"+\") ? str : str + \"Z\");\n  return isNaN(d) ? new Date() : d;\n}\n\nasync function load(silent) {\n  const from = monthStartStr() < mondayStr() ? monthStartStr() : mondayStr();\n  let rows;\n  try {\n    rows = await api(\"/api/logs?from=\" + encodeURIComponent(from));\n  } catch (err) {\n    if (err.message === \"\u9700\u8981\u53e3\u4ee4\") { showGate(\"\"); return false; }\n    if (!silent) toast(\"\u52a0\u8f7d\u5931\u8d25\uff1a\" + err.message);\n    return false;\n  }\n  render(rows || []);\n  return true;\n}\n\n// ---- \u5bc6\u7801\u754c\u9762 ----\nfunction showGate(msg) {\n  $(\"pwdErr\").textContent = msg || \"\";\n  $(\"gate\").classList.add(\"show\");\n  setTimeout(() => $(\"pwd\").focus(), 60);\n}\nfunction hideGate() { $(\"gate\").classList.remove(\"show\"); }\n\nasync function tryUnlock() {\n  const v = $(\"pwd\").value.trim();\n  if (!v) { $(\"pwdErr\").textContent = \"\u8bf7\u8f93\u5165\u5bc6\u7801\"; return; }\n  $(\"pwdBtn\").disabled = true;\n  $(\"pwdErr\").textContent = \"\";\n  const oldKey = KEY;\n  KEY = v;\n  const ok = await load(true);\n  if (ok) {\n    localStorage.setItem(\"smoke_key\", v);\n    hideGate();\n  } else {\n    KEY = oldKey;\n    if ($(\"gate\").classList.contains(\"show\")) {\n      $(\"pwdErr\").textContent = \"\u5bc6\u7801\u4e0d\u5bf9\uff0c\u518d\u8bd5\u8bd5\";\n      $(\"pwd\").select();\n    }\n  }\n  $(\"pwdBtn\").disabled = false;\n}\n$(\"pwdBtn\").addEventListener(\"click\", tryUnlock);\n$(\"pwd\").addEventListener(\"keydown\", (e) => { if (e.key === \"Enter\") tryUnlock(); });\n\nfunction render(rows) {\n  const today = todayStr();\n  const todays = rows\n    .filter(r => r.local_date === today)\n    .sort((a, b) => parseTime(b.smoked_at) - parseTime(a.smoked_at));\n\n  $(\"todayNum\").textContent = todays.length;\n  $(\"lastTime\").textContent = todays.length ? \"\u6700\u8fd1 \" + fmtTime(parseTime(todays[0].smoked_at)) : \"\";\n  $(\"head\").textContent = new Date().toLocaleDateString(\"zh-CN\", { month: \"long\", day: \"numeric\", weekday: \"long\" });\n\n  const mon = mondayStr(), mStart = monthStartStr();\n  $(\"weekNum\").textContent = rows.filter(r => r.local_date >= mon).length;\n  $(\"monthNum\").textContent = rows.filter(r => r.local_date >= mStart).length;\n\n  const list = $(\"list\");\n  list.innerHTML = \"\";\n  if (todays.length === 0) {\n    list.innerHTML = '<div class=\"empty\">\u4eca\u5929\u8fd8\u6ca1\u8bb0</div>';\n    return;\n  }\n  todays.forEach(r => {\n    const row = document.createElement(\"div\");\n    row.className = \"item\";\n    const t = document.createElement(\"span\");\n    t.className = \"t\";\n    t.textContent = fmtTime(parseTime(r.smoked_at));\n    const x = document.createElement(\"button\");\n    x.className = \"x\";\n    x.textContent = \"\u00d7\";\n    x.setAttribute(\"aria-label\", \"\u5220\u9664 \" + t.textContent);\n    x.addEventListener(\"click\", () => remove(r.id));\n    row.appendChild(t);\n    row.appendChild(x);\n    list.appendChild(row);\n  });\n}\n\nasync function add() {\n  const now = new Date();\n  const btn = $(\"tapBtn\");\n  btn.style.pointerEvents = \"none\";\n  let row;\n  try {\n    row = await api(\"/api/logs\", {\n      method: \"POST\",\n      body: JSON.stringify({ local_date: fmtDate(now), smoked_at: now.toISOString() }),\n    });\n  } catch (err) {\n    btn.style.pointerEvents = \"\";\n    toast(\"\u6ca1\u8bb0\u4e0a\uff1a\" + err.message);\n    return;\n  }\n  btn.style.pointerEvents = \"\";\n  toast(\"\u5df2\u8bb0 \" + fmtTime(now), row && row.id);\n  load();\n}\n\nasync function remove(id, quiet) {\n  if (id == null) { toast(\"\u5220\u9664\u5931\u8d25\uff1a\u627e\u4e0d\u5230\u8fd9\u6761\"); return; }\n  try {\n    await api(\"/api/logs/\" + id, { method: \"DELETE\" });\n  } catch (err) {\n    toast(\"\u5220\u9664\u5931\u8d25\uff1a\" + err.message);\n    return;\n  }\n  if (!quiet) { hideToast(); toast(\"\u5df2\u5220\u9664\"); }\n  load();\n}\n\n$(\"tapBtn\").addEventListener(\"click\", add);\nload();\n</script>\n</body>\n</html>";
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/api/logs" || url.pathname === "/api/tap" || url.pathname.startsWith("/api/logs/")) {
      try {
        return await handleApi(request, env, url);
      } catch (err) {
        return json({ error: String(err && err.message || err) }, 500);
      }
    }
    return new Response(HTML, {
      headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" },
    });
  },
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });
}

function authorized(request, env, url) {
  if (!env.APP_KEY) return true; // 没设密钥就不校验
  const given = request.headers.get("x-app-key") || url.searchParams.get("k") || "";
  return given === env.APP_KEY;
}

async function handleApi(request, env, url) {
  if (!authorized(request, env, url)) return json({ error: "unauthorized" }, 401);
  const db = env.DB;

  // 快速记录：GET /api/tap?k=口令 —— 服务端打时间戳，供快捷指令/Apple Watch 一键调用
  if (request.method === "GET" && url.pathname === "/api/tap") {
    const now = new Date();
    let localDate;
    try {
      localDate = now.toLocaleDateString("sv-SE", { timeZone: env.TZ || "Asia/Shanghai" });
    } catch {
      localDate = now.toLocaleDateString("sv-SE");
    }
    const smokedAt = now.toISOString();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(localDate)) return json({ error: "bad local_date" }, 500);
    const row = await db
      .prepare("INSERT INTO smoke_logs (local_date, smoked_at) VALUES (?, ?) RETURNING id, local_date, smoked_at")
      .bind(localDate, smokedAt)
      .first();
    return json(row, 201);
  }

  if (request.method === "GET" && url.pathname === "/api/logs") {
    const from = url.searchParams.get("from");
    const stmt = from
      ? db.prepare("SELECT id, local_date, smoked_at FROM smoke_logs WHERE local_date >= ? ORDER BY smoked_at DESC").bind(from)
      : db.prepare("SELECT id, local_date, smoked_at FROM smoke_logs ORDER BY smoked_at DESC LIMIT 500");
    const { results } = await stmt.all();
    return json(results || []);
  }

  if (request.method === "POST" && url.pathname === "/api/logs") {
    let body;
    try { body = await request.json(); } catch { return json({ error: "bad json" }, 400); }
    const localDate = String(body.local_date || "").slice(0, 10);
    const smokedAt = String(body.smoked_at || new Date().toISOString());
    if (!/^\d{4}-\d{2}-\d{2}$/.test(localDate)) return json({ error: "bad local_date" }, 400);
    if (isNaN(Date.parse(smokedAt))) return json({ error: "bad smoked_at" }, 400);

    const row = await db
      .prepare("INSERT INTO smoke_logs (local_date, smoked_at) VALUES (?, ?) RETURNING id, local_date, smoked_at")
      .bind(localDate, smokedAt)
      .first();
    return json(row, 201);
  }

  if (request.method === "DELETE" && url.pathname.startsWith("/api/logs/")) {
    const id = Number(url.pathname.slice("/api/logs/".length));
    if (!Number.isInteger(id)) return json({ error: "bad id" }, 400);
    const row = await db.prepare("DELETE FROM smoke_logs WHERE id = ? RETURNING id").bind(id).first();
    if (!row) return json({ error: "not found" }, 404);
    return json(row);
  }

  return json({ error: "method not allowed" }, 405);
}
