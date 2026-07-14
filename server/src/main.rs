//! ECHO ORBIT backend — reference implementation (docs/04 architecture).
//!
//! Offline-first philosophy: the client is the source of truth for progression;
//! this server provides anonymous auth, cloud-save sync (monotonic merge),
//! weekly leaderboards with sanity anti-cheat, and remote config (incl. the
//! daily seed for the weekly Gauntlet).
//!
//! Storage: a single JSON file (`data/store.json`), flushed on every mutation.
//! Swap for Postgres/Redis at scale; the HTTP contract stays identical.

use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        Path, Query, State,
    },
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Json},
    routing::{get, post, put},
    Router,
};
use futures::{SinkExt, StreamExt};
use rand::{distributions::Alphanumeric, Rng};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::{
    collections::HashMap,
    fs,
    path::PathBuf,
    sync::{Arc, RwLock},
    time::{SystemTime, UNIX_EPOCH},
};
use tokio::sync::broadcast;
use tower_http::cors::CorsLayer;

/* ---------------- persistent store ---------------- */

#[derive(Default, Serialize, Deserialize)]
struct Store {
    /// token -> uid
    tokens: HashMap<String, String>,
    /// uid -> profile blob (opaque to the server except merged counters)
    saves: HashMap<String, Value>,
    /// week key -> uid -> leaderboard entry
    leaderboards: HashMap<String, HashMap<String, LbEntry>>,
    /// universe seed -> uid -> best recorded ghost run (ghost racing)
    #[serde(default)]
    ghosts: HashMap<String, HashMap<String, GhostEntry>>,
    /// uid -> chosen display name (kid-safe sanitized; fallback star_name)
    #[serde(default)]
    names: HashMap<String, String>,
    /// lowercase pilot name -> account. Registration makes names UNIQUE;
    /// pass_hash is reserved for the upcoming password step (None = open).
    #[serde(default)]
    accounts: HashMap<String, Account>,
}

#[derive(Clone, Serialize, Deserialize)]
struct Account {
    uid: String,
    name: String,
    #[serde(default)]
    pass_hash: Option<String>,
    created: u64,
}

#[derive(Clone, Serialize, Deserialize)]
struct GhostEntry {
    name: String,
    height: u32,
    path: Vec<f32>,
    ts: u64,
}

#[derive(Clone, Serialize, Deserialize)]
struct LbEntry {
    name: String,
    height: u32,
    perfects: u32,
    prestige: u32,
    /// Galaxy the run was flown in (boards are per-galaxy; key = "uid:galaxy").
    #[serde(default)]
    galaxy: u32,
    /// Human-readable galaxy name as the client shows it (e.g. "EMBER NEBULA").
    #[serde(default)]
    gname: String,
    /// Career rank index computed client-side (same math as champion points
    /// over lifetime bests) — display-only, never affects scoring.
    #[serde(default)]
    rank: u32,
    ts: u64,
}

struct App {
    store: RwLock<Store>,
    path: PathBuf,
    /// Live multiplayer rooms: universe seed -> broadcast bus (never persisted).
    rooms: RwLock<HashMap<String, broadcast::Sender<String>>>,
}

