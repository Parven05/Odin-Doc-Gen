# Odin Simple Doc-Gen

A simple documentation generator for [Odin](https://odin-lang.org/) source code. Point it at your `src/` folder, run one command, get a single self-contained `index.html` with a searchable, filterable API reference.

---

## Requirements

- Python 3.10+
- No third-party packages needed

---

## Quick Start

```
your-project/
├── src/                  ← your Odin source files
└── docs/
    ├── gen.py
    ├── config.json
    ├── odin_syntax.json
    ├── template.html
    ├── style.css
    └── theme_monokai.css
```

```bash
cd docs
python gen.py
# Done: 42 items -> index.html
```

Open `index.html` in your browser. That's it.

---

## Configuration (`config.json`)

Everything you need to customise lives here.

```json
{
    "project": {
        "name":        "Silicon",
        "subtitle":    "an OpenGL Renderer",
        "tagline":     "Library Overview",
        "github_url":  "https://github.com/you/your-project",
        "page_title":  "Silicon Documentation"
    },
    "paths": {
        "source_dir":  "../src",
        "output_html": "index.html",
        "template":    "template.html",
        "syntax":      "odin_syntax.json",
        "style_css":   "style.css",
        "theme_css":   "theme_monokai.css"
    },
    "sort_order": {
        "STRUCT": 1,
        "ENUM":   2,
        "PROC":   3,
        "UNION":  4
    },
    "file_order": [
        "window.odin",
        "renderer.odin",
        "shader.odin"
    ]
}
```

### `project`
Basic info shown in the page header and browser tab.

| Key | What it does |
|---|---|
| `name` | Main title in the header |
| `subtitle` | Shown next to the title, dimmer |
| `tagline` | Small line below the title |
| `github_url` | Links the GitHub icon in the header |
| `page_title` | Browser tab title |

### `paths`
| Key | What it does |
|---|---|
| `source_dir` | Path to your Odin source, relative to `gen.py` |
| `output_html` | Where to write the output file |
| `theme_css` | Which theme file to use — swap this to change the colour theme |

### `sort_order`
Controls the order of declaration types within each file section. Lower number = appears first.

### `file_order`
Controls the order files appear in the sidebar and main content. List filenames (not paths) in the order you want them. Files not listed are sorted alphabetically after the listed ones. Omit the key entirely to sort everything alphabetically.

```json
"file_order": ["window.odin", "renderer.odin"]
```

---

## What Gets Documented

The generator picks up four kinds of declarations:

| Kind | Example |
|---|---|
| `proc` | `init_window :: proc(...) -> bool` |
| `struct` | `Shader :: struct { ... }` |
| `enum` | `DrawMode :: enum { ... }` |
| `union` | `Result :: union { ... }` |

Everything else (variables, constants, package declarations) is ignored.

---

## Doc Comments

Place a `//` or `/* */` comment **directly above** a declaration with **no blank line between them** and it becomes a readable description shown above the code block in the docs.

```odin
// Initialises the GLFW window and creates an OpenGL context.
// Returns false if GLFW or GLAD failed to load.
init_window :: proc(window_width: i32, window_height: i32, window_title: cstring) -> bool {
```

This produces a description bar in the docs reading:
> *Initialises the GLFW window and creates an OpenGL context. Returns false if GLFW or GLAD failed to load.*

**Rules:**
- Must be directly above the declaration — no blank line gap
- Both `//` and `/* */` styles work
- Comments inside the function body are ignored
- Doc comments are not repeated inside the code block — they appear as text only

---

## Attributes

Odin attributes like `@(private="file")` placed above a declaration are detected and shown as a badge next to the declaration name in the summary row.

```odin
@(private="file")
fb_size_callback :: proc(window: glfw.WindowHandle, ...) {
```

---

## Themes

Six themes are included. To switch, update `theme_css` in `config.json`:

| File | Style |
|---|---|
| `theme_monokai.css` | Classic Monokai — warm, high contrast |
| `theme_one_dark_pro.css` | One Dark Pro — deep navy, purple keywords |
| `theme_github_dark.css` | GitHub Dark — familiar GitHub palette |
| `theme_gruvbox.css` | Gruvbox — earthy, retro warm tones |
| `theme_catppuccin.css` | Catppuccin Mocha — soft pastel |
| `theme_nord.css` | Nord — arctic cool blues |
| `theme_tokyo_night.css` | Tokyo Night — neon city, deep navy |
| `theme_dracula.css` | Dracula — pink, green, purple classic |
| `theme_solarized_dark.css` | Solarized Dark — precision balanced |
| `theme_palenight.css` | Palenight — Material-style slate |

To create your own theme, copy any `theme_*.css` file and update the CSS variables. The variable names are documented inside each file.

---

## Features at a Glance

**Search** — type in the toolbar to filter by name in real time. The sidebar updates in sync.

**Type filters** — click STRUCT / ENUM / PROC / UNION in the toolbar to show only that kind.

**Params bar** — proc declarations show a params and returns bar with names and types colour-coded separately.

**Used-by links** — if a symbol is referenced inside another symbol's body, a "used by" bar appears with clickable links back to the callers.

**Sidebar TOC** — collapsible per-file groups with colour-coded type icons. Drag the edge to resize.

**Syntax highlighting** — Odin-aware, built from `odin_syntax.json` at gen time. Add new keywords or built-ins there without touching `gen.py`.

**Copy button** — every code block has a one-click copy button.

**Expand all / Collapse all** — toolbar buttons to open or close all declarations at once.

**Responsive** — sidebar hides on narrow screens.

---

## Extending the Syntax

`odin_syntax.json` controls what gets highlighted. Add to any of these arrays to extend the highlighter:

```json
"keywords":      [...],
"builtin_types": [...],
"builtin_procs": [...],
"literals":      [...]
```

No code changes needed — `gen.py` reads this file and rebuilds the JS highlighter every time you run it.

---

## Regenerating

Just run `gen.py` again after any source change:

```bash
python gen.py
```

The output is always a single self-contained `index.html` — no server needed, open it directly in any browser.
