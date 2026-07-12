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
    extract::{Query, State},
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Json},
    routing::{get, post, put},
    Router,
};
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
    ts: u64,
}

struct App {
    store: RwLock<Store>,
    path: PathBuf,
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
    const MONOTONIC: [&str; 6] = [
        "photons",
        "prestige",
        "bestHeight",
        "bestThisPrestige",
        "totalRuns",
        "dust",
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
    if s.height == 0 || s.height > 2000 || s.perfects > s.height {
        return (StatusCode::UNPROCESSABLE_ENTITY, Json(json!({"error":"implausible"})));
    }
    if let Ok(mut store) = app.store.write() {
        let board = store.leaderboards.entry(week_key()).or_default();
        let entry = board.entry(uid.clone()).or_insert(LbEntry {
            name: star_name(&uid),
            height: 0,
            perfects: 0,
            prestige: 0,
            ts: 0,
        });
        if s.height > entry.height {
            entry.height = s.height;
            entry.perfects = s.perfects;
            entry.prestige = s.prestige;
            entry.ts = now();
        }
    }
    app.flush();
    (StatusCode::OK, Json(json!({"ok": true})))
}

async fn lb_top(State(app): State<Shared>) -> impl IntoResponse {
    let mut entries: Vec<LbEntry> = app
        .store
        .read()
        .ok()
        .and_then(|s| s.leaderboards.get(&week_key()).cloned())
        .unwrap_or_default()
        .into_values()
        .collect();
    entries.sort_by(|a, b| b.height.cmp(&a.height).then(a.ts.cmp(&b.ts)));
    entries.truncate(50);
    Json(json!({ "week": week_key(), "entries": entries }))
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
        let board = store.ghosts.entry(g.seed.to_string()).or_default();
        let better = board.get(&uid).map_or(true, |e| g.height > e.height);
        if better {
            board.insert(
                uid.clone(),
                GhostEntry {
                    name: star_name(&uid),
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
async fn ghost_top(
    State(app): State<Shared>,
    Query(q): Query<SeedQuery>,
) -> impl IntoResponse {
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

/* ---------------- main ---------------- */

#[tokio::main]
async fn main() {
    let app = Arc::new(App::load(PathBuf::from("data/store.json")));

    let router = Router::new()
        .route("/health", get(health))
        .route("/api/config", get(config))
        .route("/api/auth/anonymous", post(auth_anonymous))
        .route("/api/save", put(save_put).get(save_get))
        .route("/api/leaderboard/submit", post(lb_submit))
        .route("/api/leaderboard/top", get(lb_top))
        .route("/api/ghosts", get(ghost_top))
        .route("/api/ghosts/submit", post(ghost_submit))
        .layer(CorsLayer::permissive()) // web client runs from file:// or any origin
        .with_state(app);

    let addr = std::env::var("BIND").unwrap_or_else(|_| "0.0.0.0:8080".into());
    println!("ECHO ORBIT server listening on http://{addr}");
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("bind failed");
    axum::serve(listener, router).await.expect("server failed");
}
