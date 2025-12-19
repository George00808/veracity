const app = document.getElementById("app");
const navItems = Array.from(document.querySelectorAll(".nav-item"));
const tabs = Array.from(document.querySelectorAll(".tab"));
const pageTitle = document.getElementById("pageTitle");
const titleMap = {
  dashboard: "Dashboard",
  players: "Players",
  empty: " "
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
}

navItems.forEach(btn => {
  btn.addEventListener("click", () => setTab(btn.dataset.tab));
});

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
});

setVisible(false);
setTab(defaultTab);