impl App {
    fn load(path: PathBuf) -> Self {
        let store = fs::read_to_string(&path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();
        App {
            store: RwLock::new(store),
            path,
            rooms: RwLock::new(HashMap::new()),
        }
    }

    fn flush(&self) {
        if let Ok(store) = self.store.read() {
            if let Ok(json) = serde_json::to_string(&*store) {
                if let Some(dir) = self.path.parent() {
                    let _ = fs::create_dir_all(dir);
                }
                let _ = fs::write(&self.path, json);
            }
        }
    }
}

type Shared = Arc<App>;

/* ---------------- helpers ---------------- */

fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

/// Week bucket for leaderboards (docs/04: weekly ladders).
fn week_key() -> String {
    format!("week-{}", now() / (7 * 24 * 3600))
}

fn rand_string(n: usize) -> String {
    rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(n)
        .map(char::from)
        .collect()
}

/// Display name derived from uid — no PII, kid-safe (docs/02).
fn star_name(uid: &str) -> String {
    format!("Star-{}", &uid[..6.min(uid.len())])
}

fn auth_uid(app: &Shared, headers: &HeaderMap) -> Option<String> {
    let token = headers
        .get(header::AUTHORIZATION)?
        .to_str()
        .ok()?
        .strip_prefix("Bearer ")?
        .to_string();
    app.store.read().ok()?.tokens.get(&token).cloned()
}

/// The player's display name: their chosen one, else derived from the uid.
fn display_name(store: &Store, uid: &str) -> String {
    store
        .names
        .get(uid)
        .cloned()
        .unwrap_or_else(|| star_name(uid))
}

/// Galaxy difficulty curve — MUST mirror the client (`galaxyAt` in
/// echo_orbit_game.dart): 4 handcrafted galaxies, then an endless ladder.
fn galaxy_difficulty(i: u32) -> f64 {
    match i {
        0 => 1.0,
        1 => 1.18,
        2 => 1.38,
        3 => 1.6,
        _ => 1.6 + (i as f64 - 3.0) * 0.12,
    }
}

/// Champion points for one per-galaxy weekly best: height weighted by the
/// galaxy's difficulty (x10 for readable numbers) + 5 per perfect orbit.
fn champion_points(e: &LbEntry) -> u64 {
    (e.height as f64 * galaxy_difficulty(e.galaxy) * 10.0).round() as u64 + e.perfects as u64 * 5
}

/* ---------------- handlers ---------------- */

async fn health() -> impl IntoResponse {
    Json(json!({ "ok": true, "service": "echo-orbit", "week": week_key() }))
}

/// Remote config: live-tunable values + the daily seed (docs/06 A/B levers).
async fn config() -> impl IntoResponse {
    let day = now() / (24 * 3600);
    Json(json!({
        "dailySeed": day * 2654435761u64 % 4294967291u64,
        "tuning": {
            "flightSpeed": 560,
            "ringSpacing": 175,
            "perfectWindow": 0.34,
            "dustPerRing": 5,
            "novaMinHeight": 50,
            "adDailyCap": 6
        },
        "event": { "id": "first-light", "active": true, "theme": "mint" }
    }))
}

async fn auth_anonymous(State(app): State<Shared>) -> impl IntoResponse {
    let uid = rand_string(12);
    let token = rand_string(32);
    if let Ok(mut store) = app.store.write() {
        store.tokens.insert(token.clone(), uid.clone());
    }
    app.flush();
    Json(json!({ "uid": uid, "token": token }))
}

/// Resume a stored identity (Bearer token): the client keeps its anonymous
/// uid/token across launches so a player is ONE row on the boards, not one
/// per session.
async fn auth_resume(State(app): State<Shared>, headers: HeaderMap) -> impl IntoResponse {
    match auth_uid(&app, &headers) {
        Some(uid) => (StatusCode::OK, Json(json!({ "ok": true, "uid": uid }))),
        None => (StatusCode::UNAUTHORIZED, Json(json!({"error":"auth"}))),
    }
}

#[derive(Deserialize)]
struct AuthEnter {
    name: String,
    password: String,
}

fn hash_password(salt: &str, password: &str) -> String {
    use sha2::{Digest, Sha256};
    let mut h = Sha256::new();
    h.update(salt.as_bytes());
    h.update(password.as_bytes());
    h.finalize().iter().map(|b| format!("{b:02x}")).collect()
}

/// ALPHA login: one form, two behaviours. Unknown pilot name + password =>
/// the account is created; known name => the password must match. Same
/// fields every time — no email, no verification (post-alpha upgrade path:
/// this is the only place that mints account tokens).
async fn auth_enter(State(app): State<Shared>, Json(a): Json<AuthEnter>) -> impl IntoResponse {
    let name = sanitize_name(&a.name, "");
    if name.is_empty() || name.len() < 2 || name.starts_with("Star-") {
        return (StatusCode::UNPROCESSABLE_ENTITY, Json(json!({"error":"bad_name"})));
    }
    if a.password.len() < 3 {
        return (StatusCode::UNPROCESSABLE_ENTITY, Json(json!({"error":"bad_password"})));
    }
    let key = name.to_lowercase();
    let token = rand_string(32);
    let uid;
    let mut created = false;
    {
        let Ok(mut store) = app.store.write() else {
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({"error":"store"})));
        };
        if let Some(acc) = store.accounts.get(&key).cloned() {
            // Existing pilot: the same fields must match.
            let ok = match &acc.pass_hash {
                Some(sh) => sh
                    .split_once('$')
                    .map(|(salt, h)| hash_password(salt, &a.password) == h)
                    .unwrap_or(false),
                None => true, // legacy passwordless account: adopt this password
            };
            if !ok {
                return (StatusCode::UNAUTHORIZED, Json(json!({"error":"wrong_password"})));
            }
            uid = acc.uid.clone();
            if acc.pass_hash.is_none() {
                let salt = rand_string(16);
                let hash = hash_password(&salt, &a.password);
                if let Some(acc) = store.accounts.get_mut(&key) {
                    acc.pass_hash = Some(format!("{salt}${hash}"));
                }
            }
        } else {
            // First time: register the pilot.
            created = true;
            uid = rand_string(12);
            let salt = rand_string(16);
            let hash = hash_password(&salt, &a.password);
            store.accounts.insert(
                key,
                Account {
                    uid: uid.clone(),
                    name: name.clone(),
                    pass_hash: Some(format!("{salt}${hash}")),
                    created: now(),
                },
            );
        }
        store.tokens.insert(token.clone(), uid.clone());
        store.names.insert(uid.clone(), name.clone());
    }
    app.flush();
    (
        StatusCode::OK,
        Json(json!({ "ok": true, "uid": uid, "name": name, "token": token, "created": created })),
    )
}

