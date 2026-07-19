#+ feature dynamic-literals
package doc

import "core:fmt"
import odin_ast "core:odin/ast"
import "core:odin/parser"
import "core:odin/tokenizer"
import "core:os"
import "core:path/filepath"
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

	// Each file gets its own group, emitted in order: structs → enums → unions → procs
	for _, file in pkg.files {
		file_structs: [dynamic]Decl_Entry
		file_enums: [dynamic]Decl_Entry
		file_unions: [dynamic]Decl_Entry
		file_procs: [dynamic]Decl_Entry

		collect_buckets(file, &file_structs, &file_enums, &file_unions, &file_procs)

		total := len(file_structs) + len(file_enums) + len(file_unions) + len(file_procs)
		if total == 0 do continue

		// derive a clean display name from the file path, e.g. "src/windows.odin" → "windows"
		base := filepath.base(file.fullpath)
		display_name := strings.trim_suffix(base, ".odin")

		fmt.sbprintf(&sb, "<section class='file-group' data-file='%s'>\n", display_name)
		fmt.sbprintf(
			&sb,
			`<div class='file-header' onclick='toggleFileGroup(this)'>
  <span class='file-chevron'>&#9660;</span>
  <span class='file-icon'>&#128196;</span>
  <span class='file-name'>%s</span>
  <span class='file-counts'>`,
			display_name,
		)
		if len(file_structs) >
		   0 {fmt.sbprintf(&sb, "<span class='fc-struct'>%d struct</span>", len(file_structs))}
		if len(file_enums) >
		   0 {fmt.sbprintf(&sb, "<span class='fc-enum'>%d enum</span>", len(file_enums))}
		if len(file_unions) >
		   0 {fmt.sbprintf(&sb, "<span class='fc-union'>%d union</span>", len(file_unions))}
		if len(file_procs) >
		   0 {fmt.sbprintf(&sb, "<span class='fc-proc'>%d proc</span>", len(file_procs))}
		fmt.sbprintf(&sb, "</span></div>\n<div class='file-body'>\n")

		for &entry in file_structs {emit_struct(&entry, &sb)}
		for &entry in file_enums {emit_enum(&entry, &sb)}
		for &entry in file_unions {emit_union(&entry, &sb)}
		for &entry in file_procs {emit_proc(&entry, &sb)}

		fmt.sbprintf(&sb, "</div></section>\n")
	}

	write_html_footer(&sb)

	err := os.write_entire_file("output.html", sb.buf[:])
	if err != nil {
		fmt.println("Error writing file:", err)
		return
	}
	fmt.println("output.html generated")
}

Decl_Entry :: struct {
	name:       string,
	src:        string,
	value_decl: ^odin_ast.Value_Decl,
	value:      ^odin_ast.Expr,
}

collect_buckets :: proc(
	file: ^odin_ast.File,
	structs: ^[dynamic]Decl_Entry,
	enums: ^[dynamic]Decl_Entry,
	unions: ^[dynamic]Decl_Entry,
	procs: ^[dynamic]Decl_Entry,
) {
	for decl in file.decls {
		if decl == nil do continue
		value_decl, ok := decl.derived.(^odin_ast.Value_Decl)
		if !ok do continue

		for name_expr, i in value_decl.names {
			ident, iok := name_expr.derived_expr.(^odin_ast.Ident)
			if !iok do continue
			if i >= len(value_decl.values) do continue
			value := value_decl.values[i]

			entry := Decl_Entry {
				name       = ident.name,
				src        = file.src,
				value_decl = value_decl,
				value      = value,
			}

			#partial switch _ in value.derived_expr {
			case ^odin_ast.Struct_Type:
				append(structs, entry)
			case ^odin_ast.Enum_Type:
				append(enums, entry)
			case ^odin_ast.Union_Type:
				append(unions, entry)
			case ^odin_ast.Proc_Lit:
				pl := value.derived_expr.(^odin_ast.Proc_Lit)
				if pl.type != nil {
					append(procs, entry)
				}
			}
		}
	}
}

// ── emitters ──────────────────────────────────────────────────────────────────

emit_struct :: proc(e: ^Decl_Entry, sb: ^strings.Builder) {
	fmt.sbprintf(sb, "<details id='%s'>\n", e.name)
	fmt.sbprintf(
		sb,
		"<summary><span class='chevron'>&#9654;</span><span class='item-name'>%s</span><span class='badge badge-struct'>STRUCT</span></summary>\n",
		e.name,
	)
	emit_code_block(e.src, e.value_decl.pos.offset, e.value.end.offset, sb)
	fmt.sbprintf(sb, "</details>\n")
}

