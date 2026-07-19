package test

// ── Enums ────────────────────────────────────────────────────────────────────

Direction :: enum {
	North,
	South,
	East,
	West,
}

Color :: enum u8 {
	Red   = 0,
	Green = 1,
	Blue  = 2,
	Alpha = 255,
}

Token_Kind :: enum {
	Invalid,
	EOF,
	Ident,
	Int,
	Float,
	String,
	Plus,
	Minus,
	Star,
	Slash,
	Eq,
	Not_Eq,
	Lt,
	Gt,
	Open_Paren,
	Close_Paren,
	Open_Brace,
	Close_Brace,
	Comma,
	Semicolon,
}

Log_Level :: enum i32 {
	Debug   = 0,
	Info    = 1,
	Warning = 2,
	Error   = 3,
	Fatal   = 4,
}


// ── Structs ───────────────────────────────────────────────────────────────────

Vec2 :: struct {
	x: f32,
	y: f32,
}

Vec3 :: struct {
	x: f32,
	y: f32,
	z: f32,
}

Rect :: struct {
	x:      f32,
	y:      f32,
	width:  f32,
	height: f32,
}

Color_RGBA :: struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
}

Transform :: struct {
	position: Vec3,
	rotation: Vec3,
	scale:    Vec3,
}

Entity :: struct {
	id:        u64,
	name:      string,
	transform: Transform,
	active:    bool,
	tag:       u32,
}

Allocator_Stats :: struct #packed {
	total_allocated:  int,
	total_freed:      int,
	current_usage:    int,
	peak_usage:       int,
	allocation_count: int,
}

Node :: struct {
	value: int,
	left:  ^Node,
	right: ^Node,
}

Slice_Header :: struct {
	data: rawptr,
	len:  int,
	cap:  int,
}

HTTP_Request :: struct {
	method:  string,
	path:    string,
	headers: map[string]string,
	body:    []u8,
}


// ── Unions ────────────────────────────────────────────────────────────────────

Number :: union {
	int,
	f64,
}

JSON_Value :: union {
	bool,
	int,
	f64,
	string,
	[]JSON_Value,
	map[string]JSON_Value,
}

Expr :: union {
	int,
	f64,
	string,
	^Binary_Expr,
	^Unary_Expr,
	^Call_Expr,
}

Binary_Expr :: struct {
	op:    string,
	left:  Expr,
	right: Expr,
}

Unary_Expr :: struct {
	op:      string,
	operand: Expr,
}

Call_Expr :: struct {
	callee: string,
	args:   []Expr,
}

Socket_Addr :: union {
	IPv4_Addr,
	IPv6_Addr,
}

IPv4_Addr :: struct {
	octets: [4]u8,
	port:   u16,
}

IPv6_Addr :: struct {
	groups: [8]u16,
	port:   u16,
}

Result :: union {
	string, // ok value
	Error,
}

Error :: struct {
	code:    int,
	message: string,
}


// ── Procs ─────────────────────────────────────────────────────────────────────

vec2_add :: proc(a: Vec2, b: Vec2) -> Vec2 {
	return Vec2{a.x + b.x, a.y + b.y}
}

vec2_length :: proc(v: Vec2) -> f32 {
	return 0 // placeholder
}

rect_contains :: proc(r: Rect, p: Vec2) -> bool {
	return p.x >= r.x && p.x <= r.x + r.width && p.y >= r.y && p.y <= r.y + r.height
}

entity_set_active :: proc(e: ^Entity, active: bool) {
	e.active = active
}

json_is_null :: proc(v: JSON_Value) -> bool {
	return v == nil
}

result_unwrap :: proc(r: Result) -> string {
	val, ok := r.(string)
	if !ok do return ""
	return val
}