/// Cloud save push. Merge policy (docs/04): monotonic counters take max,
/// everything else last-write-wins. The server never invents progress.
async fn save_put(
    State(app): State<Shared>,
    headers: HeaderMap,
    Json(incoming): Json<Value>,
) -> impl IntoResponse {
    let Some(uid) = auth_uid(&app, &headers) else {
        return (StatusCode::UNAUTHORIZED, Json(json!({"error":"auth"})));
    };
    const MONOTONIC: [&str; 8] = [
        "photons",
        "prestige",
        "bestHeight",
        "bestThisPrestige",
        "totalRuns",
        "dust",
        "playSeconds",
        "rankSeen",
    ];
    if let Ok(mut store) = app.store.write() {
        let merged = match store.saves.get(&uid) {
            Some(existing) => {
                let mut m = incoming.clone();
                if let (Some(obj), Some(old)) = (m.as_object_mut(), existing.as_object()) {
                    for key in MONOTONIC {
                        let new_v = obj.get(key).and_then(Value::as_i64).unwrap_or(0);
                        let old_v = old.get(key).and_then(Value::as_i64).unwrap_or(0);
                        if old_v > new_v {
                            obj.insert(key.into(), json!(old_v));
                        }
                    }
                }
                m
            }
            None => incoming,
        };
        store.saves.insert(uid, merged);
    }
    app.flush();
    (StatusCode::OK, Json(json!({"ok": true})))
}

async fn save_get(State(app): State<Shared>, headers: HeaderMap) -> impl IntoResponse {
    let Some(uid) = auth_uid(&app, &headers) else {
        return (StatusCode::UNAUTHORIZED, Json(json!({"error":"auth"})));
    };
    let blob = app
        .store
        .read()
        .ok()
        .and_then(|s| s.saves.get(&uid).cloned())
        .unwrap_or(Value::Null);
    (StatusCode::OK, Json(blob))
}

#[derive(Deserialize)]
struct ScoreSubmit {
    height: u32,
    #[serde(default)]
    perfects: u32,
    #[serde(default)]
    prestige: u32,
    #[serde(default)]
    galaxy: u32,
    #[serde(default)]
    gname: String,
    #[serde(default)]
    rank: u32,
}

