# Odin Doc-Gen

A simple documentation generator for [Odin](https://odin-lang.org/) projects. Point it at your `src/` folder, run one command, get a single self-contained `index.html` with a searchable, filterable code reference.

> Odin already has a great built-in doc tool. This isn't a replacement, while working on my own project I wanted to build my own doc generator, so I made this. I plan to keep improving it, and if you need a quick doc site for your Odin project, feel free to use it and share it around.

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

Example :

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

### project

| Key | Description |
|---|---|
| `name` | Main title shown in the header |
| `subtitle` | Shown next to the title, dimmer |
| `tagline` | Small line below the title |
| `github_url` | Links the GitHub icon in the header |
| `page_title` | Browser tab title |

### sort_order

Controls the order declaration types appear within each file section. Lower number appears first. Default order is STRUCT → ENUM → PROC → UNION.

### file_order

Controls the order files appear in the sidebar and main content. List filenames only, not full paths. Files not listed are sorted alphabetically after the ones you specify. Omit the key entirely to sort everything alphabetically.

### theme_css

Swap this filename to change the colour theme. See the Themes section for all available options.

## What Gets Documented

Only top-level declarations are picked up:

| Declaration | Example |
|---|---|
| `proc` | `init_window :: proc(...) -> bool` |
| `struct` | `Shader :: struct { ... }` |
| `enum` | `DrawMode :: enum { ... }` |
| `union` | `Result :: union { ... }` |

Everything else (variables, constants, package declarations) is ignored.

## Doc Comments

Place a `//` or `/* */` comment directly above a declaration with no blank line between them and it becomes a readable description shown in the docs.

```odin
// Initialises the GLFW window and creates an OpenGL context.
// Returns false if GLFW or GLAD failed to load.
init_window :: proc(window_width: i32, window_height: i32, window_title: cstring) -> bool {
```

- Both `//` and `/* */` styles work
- No blank line allowed between the comment and the declaration
- Comments inside the function body are ignored
- The comment appears as description text and is removed from the code block

## Attributes

Odin attributes like `@(private="file")` placed above a declaration are detected and shown as a badge next to the declaration name.

```odin
@(private="file")
fb_size_callback :: proc(...) {
```

## Themes

Change `theme_css` in `config.json` to switch themes:

- `theme_monokai.css`
- `theme_one_dark_pro.css`
- `theme_github_dark.css`
- `theme_gruvbox.css`
- `theme_catppuccin.css`
- `theme_tokyo_night.css`
- `theme_dracula.css`
- `theme_solarized_dark.css`
- `theme_palenight.css`

To make your own theme, copy any `theme_*.css` and update the CSS variables inside.

## Features

| Feature | Description |
|---|---|
| Search | Filters by name in real time, sidebar updates in sync |
| Type filters | STRUCT / ENUM / PROC / UNION buttons in the toolbar |
| Params bar | Param names and types are colour-coded separately |
| Doc comments | `//` or `/* */` directly above a declaration becomes readable description text |
| Used-by links | Shows which other symbols reference a given symbol |
| Sidebar TOC | Collapsible per-file groups with type icons, drag the edge to resize |
| Syntax highlighting | Odin-aware, rebuilt from `odin_syntax.json` each run |
| Copy button | One-click copy on every code block |
| Expand / Collapse all | Toolbar buttons to open or close everything at once |
| Responsive | Sidebar hides on narrow screens |

## Extending the Syntax

`odin_syntax.json` controls what gets highlighted. Add entries to any of these arrays and re-run `gen.py` — no Python changes needed:

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

[Silicon Docs](https://parven05.github.io/Silicon/)

If you use this tool, feel free to open a PR or issue to add your site here.
