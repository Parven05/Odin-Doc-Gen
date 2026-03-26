package doc

import "core:strings"

write_html_header :: proc(sb: ^strings.Builder) {
	strings.write_string(
		sb,
		`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Odin Doc</title>
<style>
:root {
    --bg:       #1a1a1a;
    --bg2:      #1e1e1e;
    --card:     #252525;
    --border:   #2e2e2e;
    --border2:  #383838;
    --text:     #d4d4d4;
    --text-dim: #777;
    --text-faint:#444;
    --accent:   #4e8fce;
    --sb-bg:    #161616;
    --sb-border:#2a2a2a;
    --sb-text:  #999;
    --sb-hover: #222;

    --kw:   #569cd6;
    --ident:#d4d4d4;
    --ty:   #4ec9b0;
    --num:  #b5cea8;
    --str:  #ce9178;
    --cm:   #6a9955;
    --br:   #ffd700;
    --op:   #d4d4d4;
    --attr: #c586c0;

    --badge-proc:   #1a3a1a;
    --badge-proc-fg:#4ec94e;
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%; }

body {
    background: var(--bg);
    color: var(--text);
    font-family: 'Segoe UI', system-ui, sans-serif;
    font-size: 14px;
    display: flex;
    overflow: hidden;
}

/* sidebar */
#sidebar {
    width: 220px;
    min-width: 180px;
    background: var(--sb-bg);
    border-right: 1px solid var(--sb-border);
    display: flex;
    flex-direction: column;
    overflow: hidden;
    flex-shrink: 0;
}
#sidebar.hidden { width: 0; min-width: 0; opacity: 0; pointer-events: none; }

#sidebar-header {
    padding: 10px 12px;
    border-bottom: 1px solid var(--sb-border);
    font-weight: 700;
    font-size: 0.86rem;
    color: var(--text);
    display: flex;
    align-items: center;
    justify-content: space-between;
}

#sidebar-content { overflow-y: auto; flex: 1; padding: 8px 0; }

.toc-link {
    display: block;
    padding: 4px 12px 4px 16px;
    font-family: monospace;
    font-size: 0.86rem;
    color: var(--sb-text);
    text-decoration: none;
    border-left: 2px solid var(--badge-proc-fg);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    transition: background 0.1s, color 0.1s;
}
.toc-link:hover  { background: var(--sb-hover); color: var(--text); }
.toc-link.active { color: var(--text); font-weight: 600; background: var(--sb-hover); }

/* main */
#main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }

header {
    padding: 12px 20px;
    border-bottom: 1px solid var(--border);
    background: var(--bg2);
    display: flex;
    align-items: center;
    gap: 10px;
    flex-shrink: 0;
}

header h1 { font-size: 1rem; font-weight: 700; }

#sidebar-toggle {
    background: none; border: none; color: var(--text-dim);
    cursor: pointer; font-size: 1.1rem; padding: 2px 6px;
}
#sidebar-toggle:hover { color: var(--text); }

#toolbar {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 20px;
    border-bottom: 1px solid var(--border);
    background: var(--bg2);
    flex-shrink: 0;
}

#search {
    flex: 1;
    background: var(--bg);
    border: 1px solid var(--border2);
    border-radius: 3px;
    padding: 5px 10px;
    color: var(--text);
    outline: none;
    font-family: monospace;
    font-size: 13px;
    transition: border-color 0.15s;
}
#search:focus { border-color: var(--accent); }
#search::placeholder { color: var(--text-faint); }

#api-root {
    overflow-y: auto;
    flex: 1;
    padding: 16px 20px 40px;
}

/* details cards */
details {
    border: 1px solid var(--border);
    border-top: none;
    background: var(--card);
}
details:first-child { border-top: 1px solid var(--border); }

summary {
    padding: 7px 12px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 8px;
    list-style: none;
    font-family: monospace;
    font-size: 0.93rem;
    user-select: none;
    transition: background 0.1s;
}
summary::-webkit-details-marker { display: none; }
summary:hover { background: #2a2a2a; }

.item-name { font-weight: 600; color: var(--text); }

.badge {
    margin-left: auto;
    font-size: 0.71rem;
    font-family: monospace;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 3px;
    background: var(--badge-proc);
    color: var(--badge-proc-fg);
}

/* meta bar */
.meta-bar {
    padding: 5px 14px;
    border-top: 1px solid var(--border);
    background: var(--bg);
    font-family: monospace;
    font-size: 0.82rem;
    color: var(--text-dim);
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    align-items: center;
}

.meta-tag {
    background: #2a2a2a;
    border: 1px solid var(--border2);
    border-radius: 3px;
    padding: 1px 6px;
    font-size: 0.79rem;
}

.meta-tag .label { color: var(--text-faint); margin-right: 3px; }
.meta-tag .val   { color: var(--text); }
.meta-tag .type  { color: var(--ty); }
.meta-tag .num   { color: var(--num); }
.meta-tag .attr  { color: var(--attr); }

/* code block */
.code-wrap {
    border-top: 1px solid var(--border);
    background: #1e1e1e;
}

.code-header {
    display: flex;
    justify-content: flex-end;
    padding: 3px 10px;
    background: #252525;
    border-bottom: 1px solid var(--border);
}

.copy-btn {
    background: none;
    border: none;
    color: var(--text-dim);
    cursor: pointer;
    font-size: 0.79rem;
    padding: 1px 6px;
    border-radius: 3px;
    transition: background 0.1s, color 0.1s;
}
.copy-btn:hover  { background: #333; color: var(--text); }
.copy-btn.copied { color: var(--ty); }

pre {
    margin: 0;
    padding: 12px 16px;
    overflow-x: auto;
    tab-size: 4;
}

code {
    font-family: Consolas, 'Courier New', monospace;
    font-size: 13px;
    line-height: 1.65;
    color: var(--ident);
    white-space: pre;
}

/* highlight classes */
.kw  { color: var(--kw);   font-weight: bold; }
.ty  { color: var(--ty);   }
.num { color: var(--num);  }
.str { color: var(--str);  }
.cm  { color: var(--cm);   font-style: italic; }
.br  { color: var(--br);   }
.op  { color: var(--op);   }
.at  { color: var(--attr); }

@keyframes flash {
    0%   { outline: 2px solid var(--accent); }
    100% { outline: 2px solid transparent; }
}
details.flash { animation: flash 0.8s ease-out forwards; }

#no-results {
    display: none;
    text-align: center;
    padding: 4rem;
    color: var(--text-faint);
    font-size: 0.93rem;
}
</style>
</head>
<body>

<aside id="sidebar">
    <div id="sidebar-header">
        <span>Odin Doc</span>
        <button id="sidebar-toggle" onclick="toggleSidebar()" title="Toggle sidebar">&#9776;</button>
    </div>
    <div id="sidebar-content"></div>
</aside>

<main id="main">
    <header>
        <button id="sidebar-toggle" onclick="toggleSidebar()" title="Toggle sidebar">&#9776;</button>
        <h1>Odin Doc</h1>
    </header>
    <div id="toolbar">
        <input type="text" id="search" placeholder="Filter by name..." autocomplete="off" spellcheck="false">
    </div>
    <div id="api-root">
`,
	)
}