/// Leaderboard submit with sanity anti-cheat (docs/04): implausible values
/// are rejected; cheating can never affect another player's economy.
async fn lb_submit(
    State(app): State<Shared>,
    headers: HeaderMap,
    Json(s): Json<ScoreSubmit>,
) -> impl IntoResponse {
    let Some(uid) = auth_uid(&app, &headers) else {
        return (StatusCode::UNAUTHORIZED, Json(json!({"error":"auth"})));
    };
    // Sanity bounds: heights beyond 2000 or perfects > height are implausible.
    if s.height == 0 || s.height > 2000 || s.perfects > s.height || s.galaxy > 500 {
        return (
            StatusCode::UNPROCESSABLE_ENTITY,
            Json(json!({"error":"implausible"})),
        );
    }
    if let Ok(mut store) = app.store.write() {
        let name = display_name(&store, &uid);
        let board = store.leaderboards.entry(week_key()).or_default();
        // Migrate a legacy plain-uid entry (pre-galaxy boards) to "uid:0" so
        // the same player never shows up twice on this week's board.
        if let Some(old) = board.remove(&uid) {
            let e0 = board
                .entry(format!("{uid}:0"))
                .or_insert_with(|| old.clone());
            if old.height > e0.height {
                *e0 = old;
            }
        }
        // One entry per player PER GALAXY — boards are separate per galaxy
        // and the champion score sums a player's bests across galaxies.
        let entry = board
            .entry(format!("{uid}:{}", s.galaxy))
            .or_insert(LbEntry {
                name: name.clone(),
                height: 0,
                perfects: 0,
                prestige: 0,
                galaxy: s.galaxy,
                gname: String::new(),
                rank: 0,
                ts: 0,
            });
        entry.name = name; // renames ripple through on the next submit
        entry.prestige = s.prestige;
        entry.rank = entry.rank.max(s.rank.min(50)); // ranks only climb
        entry.gname = s.gname.chars().take(24).collect();
        if s.height > entry.height {
            entry.height = s.height;
            entry.perfects = s.perfects;
            entry.ts = now();
        }
    }
    app.flush();
    (StatusCode::OK, Json(json!({"ok": true})))
}

/// `?galaxy=N` -> that galaxy's board (by height). No param -> CHAMPIONS:
/// every player's per-galaxy bests scored by difficulty and summed.
async fn lb_top(
    State(app): State<Shared>,
    Query(q): Query<HashMap<String, String>>,
) -> impl IntoResponse {
    let board: HashMap<String, LbEntry> = app
        .store
        .read()
        .ok()
        .and_then(|s| s.leaderboards.get(&week_key()).cloned())
        .unwrap_or_default();

    if let Some(g) = q.get("galaxy").and_then(|v| v.parse::<u32>().ok()) {
        // One row per pilot NAME: the same player on phone + web (two
        // anonymous uids) must not fill the board twice.
        let mut bestn: HashMap<String, LbEntry> = HashMap::new();
        for e in board.into_values().filter(|e| e.galaxy == g) {
            match bestn.get(&e.name) {
                Some(prev) if prev.height >= e.height => {}
                _ => {
                    bestn.insert(e.name.clone(), e);
                }
            }
        }
        let mut entries: Vec<LbEntry> = bestn.into_values().collect();
        entries.sort_by(|a, b| b.height.cmp(&a.height).then(a.ts.cmp(&b.ts)));
        entries.truncate(50);
        return Json(json!({ "week": week_key(), "galaxy": g, "entries": entries }));
    }

    // Champions: aggregate per player across all galaxies flown this week.
    struct Agg {
        name: String,
        score: u64,
        height: u32,
        galaxy: u32,
        gname: String,
        galaxies: u32,
        perfects: u32,
        prestige: u32,
        rank: u32,
        ts: u64,
    }
    // Best entry per (pilot NAME, galaxy) first — duplicate uids of the same
    // pilot (multiple sessions/devices, legacy keys) collapse here instead
    // of double-counting.
    let mut best: HashMap<String, HashMap<u32, LbEntry>> = HashMap::new();
    for (_key, e) in board {
        let slot = best.entry(e.name.clone()).or_default();
        match slot.get(&e.galaxy) {
            Some(prev) if prev.height >= e.height => {}
            _ => {
                slot.insert(e.galaxy, e);
            }
        }
    }
    let mut byuid: HashMap<String, Agg> = HashMap::new();
    for (name, gals) in best {
        for e in gals.into_values() {
            let a = byuid.entry(name.clone()).or_insert(Agg {
                name: e.name.clone(),
                score: 0,
                height: 0,
                galaxy: 0,
                gname: String::new(),
                galaxies: 0,
                perfects: 0,
                prestige: 0,
                rank: 0,
                ts: 0,
            });
            a.score += champion_points(&e);
            a.galaxies += 1;
            a.perfects += e.perfects;
            a.prestige = a.prestige.max(e.prestige);
            a.rank = a.rank.max(e.rank);
            a.ts = a.ts.max(e.ts);
            if e.galaxy >= a.galaxy {
                a.galaxy = e.galaxy; // deepest galaxy reached
                a.gname = e.gname.clone();
            }
            if e.height > a.height {
                a.height = e.height;
            }
            if e.ts >= a.ts {
                a.name = e.name; // freshest name wins
            }
        }
    }
    let mut entries: Vec<Agg> = byuid.into_values().collect();
    entries.sort_by(|a, b| b.score.cmp(&a.score).then(a.ts.cmp(&b.ts)));
    entries.truncate(50);
    let entries: Vec<Value> = entries
        .into_iter()
        .map(|a| {
            json!({
                "name": a.name, "score": a.score, "height": a.height,
                "galaxy": a.galaxy, "gname": a.gname, "galaxies": a.galaxies,
                "perfects": a.perfects, "prestige": a.prestige, "rank": a.rank,
            })
        })
        .collect();
    Json(json!({ "week": week_key(), "overall": true, "entries": entries }))
}

