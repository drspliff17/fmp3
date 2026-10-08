package main

import "core:c"

foreign import taglib "system:tag_c"

File :: struct {}
Tag :: struct {}

@(link_prefix = "taglib_")
foreign taglib {
	file_new :: proc(filename: cstring) -> ^File ---
	file_free :: proc(file: ^File) ---
	file_tag :: proc(file: ^File) -> ^Tag ---
	file_save :: proc(file: ^File) -> c.int ---

	tag_title :: proc(tag: ^Tag) -> cstring ---
	tag_artist :: proc(tag: ^Tag) -> cstring ---
	tag_album :: proc(tag: ^Tag) -> cstring ---
	tag_set_title :: proc(tag: ^Tag, value: cstring) ---
	tag_set_artist :: proc(tag: ^Tag, value: cstring) ---
	tag_set_album :: proc(tag: ^Tag, value: cstring) ---
	tag_free_strings :: proc() ---
}
