package test

import "core:fmt"

// 1. basic proc no params no return
basic :: proc() {
	fmt.println("basic")
}

// 2. single param single return
add :: proc(x: int) -> int {
	return x + 1
}

// 3. multiple params same type
add_two :: proc(x, y: int) -> int {
	return x + y
}

// 4. multiple params different types
mixed_params :: proc(x: int, y: f32, z: string) -> bool {
	return true
}

// 5. named return
named_return :: proc(x: int) -> (result: int) {
	result = x * 2
	return
}

// 6. multiple named returns
multi_named_return :: proc(x: int) -> (value: int, ok: bool) {
	return x, true
}

// 7. multiple unnamed returns
multi_unnamed_return :: proc(x: int) -> (int, bool) {
	return x, true
}

// 8. default param value
default_value :: proc(x: int = 10, y: int = 20) -> int {
	return x + y
}

// 9. calling convention c
foreign_c :: proc "c" (x: i32) -> i32 {
	return x
}

// 10. calling convention stdcall
foreign_std :: proc "stdcall" (x: i32) -> i32 {
	return x
}

// 11. attributes
@(private = "file")
private_proc :: proc() {
	fmt.println("private")
}

// 12. multiple attributes
@(private)
@(export)
multi_attr :: proc() {}

// 13. generic proc single type param
generic_single :: proc(x: $T) -> T {
	return x
}

// 14. generic proc multiple type params
generic_multi :: proc(x: $T, y: $U) -> T {
	return x
}

// 15. where clause
generic_where :: proc(x: $T) -> T where intrinsics.type_is_integer(T) {
	return x + 1
}

// 16. diverging proc never returns
diverging :: proc() -> ! {
	for {}
}

// 17. using param
Using_Struct :: struct {
	x, y: f32,
}

// 18. variadic params
variadic :: proc(args: ..int) -> int {
	total := 0
	for a in args do total += a
	return total
}

// 19. variadic any
variadic_any :: proc(args: ..any) {
	fmt.println(args)
}

// 20. proc type declaration no body
Callback :: proc(dt: f32)

// 21. proc pointer as param
takes_callback :: proc(cb: proc(dt: f32), dt: f32) {
	cb(dt)
}

// 22. proc returning proc
returns_proc :: proc() -> proc(_: int) -> int {
	return proc(x: int) -> int {return x}
}

// 23. no param with multiple returns
no_param_multi_return :: proc() -> (int, string, bool) {
	return 1, "hello", true
}

// 24. foreign attribute with calling convention
@(private = "file")
@(objc_name = "test")
foreign_proc :: proc "c" (x: i32) -> i32 {
	return x * 2
}

// 25. inline forced
foo :: #force_inline proc() {
	fmt.println("inlined")
}

// 26. inline no forced
foo_no :: #force_no_inline proc() {
	fmt.println("no inlined")
}