/* ---------------- player profile (naming system) ---------------- */

#[derive(Deserialize)]
struct NameSubmit {
    name: String,
}

/// Set the player's display name — shown on the leaderboard, ghost races and
/// live rooms. Kid-safe sanitized; renames update this week's board at once.
async fn profile_name(
    State(app): State<Shared>,
    headers: HeaderMap,
    Json(n): Json<NameSubmit>,
) -> impl IntoResponse {
    let Some(uid) = auth_uid(&app, &headers) else {
        return (StatusCode::UNAUTHORIZED, Json(json!({"error":"auth"})));
    };
    let name = sanitize_name(&n.name, &uid[..6.min(uid.len())]);
    if let Ok(mut store) = app.store.write() {
        store.names.insert(uid.clone(), name.clone());
        // rename ripples through the current week's leaderboard immediately
        // (board keys are "uid:galaxy"; legacy plain-uid keys still match)
        let prefix = format!("{uid}:");
        if let Some(board) = store.leaderboards.get_mut(&week_key()) {
            for (k, e) in board.iter_mut() {
                if k == &uid || k.starts_with(&prefix) {
                    e.name = name.clone();
                }
            }
        }
    }
    app.flush();
    (StatusCode::OK, Json(json!({"ok": true, "name": name})))
}

/* ---------------- ghost racing ---------------- */

#[derive(Deserialize)]
struct GhostSubmit {
    seed: i64,
    height: u32,
    path: Vec<f32>,
}

/// Publish a run's path for its universe seed. Keeps each player's best run
/// per seed; the board is pruned to the 25 best so the store stays small.
async fn ghost_submit(
    State(app): State<Shared>,
    headers: HeaderMap,
    Json(g): Json<GhostSubmit>,
) -> impl IntoResponse {
    let Some(uid) = auth_uid(&app, &headers) else {
        return (StatusCode::UNAUTHORIZED, Json(json!({"error":"auth"})));
    };
    // Sanity anti-cheat: implausible heights / malformed or huge paths.
    if g.height == 0
        || g.height > 2000
        || g.path.len() < 6
        || g.path.len() > 12000
        || g.path.len() % 2 != 0
    {
        return (
            StatusCode::UNPROCESSABLE_ENTITY,
            Json(json!({"error":"implausible"})),
        );
    }
    if let Ok(mut store) = app.store.write() {
        let name = display_name(&store, &uid);
        let board = store.ghosts.entry(g.seed.to_string()).or_default();
        let better = board.get(&uid).map_or(true, |e| g.height > e.height);
        if better {
            board.insert(
                uid.clone(),
                GhostEntry {
                    name,
                    height: g.height,
                    path: g.path,
                    ts: now(),
                },
            );
            if board.len() > 25 {
                let mut hs: Vec<(String, u32)> =
                    board.iter().map(|(k, e)| (k.clone(), e.height)).collect();
                hs.sort_by(|a, b| b.1.cmp(&a.1));
                let keep: std::collections::HashSet<String> =
                    hs.into_iter().take(25).map(|x| x.0).collect();
                board.retain(|k, _| keep.contains(k));
            }
        }
    }
    app.flush();
    (StatusCode::OK, Json(json!({"ok": true})))
}

#[derive(Deserialize)]
struct SeedQuery {
    seed: i64,
}

/// Top rival ghosts for a universe seed (name + height + path).
async fn ghost_top(State(app): State<Shared>, Query(q): Query<SeedQuery>) -> impl IntoResponse {
    let mut list: Vec<GhostEntry> = app
        .store
        .read()
        .ok()
        .and_then(|s| s.ghosts.get(&q.seed.to_string()).cloned())
        .unwrap_or_default()
        .into_values()
        .collect();
    list.sort_by(|a, b| b.height.cmp(&a.height).then(a.ts.cmp(&b.ts)));
    list.truncate(5);
    Json(json!({ "seed": q.seed, "ghosts": list }))
}

