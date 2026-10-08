package taglib

import "core:c"

foreign import taglib "system:tag_c"

File :: struct {}
Tag :: struct {}
AudioProperties :: struct {}

BOOL :: enum c.int {
	FALSE = 0,
	TRUE  = 1,
}

@(link_prefix = "taglib_")
foreign taglib {
	// By default, Taglib keeps track of created strings when outputting
	// tag values. Set this to 0 to disable (Must then use free() to cleanup tag strings)
	set_string_management_enabled :: proc(management: BOOL) ---

	// Explicitly free a string returned from Taglib
	free :: proc(pointer: rawptr) ---

	// Create a Taglib file based on filename, Taglib will attempt to guess filetype
	file_new :: proc(filename: cstring) -> ^File ---

	// Frees and closes the file
	file_free :: proc(file: ^File) ---

	// Returns pointer to the tag associated with the file. Freed automatically, when file freed
	file_tag :: proc(file: ^File) -> ^Tag ---

	// Save the file to disk
	file_save :: proc(file: ^File) -> BOOL ---

	// Return true if the file is open and readable and valid information for the Tag/AudioProperties was found
	file_is_valid :: proc(file: ^File) -> BOOL ---

	// Returns cstring with the tag's title
	tag_title :: proc(tag: ^Tag) -> cstring ---

	// Returns cstring with the tag's artist
	tag_artist :: proc(tag: ^Tag) -> cstring ---

	// Returns cstring with the tag's album
	tag_album :: proc(tag: ^Tag) -> cstring ---

	// Set the tag's title
	tag_set_title :: proc(tag: ^Tag, value: cstring) ---

	// Set the tag's artist
	tag_set_artist :: proc(tag: ^Tag, value: cstring) ---

	// Set the tag's album
	tag_set_album :: proc(tag: ^Tag, value: cstring) ---

	// Frees all of the strings that have been created
	tag_free_strings :: proc() ---
}

foreign import strip "../../lib/libstrip.so"

foreign strip {
	strip_mp3_tags :: proc(path: cstring) -> BOOL ---
}
