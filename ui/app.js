const app = document.getElementById("app");
const navItems = Array.from(document.querySelectorAll(".nav-item"));
const tabs = Array.from(document.querySelectorAll(".tab"));
const pageTitle = document.getElementById("pageTitle");
const playersListEl = document.getElementById("playersList");
const playerDetailEl = document.getElementById("playerDetail");

let players = [];
let selectedId = null;

const titleMap = {
  dashboard: "Dashboard",
  admin: "Admin",
  players: "Players",
  config: "Config",
  logs: "Logs",
  settings: "Settings"
};
const defaultTab = "dashboard";

function nuiPost(name, payload = {}) {
  return fetch(`https://${GetParentResourceName()}/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(payload)
  });
}

function setVisible(visible) {
  app.classList.toggle("hidden", !visible);
  if (visible && getActiveTab() === "players") {
    requestPlayers();
  }
}

function getActiveTab() {
  const active = navItems.find(btn => btn.classList.contains("active"));
  return active ? active.dataset.tab : defaultTab;
}

function setTab(tabName) {
  navItems.forEach(btn => {
    const isActive = btn.dataset.tab === tabName;
    btn.classList.toggle("active", isActive);
    btn.setAttribute("aria-current", isActive ? "page" : "false");
  });

  tabs.forEach(panel => {
    const isActive = panel.dataset.tabpanel === tabName;
    panel.classList.toggle("hidden", !isActive);
  });

  pageTitle.textContent = titleMap[tabName] ?? "Veracity";

  if (tabName === "players") {
    requestPlayers();
  }
}

function renderPlayers() {
  if (!playersListEl) return;
  playersListEl.innerHTML = "";

  if (!players.length) {
    playersListEl.innerHTML = '<div class="list-empty">No players online</div>';
    playerDetailEl.innerHTML = '<div class="empty"><div class="empty-title">Select a player</div><div class="empty-sub">Click a row to inspect identifiers</div></div>';
    selectedId = null;
    return;
  }

  players.forEach(p => {
    const row = document.createElement("button");
    row.className = "player-row" + (p.id === selectedId ? " active" : "");
    row.dataset.playerId = p.id;
    const distance = typeof p.distance === "number" ? `${Math.floor(p.distance)} m` : "--";
    row.innerHTML = `
      <div class="player-row-main">
        <div class="player-name">${p.name || "Unknown"}</div>
        <div class="player-sub">ID ${p.id}</div>
      </div>
      <div class="player-distance">${distance}</div>
    `;
    playersListEl.appendChild(row);
  });

  if (selectedId === null && players.length) {
    selectedId = players[0].id;
  }

  renderDetail();
}

function renderDetail() {
  if (!playerDetailEl) return;
  const target = players.find(p => p.id === selectedId);
  if (!target) {
    playerDetailEl.innerHTML = '<div class="empty"><div class="empty-title">Select a player</div><div class="empty-sub">Click a row to inspect identifiers</div></div>';
    return;
  }

  const coords = target.coords || {};
  const distance = typeof target.distance === "number" ? `${Math.floor(target.distance)} m away` : "Distance unavailable";
  const identifiers = (target.identifiers || []).map(id => `<li>${id}</li>`).join("") || "<li>No identifiers</li>";

  playerDetailEl.innerHTML = `
    <div class="detail-head">
      <div>
        <div class="detail-name">${target.name || "Unknown"}</div>
        <div class="detail-sub">ID ${target.id} ? ${distance}</div>
      </div>
    </div>
    <div class="detail-section">
      <div class="detail-label">Position</div>
      <div class="detail-value">x: ${coords.x !== undefined ? coords.x.toFixed(2) : "--"} ? y: ${coords.y !== undefined ? coords.y.toFixed(2) : "--"} ? z: ${coords.z !== undefined ? coords.z.toFixed(2) : "--"}</div>
    </div>
    <div class="detail-section">
      <div class="detail-label">Licenses / HWIDs</div>
      <ul class="identifier-list">${identifiers}</ul>
    </div>
  `;
}

function requestPlayers() {
  nuiPost("requestPlayers");
}

navItems.forEach(btn => {
  btn.addEventListener("click", () => setTab(btn.dataset.tab));
});

if (playersListEl) {
  playersListEl.addEventListener("click", (e) => {
    const row = e.target.closest(".player-row");
    if (!row) return;
    selectedId = Number(row.dataset.playerId);
    renderPlayers();
  });
}

window.addEventListener("keydown", (e) => {
  if (e.key === "Backspace") {
    e.preventDefault();
    nuiPost("close");
  }
});

window.addEventListener("message", (event) => {
  const data = event.data || {};
  if (data.type === "setVisible") {
    setVisible(!!data.visible);
    if (data.visible) setTab(defaultTab);
  }
  if (data.type === "players") {
    players = Array.isArray(data.players) ? data.players : [];
    // ensure lowest id first client-side too
    players.sort((a, b) => (a.id || 0) - (b.id || 0));
    renderPlayers();
  }
});

setVisible(false);
setTab(defaultTab);