emit_enum :: proc(e: ^Decl_Entry, sb: ^strings.Builder) {
	fmt.sbprintf(sb, "<details id='%s'>\n", e.name)
	fmt.sbprintf(
		sb,
		"<summary><span class='chevron'>&#9654;</span><span class='item-name'>%s</span><span class='badge badge-enum'>ENUM</span></summary>\n",
		e.name,
	)
	emit_code_block(e.src, e.value_decl.pos.offset, e.value.end.offset, sb)
	fmt.sbprintf(sb, "</details>\n")
}

emit_union :: proc(e: ^Decl_Entry, sb: ^strings.Builder) {
	fmt.sbprintf(sb, "<details id='%s'>\n", e.name)
	fmt.sbprintf(
		sb,
		"<summary><span class='chevron'>&#9654;</span><span class='item-name'>%s</span><span class='badge badge-union'>UNION</span></summary>\n",
		e.name,
	)
	emit_code_block(e.src, e.value_decl.pos.offset, e.value.end.offset, sb)
	fmt.sbprintf(sb, "</details>\n")
}

emit_proc :: proc(e: ^Decl_Entry, sb: ^strings.Builder) {
	proc_lit := e.value.derived_expr.(^odin_ast.Proc_Lit)
	src := e.src

	fmt.sbprintf(sb, "<details id='%s'>\n", e.name)
	fmt.sbprintf(
		sb,
		"<summary><span class='chevron'>&#9654;</span><span class='item-name'>%s</span><span class='badge badge-proc'>PROC</span></summary>\n",
		e.name,
	)

	fmt.sbprintf(sb, "<div class='meta-bar'>\n")

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
		fmt.sbprintf(sb, "<span class='meta-tag'><span class='attr'>diverging</span></span>")
	}
	if proc_lit.body == nil {
		fmt.sbprintf(
			sb,
			"<span class='meta-tag'><span class='attr'>declaration only</span></span>",
		)
	}

	for attr in e.value_decl.attributes {
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

	switch proc_lit.inlining {
	case .Inline:
		fmt.sbprintf(sb, "<span class='meta-tag'><span class='attr'>force_inline</span></span>")
	case .No_Inline:
		fmt.sbprintf(sb, "<span class='meta-tag'><span class='attr'>force_no_inline</span></span>")
	case .None:
	}

	if proc_lit.type.params != nil {
		for field in proc_lit.type.params.list {
			for param_name in field.names {
				pident, pok := param_name.derived_expr.(^odin_ast.Ident)
				if !pok do continue
				type_str := extract_type_string(field.type, src)
				if field.default_value != nil {
					def, dok := field.default_value.derived_expr.(^odin_ast.Basic_Lit)
					if dok {
						fmt.sbprintf(
							sb,
							"<span class='meta-tag'><span class='label'>param</span><span class='val'>%s</span><span class='label'>:</span><span class='type'>%s</span><span class='label'> =</span><span class='num'>%s</span></span>",
							pident.name,
							type_str,
							def.tok.text,
						)
					} else {
						fmt.sbprintf(
							sb,
							"<span class='meta-tag'><span class='label'>param</span><span class='val'>%s</span><span class='label'>:</span><span class='type'>%s</span></span>",
							pident.name,
							type_str,
						)
					}
				} else {
					fmt.sbprintf(
						sb,
						"<span class='meta-tag'><span class='label'>param</span><span class='val'>%s</span><span class='label'>:</span><span class='type'>%s</span></span>",
						pident.name,
						type_str,
					)
				}
			}
		}
	}

	if proc_lit.type.results != nil {
		for field in proc_lit.type.results.list {
			if len(field.names) == 0 {
				if field.type != nil {
					rstr := extract_type_string(field.type, src)
					fmt.sbprintf(
						sb,
						"<span class='meta-tag'><span class='label'>returns</span><span class='type'>%s</span></span>",
						rstr,
					)
				}
			} else {
				for result_name in field.names {
					rident, rok := result_name.derived_expr.(^odin_ast.Ident)
					if !rok do continue
					rstr := extract_type_string(field.type, src)
					fmt.sbprintf(
						sb,
						"<span class='meta-tag'><span class='label'>returns</span><span class='val'>%s</span><span class='label'>:</span><span class='type'>%s</span></span>",
						rident.name,
						rstr,
					)
				}
			}
		}
	}

	fmt.sbprintf(sb, "</div>\n")

	if proc_lit.body != nil {
		emit_code_block(src, e.value_decl.pos.offset, proc_lit.body.end.offset, sb)
	}

	fmt.sbprintf(sb, "</details>\n")
}

