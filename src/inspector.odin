package doc

import "core:fmt"
import odin_ast "core:odin/ast"
import "core:odin/parser"
import "core:odin/tokenizer"
import "core:os"
import "core:strings"

main :: proc() {
	pkg, ok := parser.collect_package("test")
	if !ok {
		fmt.println("Error collecting package")
		return
	}
	ok = parser.parse_package(pkg)
	if !ok {
		fmt.println("Error parsing package")
		return
	}

	sb: strings.Builder
	strings.builder_init(&sb)

	// html builder
	strings.write_string(
		&sb,
		`<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Odin Doc</title>
    <style>
        body { background: #1e1e1e; color: #d4d4d4; font-family: monospace; padding: 2rem; }
        h2   { color: #9cdcfe; border-bottom: 1px solid #333; padding-bottom: 0.3rem; }
        .block      { margin-bottom: 2rem; }
        .meta { color: #888; font-size: 0.85rem; margin-bottom: 0.5rem; display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; }
        .meta span { background: #2d2d2d; padding: 0.2rem 0.5rem; border-radius: 4px; }
        pre         { background: #252526; padding: 1rem; border-radius: 6px; overflow-x: auto; }

        .kw      { color: #569cd6; font-weight: bold; }
        .ident   { color: #d4d4d4; }
        .type    { color: #4ec9b0; }
        .number  { color: #b5cea8; }
        .string  { color: #ce9178; }
        .comment { color: #6a9955; font-style: italic; }
        .brace   { color: #ffd700; }
        .op      { color: #d4d4d4; }
        .attr    { color: #c586c0; }
    </style>
</head>
<body>
`,
	)

	for _, file in pkg.files {
		walk_ast(file, &sb)
	}

	strings.write_string(&sb, "</body>\n</html>")
	err := os.write_entire_file("output.html", sb.buf[:])
	if err != nil {
		fmt.println("Error writing file:", err)
		return
	}
	fmt.println("output.html generated")
}

walk_ast :: proc(file: ^odin_ast.File, sb: ^strings.Builder) {
	Ctx :: struct {
		file: ^odin_ast.File,
		sb:   ^strings.Builder,
	}
	ctx := new(Ctx)
	ctx.file = file
	ctx.sb = sb

	visitor := odin_ast.Visitor {
		data = rawptr(ctx),
		visit = proc(v: ^odin_ast.Visitor, node: ^odin_ast.Node) -> ^odin_ast.Visitor {
			ctx := (^Ctx)(v.data)
			process_node(node, ctx.file.src, ctx.sb)
			return v
		},
	}
	odin_ast.walk(&visitor, file)
}