write_html_footer :: proc(sb: ^strings.Builder) {
	strings.write_string(
		sb,
		`
    <div id="no-results">No symbols match</div>
    </div>
</main>

<script>
// sidebar links
var allDetails = Array.from(document.querySelectorAll("details"));
var sidebar    = document.getElementById("sidebar-content");

allDetails.forEach(function(d) {
    var name = d.querySelector(".item-name");
    if (!name) return;
    var a = document.createElement("a");
    a.className   = "toc-link";
    a.href        = "#" + d.id;
    a.textContent = name.textContent;
    a.onclick = function(e) {
        e.preventDefault();
        navigateTo(d.id);
    };
    sidebar.appendChild(a);
});

function navigateTo(id) {
    var el = document.getElementById(id);
    if (!el) return;
    el.open = true;
    el.scrollIntoView({ behavior: "smooth", block: "start" });
    el.classList.add("flash");
    setTimeout(function() { el.classList.remove("flash"); }, 800);
    document.querySelectorAll(".toc-link").forEach(function(a) {
        a.classList.toggle("active", a.href.endsWith("#" + id));
    });
    history.replaceState(null, "", "#" + id);
}

// toggle sidebar
function toggleSidebar() {
    document.getElementById("sidebar").classList.toggle("hidden");
}

// search filter
document.getElementById("search").addEventListener("input", function() {
    var term = this.value.toLowerCase();
    var any  = false;
    allDetails.forEach(function(d) {
        var name = d.querySelector(".item-name");
        var vis  = !name || name.textContent.toLowerCase().includes(term);
        d.style.display = vis ? "" : "none";
        if (vis) any = true;
    });
    document.querySelectorAll(".toc-link").forEach(function(a) {
        a.style.display = a.textContent.toLowerCase().includes(term) ? "" : "none";
    });
    document.getElementById("no-results").style.display = any ? "none" : "block";
});

// copy button
function copyCode(btn) {
    var code = btn.closest("details").querySelector("code");
    if (!code) return;
    navigator.clipboard.writeText(code.textContent).then(function() {
        var orig = btn.textContent;
        btn.textContent = "✓";
        btn.classList.add("copied");
        setTimeout(function() { btn.textContent = orig; btn.classList.remove("copied"); }, 1500);
    });
}

// anchor on load
(function() {
    var hash = window.location.hash.slice(1);
    if (!hash) return;
    var el = document.getElementById(hash);
    if (!el) return;
    el.open = true;
    setTimeout(function() { el.scrollIntoView({ behavior: "smooth", block: "start" }); }, 80);
}());
</script>
</body>
</html>
`,
	)
}
