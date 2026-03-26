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
	write_html_header(&sb)

	for _, file in pkg.files {
		walk_ast(file, &sb)
	}

	write_html_footer(&sb)

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

			// details card
			fmt.sbprintf(sb, "<details id='%s'>\n", name)
			fmt.sbprintf(
				sb,
				"<summary><span class='item-name'>%s</span><span class='badge'>PROC</span></summary>\n",
				name,
			)

			// meta bar
			fmt.sbprintf(sb, "<div class='meta-bar'>\n")

			// calling convention
			if proc_lit.type.calling_convention != nil {
				fmt.sbprintf(
					sb,
					"<span class='meta-tag'><span class='label'>conv</span><span class='val'>%v</span></span>",
					proc_lit.type.calling_convention,
				)
			}
			if proc_lit.type.generic {
				fmt.sbprintf(sb, "<span class='meta-tag'><span class='attr'>generic</span></span>")
			}
			if proc_lit.type.diverging {
				fmt.sbprintf(
					sb,
					"<span class='meta-tag'><span class='attr'>diverging</span></span>",
				)
			}
			if proc_lit.body == nil {
				fmt.sbprintf(
					sb,
					"<span class='meta-tag'><span class='attr'>declaration only</span></span>",
				)
			}

			// attributes
			for attr in derived.attributes {
				for element in attr.elems {
					attr_ident, aok := element.derived_expr.(^odin_ast.Ident)
					if aok {
						fmt.sbprintf(
							sb,
							"<span class='meta-tag'><span class='attr'>@(%s)</span></span>",
							attr_ident.name,
						)
					}
				}
			}

			// inlining
			switch proc_lit.inlining {
			case .Inline:
				fmt.sbprintf(
					sb,
					"<span class='meta-tag'><span class='attr'>force_inline</span></span>",
				)
			case .No_Inline:
				fmt.sbprintf(
					sb,
					"<span class='meta-tag'><span class='attr'>force_no_inline</span></span>",
				)
			case .None:
			}

			// params
			if proc_lit.type.params != nil {
				for field in proc_lit.type.params.list {
					for param_name in field.names {
						pident, pok := param_name.derived_expr.(^odin_ast.Ident)
						if !pok do continue
						if field.type != nil {
							ptype, tok := field.type.derived_expr.(^odin_ast.Ident)
							if tok {
								if field.default_value != nil {
									def, dok := field.default_value.derived_expr.(^odin_ast.Basic_Lit)
									if dok {
										fmt.sbprintf(
											sb,
											"<span class='meta-tag'><span class='label'>param</span><span class='val'>%s</span><span class='label'>:</span><span class='type'>%s</span><span class='label'> =</span><span class='num'>%s</span></span>",
											pident.name,
											ptype.name,
											def.tok.text,
										)
									} else {
										fmt.sbprintf(
											sb,
											"<span class='meta-tag'><span class='label'>param</span><span class='val'>%s</span><span class='label'>:</span><span class='type'>%s</span></span>",
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

			// results
			if proc_lit.type.results != nil {
				for field in proc_lit.type.results.list {
					if len(field.names) == 0 {
						if field.type != nil {
							rtype, rok := field.type.derived_expr.(^odin_ast.Ident)
							if rok {
								fmt.sbprintf(
									sb,
									"<span class='meta-tag'><span class='label'>returns</span><span class='type'>%s</span></span>",
									rtype.name,
								)
							}
						}
					} else {
						for result_name in field.names {
							rident, rok := result_name.derived_expr.(^odin_ast.Ident)
							if !rok do continue
							if field.type != nil {
								rtype, tok := field.type.derived_expr.(^odin_ast.Ident)
								if tok {
									fmt.sbprintf(
										sb,
										"<span class='meta-tag'><span class='label'>returns</span><span class='val'>%s</span><span class='label'>:</span><span class='type'>%s</span></span>",
										rident.name,
										rtype.name,
									)
								}
							}
						}
					}
				}
			}

			fmt.sbprintf(sb, "</div>\n") // meta-bar

			// code block
			if proc_lit.body != nil {
				start := derived.pos.offset
				end := proc_lit.body.end.offset
				if start < len(src) && end <= len(src) {
					fmt.sbprintf(sb, "<div class='code-wrap'>")
					fmt.sbprintf(
						sb,
						"<div class='code-header'><button class='copy-btn' onclick='copyCode(this)'>copy</button></div>",
					)
					fmt.sbprintf(sb, "<pre><code class='language-odin'>")
					highlight_source(src[start:end], sb)
					fmt.sbprintf(sb, "</code></pre></div>\n")
				}
			}

			fmt.sbprintf(sb, "</details>\n")
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

		// write gap
		gap_start := prev_end
		gap_end := token.pos.offset
		if gap_start < gap_end && gap_end <= len(src) {
			write_escaped(sb, src[gap_start:gap_end])
		}
		prev_end = token.pos.offset + len(token.text)

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
		case .Integer, .Float:
			fmt.sbprintf(sb, "<span class='num'>%s</span>", token.text)
		case .String:
			fmt.sbprintf(sb, "<span class='str'>")
			write_escaped(sb, token.text)
			strings.write_string(sb, "</span>")
		case .Comment:
			fmt.sbprintf(sb, "<span class='cm'>")
			write_escaped(sb, token.text)
			strings.write_string(sb, "</span>")
		case .Open_Brace, .Close_Brace, .Open_Paren, .Close_Paren, .Open_Bracket, .Close_Bracket:
			fmt.sbprintf(sb, "<span class='br'>%s</span>", token.text)
		case .Colon,
		     .Arrow_Right,
		     .Add,
		     .Sub,
		     .Mul,
		     .Quo,
		     .Mod,
		     .And,
		     .Or,
		     .Xor,
		     .Not,
		     .Eq,
		     .Not_Eq,
		     .Lt,
		     .Gt,
		     .Lt_Eq,
		     .Gt_Eq:
			write_escaped(sb, token.text)
		case .Ident:
			fmt.sbprintf(sb, "<span class='ident'>%s</span>", token.text)
		case:
			write_escaped(sb, token.text)
		}
	}
}

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