/* ---------------- live multiplayer rooms ---------------- */

#[derive(Deserialize)]
struct WsQuery {
    #[serde(default)]
    name: String,
}

/// Kid-safe display name: strip everything but word chars, cap the length.
fn sanitize_name(raw: &str, fallback: &str) -> String {
    let clean: String = raw
        .chars()
        .filter(|c| c.is_ascii_alphanumeric() || *c == '-' || *c == '_' || *c == ' ')
        .take(16)
        .collect();
    let clean = clean.trim().to_string();
    if clean.is_empty() {
        format!("Star-{fallback}")
    } else {
        clean
    }
}

/// Join a live room for one universe seed (same key as ghost racing).
/// Protocol: client sends {"x":..,"y":..,"h":..} at ~10 Hz; server relays
/// {"id","name","x","y","h"} to everyone in the room; on leave {"id","gone"}.
async fn ws_room(
    State(app): State<Shared>,
    Path(seed): Path<String>,
    Query(q): Query<WsQuery>,
    ws: WebSocketUpgrade,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| room_loop(app, seed, q.name, socket))
}

async fn room_loop(app: Shared, seed: String, raw_name: String, socket: WebSocket) {
    let id = rand_string(8);
    let name = sanitize_name(&raw_name, &id[..4]);
    let tx = {
        let mut rooms = match app.rooms.write() {
            Ok(r) => r,
            Err(_) => return,
        };
        rooms
            .entry(seed.clone())
            .or_insert_with(|| broadcast::channel::<String>(128).0)
            .clone()
    };
    let mut rx = tx.subscribe();
    let (mut sink, mut stream) = socket.split();

    // Tell the client its own id (so it can ignore its echoes) + room size.
    let hello = json!({ "you": id, "players": tx.receiver_count() }).to_string();
    if sink.send(Message::Text(hello)).await.is_err() {
        return;
    }

    loop {
        tokio::select! {
            incoming = stream.next() => match incoming {
                Some(Ok(Message::Text(t))) if t.len() <= 512 => {
                    if let Ok(v) = serde_json::from_str::<Value>(&t) {
                        let out = json!({
                            "id": id,
                            "name": name,
                            "x": v.get("x").and_then(Value::as_f64).unwrap_or(0.0),
                            "y": v.get("y").and_then(Value::as_f64).unwrap_or(0.0),
                            "h": v.get("h").and_then(Value::as_i64).unwrap_or(0),
                        });
                        let _ = tx.send(out.to_string());
                    }
                }
                Some(Ok(Message::Close(_))) | Some(Err(_)) | None => break,
                _ => {}
            },
            relayed = rx.recv() => match relayed {
                Ok(msg) => {
                    if sink.send(Message::Text(msg)).await.is_err() {
                        break;
                    }
                }
                Err(broadcast::error::RecvError::Lagged(_)) => {} // drop old frames
                Err(_) => break,
            },
        }
    }

    let _ = tx.send(json!({ "id": id, "gone": true }).to_string());
    drop(rx);
    if let Ok(mut rooms) = app.rooms.write() {
        if rooms.get(&seed).map_or(false, |s| s.receiver_count() == 0) {
            rooms.remove(&seed);
        }
    }
}

/* ---------------- main ---------------- */

#[tokio::main]
async fn main() {
    let app = Arc::new(App::load(PathBuf::from("data/store.json")));

    let router = Router::new()
        .route("/health", get(health))
        .route("/api/config", get(config))
        .route("/api/auth/anonymous", post(auth_anonymous))
        .route("/api/auth/resume", post(auth_resume))
        .route("/api/auth/enter", post(auth_enter))
        .route("/api/profile/name", post(profile_name))
        .route("/api/save", put(save_put).get(save_get))
        .route("/api/leaderboard/submit", post(lb_submit))
        .route("/api/leaderboard/top", get(lb_top))
        .route("/api/ghosts", get(ghost_top))
        .route("/api/ghosts/submit", post(ghost_submit))
        .route("/ws/room/:seed", get(ws_room))
        .layer(CorsLayer::permissive()) // web client runs from file:// or any origin
        .with_state(app);

    let addr = std::env::var("BIND").unwrap_or_else(|_| "0.0.0.0:8080".into());
    println!("ECHO ORBIT server listening on http://{addr}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("bind failed");
    axum::serve(listener, router).await.expect("server failed");
}