emit_code_block :: proc(src: string, start, end: int, sb: ^strings.Builder) {
	if start >= len(src) || end > len(src) || start >= end do return
	fmt.sbprintf(sb, "<div class='code-wrap'>")
	fmt.sbprintf(
		sb,
		`<div class='code-header'><button class='copy-btn' onclick='copyCode(this)' title='Copy code'><svg class='copy-icon' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.5'><rect x='5' y='5' width='9' height='9' rx='1.5'/><path d='M3 11V3a1 1 0 0 1 1-1h8'/></svg><svg class='check' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.8'><path d='M3 8l3.5 3.5L13 5'/></svg></button></div>`,
	)
	fmt.sbprintf(sb, "<pre><code>")
	highlight_source(src[start:end], sb)
	fmt.sbprintf(sb, "</code></pre></div>\n")
}

// ── Type string extraction ─────────────────────────────────────────────────────

extract_type_string :: proc(expr: ^odin_ast.Expr, src: string) -> string {
	if expr == nil do return ""
	#partial switch t in expr.derived_expr {
	case ^odin_ast.Ident:
		return t.name
	case ^odin_ast.Pointer_Type:
		inner := extract_type_string(t.elem, src)
		sb: strings.Builder
		strings.builder_init(&sb)
		fmt.sbprintf(&sb, "^%s", inner)
		return strings.to_string(sb)
	case ^odin_ast.Array_Type:
		inner := extract_type_string(t.elem, src)
		sb: strings.Builder
		strings.builder_init(&sb)
		if t.len == nil {
			fmt.sbprintf(&sb, "[]%s", inner)
		} else {
			s := t.len.pos.offset
			e := t.len.end.offset
			if s < len(src) && e <= len(src) {
				fmt.sbprintf(&sb, "[%s]%s", src[s:e], inner)
			} else {
				fmt.sbprintf(&sb, "[...]%s", inner)
			}
		}
		return strings.to_string(sb)
	case ^odin_ast.Dynamic_Array_Type:
		inner := extract_type_string(t.elem, src)
		sb: strings.Builder
		strings.builder_init(&sb)
		fmt.sbprintf(&sb, "[dynamic]%s", inner)
		return strings.to_string(sb)
	case ^odin_ast.Map_Type:
		ks := extract_type_string(t.key, src)
		vs := extract_type_string(t.value, src)
		sb: strings.Builder
		strings.builder_init(&sb)
		fmt.sbprintf(&sb, "map[%s]%s", ks, vs)
		return strings.to_string(sb)
	case ^odin_ast.Selector_Expr:
		x := extract_type_string(t.expr, src)
		sel, ok := t.field.derived_expr.(^odin_ast.Ident)
		if ok {
			sb: strings.Builder
			strings.builder_init(&sb)
			fmt.sbprintf(&sb, "%s.%s", x, sel.name)
			return strings.to_string(sb)
		}
	case ^odin_ast.Multi_Pointer_Type:
		inner := extract_type_string(t.elem, src)
		sb: strings.Builder
		strings.builder_init(&sb)
		fmt.sbprintf(&sb, "[^]%s", inner)
		return strings.to_string(sb)
	}
	s := expr.pos.offset
	e := expr.end.offset
	if s < len(src) && e <= len(src) && s < e {
		return src[s:e]
	}
	return "..."
}

// ── Syntax highlighter ─────────────────────────────────────────────────────────

BUILTIN_TYPES := map[string]bool {
	"bool"          = true,
	"b8"            = true,
	"b16"           = true,
	"b32"           = true,
	"b64"           = true,
	"int"           = true,
	"uint"          = true,
	"i8"            = true,
	"i16"           = true,
	"i32"           = true,
	"i64"           = true,
	"i128"          = true,
	"u8"            = true,
	"u16"           = true,
	"u32"           = true,
	"u64"           = true,
	"u128"          = true,
	"uintptr"       = true,
	"f16"           = true,
	"f32"           = true,
	"f64"           = true,
	"f16le"         = true,
	"f16be"         = true,
	"f32le"         = true,
	"f32be"         = true,
	"f64le"         = true,
	"f64be"         = true,
	"complex32"     = true,
	"complex64"     = true,
	"complex128"    = true,
	"quaternion64"  = true,
	"quaternion128" = true,
	"quaternion256" = true,
	"string"        = true,
	"cstring"       = true,
	"rune"          = true,
	"rawptr"        = true,
	"byte"          = true,
	"typeid"        = true,
	"any"           = true,
	"i16le"         = true,
	"i32le"         = true,
	"i64le"         = true,
	"i128le"        = true,
	"u16le"         = true,
	"u32le"         = true,
	"u64le"         = true,
	"u128le"        = true,
	"i16be"         = true,
	"i32be"         = true,
	"i64be"         = true,
	"i128be"        = true,
	"u16be"         = true,
	"u32be"         = true,
	"u64be"         = true,
	"u128be"        = true,
}