process_node :: proc(node: ^odin_ast.Node, src: string, sb: ^strings.Builder) {
	if node == nil do return
	#partial switch derived in node.derived {
	case ^odin_ast.Value_Decl:
		for name_expr, i in derived.names {
			ident, ok := name_expr.derived_expr.(^odin_ast.Ident)
			if !ok do continue
			name := ident.name
			if i >= len(derived.values) do continue
			value := derived.values[i]
			proc_lit, is_proc := value.derived_expr.(^odin_ast.Proc_Lit)
			if !is_proc do continue
			if proc_lit.type == nil do continue

			// proc heading
			fmt.sbprintf(sb, "<div class='block'>\n")
			fmt.sbprintf(sb, "<h2>%s</h2>\n", name)
			fmt.sbprintf(sb, "<div class='meta'>\n")

			// calling convention
			if proc_lit.type.calling_convention != "" {
				fmt.sbprintf(
					sb,
					"  <span>conv: <b>%v</b></span>\n",
					proc_lit.type.calling_convention,
				)
			}
			if proc_lit.type.generic {
				fmt.sbprintf(sb, "  <span class='attr'>generic</span>\n")
			}
			if proc_lit.type.diverging {
				fmt.sbprintf(sb, "  <span style='color:#f44'>diverging</span>\n")
			}

			// attributes
			for attr in derived.attributes {
				for element in attr.elems {
					attr_ident, ok := element.derived_expr.(^odin_ast.Ident)
					if ok {
						fmt.sbprintf(sb, "  <span class='attr'>@(%s)</span>\n", attr_ident.name)
					}
				}
			}

			// params
			if proc_lit.type.params != nil {
				for field in proc_lit.type.params.list {
					for param_name in field.names {
						pident, ok := param_name.derived_expr.(^odin_ast.Ident)
						if ok {
							if field.type != nil {
								ptype, tok := field.type.derived_expr.(^odin_ast.Ident)
								if tok {
									if field.default_value != nil {
										def, dok := field.default_value.derived_expr.(^odin_ast.Basic_Lit)
										if dok {
											fmt.sbprintf(
												sb,
												" <span>param: <b>%s</b>: <span class='type'>%s</span> = <span class='number'>%s</span></span>",
												pident.name,
												ptype.name,
												def.tok.text,
											)
										} else {
											fmt.sbprintf(
												sb,
												" <span>param: <b>%s</b>: <span class='type'>%s</span>",
												pident.name,
												ptype.name,
											)
										}
									}

								}
							}
						}
					}

				}
			}

			// results
			if proc_lit.type.results != nil {
				for field in proc_lit.type.results.list {
					if len(field.names) == 0 {
						if field.type != nil {
							rtype, ok := field.type.derived_expr.(^odin_ast.Ident)
							if ok {
								fmt.sbprintf(
									sb,
									"  <span>returns: <span class='type'>%s</span></span>\n",
									rtype.name,
								)
							}
						}
					} else {
						for result_name in field.names {
							rident, ok := result_name.derived_expr.(^odin_ast.Ident)
							if ok {
								if field.type != nil {
									rtype, tok := field.type.derived_expr.(^odin_ast.Ident)
									if tok {
										fmt.sbprintf(
											sb,
											"  <span>returns: <b>%s</b>: <span class='type'>%s</span></span>\n",
											rident.name,
											rtype.name,
										)
									}
								}
							}
						}
					}
				}
			}

			// inlining
			switch proc_lit.inlining {
			case .Inline:
				fmt.sbprintf(sb, "  <span class='attr'>force_inline</span>\n")
			case .No_Inline:
				fmt.sbprintf(sb, "  <span style='color:#f44'>force_no_inline</span>\n")
			case .None:
			}

			if proc_lit.where_clauses != nil {
				fmt.sbprintf(sb, "  <span class='attr'>has where clauses</span>\n")
			}

			fmt.sbprintf(sb, "</div>\n")

			// colored source block
			if proc_lit.body != nil {
				start := derived.pos.offset
				end := proc_lit.body.end.offset
				if start < len(src) && end <= len(src) {
					fmt.sbprintf(sb, "<pre>")
					highlight_source(src[start:end], sb)
					fmt.sbprintf(sb, "</pre>\n")
				}
			}

			fmt.sbprintf(sb, "</div>\n")
		}
	}
}

highlight_source :: proc(src: string, sb: ^strings.Builder) {
	t: tokenizer.Tokenizer
	tokenizer.init(&t, src, "")
	prev_end := 0

	for {
		token := tokenizer.scan(&t)
		if token.kind == .EOF do break

		// print gap
		gap_start := prev_end
		gap_end := token.pos.offset
		if gap_start < gap_end && gap_end <= len(src) {
			write_escaped(sb, src[gap_start:gap_end])
		}
		prev_end = token.pos.offset + len(token.text)

		// syntax highlight
		#partial switch token.kind {
		case .Proc,
		     .Return,
		     .If,
		     .Else,
		     .For,
		     .In,
		     .Do,
		     .Switch,
		     .Case,
		     .Break,
		     .Continue,
		     .Defer,
		     .When,
		     .Import,
		     .Package,
		     .Foreign,
		     .Using:
			fmt.sbprintf(sb, "<span class='kw'>%s</span>", token.text)
		case:
			write_escaped(sb, token.text)
		}
	}
}

// escape html special chars
write_escaped :: proc(sb: ^strings.Builder, s: string) {
	for ch in s {
		switch ch {
		case '<':
			strings.write_string(sb, "&lt;")
		case '>':
			strings.write_string(sb, "&gt;")
		case '&':
			strings.write_string(sb, "&amp;")
		case '"':
			strings.write_string(sb, "&quot;")
		case:
			strings.write_rune(sb, ch)
		}
	}
}
