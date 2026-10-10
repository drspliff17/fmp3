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

	// Returns pointer to the audio propertiers associated with the file. Freed  automatically, when file freed
	file_audioproperties :: proc(file: ^File) -> ^AudioProperties ---

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

	// Returns cstring with the tag's comment
	tag_comment :: proc(tag: ^Tag) -> cstring ---

	// Returns cstring with the tag's genre
	tag_genre :: proc(tag: ^Tag) -> cstring ---

	// Returns the tag's year, or 0 if year is not set
	tag_year :: proc(tag: ^Tag) -> c.int ---

	// Return the tag's track number, or 0 if track number is not set
	tag_track :: proc(tag: ^Tag) -> c.int ---

	// Set the tag's title
	tag_set_title :: proc(tag: ^Tag, value: cstring) ---

	// Set the tag's artist
	tag_set_artist :: proc(tag: ^Tag, value: cstring) ---

	// Set the tag's album
	tag_set_album :: proc(tag: ^Tag, value: cstring) ---

	// Set the tag's comment
	tag_set_comment :: proc(tag: ^Tag, value: cstring) ---

	// Set the tag's genre
	tag_set_genre :: proc(tag: ^Tag, value: cstring) ---

	// Set the tag's year. 0 indicates that this field should be cleared
	tag_set_year :: proc(tag: ^Tag, value: c.int) ---

	// Set the tag's track number. 0 indicates that this field should be cleared
	tag_set_track :: proc(tag: ^Tag, value: c.int) ---

	// Frees all of the strings that have been created
	tag_free_strings :: proc() ---

	// Returns the length of the file in seconds
	audioproperties_length :: proc(ap: ^AudioProperties) -> c.int ---

	// Returns the bitrate of the file in kb/s
	audioproperties_bitrate :: proc(ap: ^AudioProperties) -> c.int ---

	// Returns the sample rate of the file in Hz
	audioproperties_samplerate :: proc(ap: ^AudioProperties) -> c.int ---

	// Returns the number of channels in the audio stream
	audioproperties_channels :: proc(ap: ^AudioProperties) -> c.int ---
}

foreign import strip "../../lib/libstrip.so"

foreign strip {
	// Remove all tags from the given path
	strip_mp3_tags :: proc(path: cstring) -> BOOL ---
}
