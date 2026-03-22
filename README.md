# Odin Doc-Gen

A simple documentation generator for [Odin](https://odin-lang.org/) source code. Point it at your `src/` folder, run one command, get a single self-contained `index.html` with a searchable, filterable API reference.

## Requirements

- Python 3.10+
- No third-party packages needed

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

Open `index.html` in your browser. No server needed.

## Configuration (`config.json`)

You must create this file yourself — `gen.py` will not run without it. Place it in the same folder as `gen.py`.

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

**`project`**
- `name` — main title in the header
- `subtitle` — shown next to the title, dimmer
- `tagline` — small line below the title
- `github_url` — links the GitHub icon in the header
- `page_title` — browser tab title

**`sort_order`** — order of declaration types within each file. Lower number = appears first.

**`file_order`** — order files appear in the docs. List filenames (not paths). Files not listed are sorted alphabetically after. Omit the key entirely to sort everything alphabetically.

**`theme_css`** — swap this filename to change the colour theme.

## What Gets Documented

Only top-level declarations are picked up:

- `proc` — `init_window :: proc(...) -> bool`
- `struct` — `Shader :: struct { ... }`
- `enum` — `DrawMode :: enum { ... }`
- `union` — `Result :: union { ... }`

Everything else (variables, constants, package declarations) is ignored.

## Doc Comments

Place a `//` or `/* */` comment **directly above** a declaration with **no blank line between them** and it becomes a readable description in the docs.

```odin
// Initialises the GLFW window and creates an OpenGL context.
// Returns false if GLFW or GLAD failed to load.
init_window :: proc(window_width: i32, window_height: i32, window_title: cstring) -> bool {
```

- Both `//` and `/* */` styles work
- No blank line allowed between the comment and the declaration
- Comments inside the function body are ignored
- The comment is shown as description text and removed from the code block

## Attributes

Odin attributes like `@(private="file")` above a declaration are shown as a badge next to the name.

```odin
@(private="file")
fb_size_callback :: proc(...) {
```

## Themes

Change `theme_css` in `config.json` to switch themes:

| File | Style |
|---|---|
| `theme_monokai.css` | Classic Monokai, warm high contrast |
| `theme_one_dark_pro.css` | One Dark Pro, deep navy purple keywords |
| `theme_github_dark.css` | GitHub Dark, familiar GitHub palette |
| `theme_gruvbox.css` | Gruvbox, earthy retro warm tones |
| `theme_catppuccin.css` | Catppuccin Mocha, soft pastel |
| `theme_tokyo_night.css` | Tokyo Night, neon city deep navy |
| `theme_dracula.css` | Dracula, pink green purple classic |
| `theme_solarized_dark.css` | Solarized Dark, precision balanced |
| `theme_palenight.css` | Palenight, Material-style slate |

To make your own theme, copy any `theme_*.css` and update the CSS variables inside.

## Features

- **Search** — filters by name in real time, sidebar updates in sync
- **Type filters** — STRUCT / ENUM / PROC / UNION buttons in the toolbar
- **Params bar** — param names and types are colour-coded separately
- **Used-by links** — shows which other symbols reference a given symbol
- **Sidebar TOC** — collapsible per-file groups with type icons, drag edge to resize
- **Syntax highlighting** — Odin-aware, rebuilt from `odin_syntax.json` each run
- **Copy button** — one-click copy on every code block
- **Expand / Collapse all** — toolbar buttons to open or close everything at once
- **Responsive** — sidebar hides on narrow screens

## Extending the Syntax

Add to any of these arrays in `odin_syntax.json` — no Python changes needed:

```json
"keywords":      [...],
"builtin_types": [...],
"builtin_procs": [...],
"literals":      [...]
```

## Regenerating

```bash
python gen.py
```

Run this after any source change. Output is always a single `index.html`.

## Real Usage

Projects using odin-docgen in the wild:

| Docs |
|---|---|
| [silicon-docs](https://parven05.github.io/Silicon/) |

Using odin-docgen for your own Odin project? Feel free to open a PR or issue to add your generated site to this list.