BUILTIN_PROCS := map[string]bool {
	"len"              = true,
	"cap"              = true,
	"size_of"          = true,
	"align_of"         = true,
	"offset_of"        = true,
	"type_of"          = true,
	"typeid_of"        = true,
	"make"             = true,
	"new"              = true,
	"new_clone"        = true,
	"free"             = true,
	"delete"           = true,
	"append"           = true,
	"append_elems"     = true,
	"inject_at"        = true,
	"assign_at"        = true,
	"clear"            = true,
	"reserve"          = true,
	"resize"           = true,
	"copy"             = true,
	"pop"              = true,
	"unordered_remove" = true,
	"ordered_remove"   = true,
	"map_insert"       = true,
	"map_remove"       = true,
	"panic"            = true,
	"assert"           = true,
	"min"              = true,
	"max"              = true,
	"abs"              = true,
	"clamp"            = true,
	"transmute"        = true,
	"cast"             = true,
	"auto_cast"        = true,
	"nil"              = true,
	"true"             = true,
	"false"            = true,
	"context"          = true,
}

highlight_source :: proc(src: string, sb: ^strings.Builder) {
	t: tokenizer.Tokenizer
	tokenizer.init(&t, src, "")
	prev_end := 0

	for {
		token := tokenizer.scan(&t)
		if token.kind == .EOF do break

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
		     .Not_In,
		     .Do,
		     .Switch,
		     .Case,
		     .Break,
		     .Continue,
		     .Fallthrough,
		     .Defer,
		     .When,
		     .Import,
		     .Package,
		     .Foreign,
		     .Using,
		     .Or_Else,
		     .Or_Return,
		     .Struct,
		     .Enum,
		     .Union,
		     .Bit_Set,
		     .Map,
		     .Dynamic,
		     .Bit_Field,
		     .Where,
		     .Matrix:
			fmt.sbprintf(sb, "<span class='kw'>%s</span>", token.text)

		case .Integer, .Float:
			fmt.sbprintf(sb, "<span class='num'>%s</span>", token.text)

		case .String, .Rune:
			fmt.sbprintf(sb, "<span class='str'>")
			write_escaped(sb, token.text)
			strings.write_string(sb, "</span>")

		case .Comment:
			fmt.sbprintf(sb, "<span class='cm'>")
			write_escaped(sb, token.text)
			strings.write_string(sb, "</span>")

		case .Open_Brace, .Close_Brace, .Open_Paren, .Close_Paren, .Open_Bracket, .Close_Bracket:
			fmt.sbprintf(sb, "<span class='br'>%s</span>", token.text)

		case .Add,
		     .Sub,
		     .Mul,
		     .Quo,
		     .Mod,
		     .Mod_Mod,
		     .And,
		     .Or,
		     .Xor,
		     .And_Not,
		     .Eq,
		     .Not_Eq,
		     .Lt,
		     .Gt,
		     .Lt_Eq,
		     .Gt_Eq,
		     .Not,
		     .Pointer,
		     .Arrow_Right,
		     .Colon,
		     .Add_Eq,
		     .Sub_Eq,
		     .Mul_Eq,
		     .Quo_Eq,
		     .Mod_Eq,
		     .Mod_Mod_Eq,
		     .And_Eq,
		     .Or_Eq,
		     .Xor_Eq,
		     .And_Not_Eq,
		     .Shl_Eq,
		     .Shr_Eq,
		     .Shl,
		     .Shr,
		     .Ellipsis,
		     .Range_Half,
		     .Range_Full,
		     .At,
		     .Hash,
		     .Comma,
		     .Period,
		     .Semicolon:
			fmt.sbprintf(sb, "<span class='op'>")
			write_escaped(sb, token.text)
			strings.write_string(sb, "</span>")

		case .Ident:
			if BUILTIN_TYPES[token.text] {
				fmt.sbprintf(sb, "<span class='ty'>%s</span>", token.text)
			} else if BUILTIN_PROCS[token.text] {
				fmt.sbprintf(sb, "<span class='bi'>%s</span>", token.text)
			} else {
				first := rune(token.text[0])
				if first >= 'A' && first <= 'Z' {
					fmt.sbprintf(sb, "<span class='ty'>%s</span>", token.text)
				} else {
					fmt.sbprintf(sb, "<span class='ident'>%s</span>", token.text)
				}
			}

		case:
			write_escaped(sb, token.text)
		}
	}

	if prev_end < len(src) {
		write_escaped(sb, src[prev_end:])
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
