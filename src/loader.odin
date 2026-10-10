package main

import "core:fmt"
import "core:os"
import tl "taglib"

// Used explicitly by Loader
MP3_File :: struct {
	tagfile: ^tl.File,
	tag:     ^tl.Tag,
	audio:   ^tl.AudioProperties,
	path:    string,
}

// Constructor - MP3_File.path is cloned from arg. Uses tl.file_new and tl.file_tag for tagfile/tag respectively
mp3_create :: proc(path: cstring) -> (mp3: MP3_File, ok: bool) {
	tf := tl.file_new(path)
	if tf == nil do return {}, false

	tt := tl.file_tag(tf)
	if tt == nil {
		tl.file_free(tf)
		return {}, false
	}

	ap := tl.file_audioproperties(tf)
	if ap == nil {
		tl.file_free(tf)
		return {}, false
	}

	m := MP3_File {
		path    = fmt.aprintf("%s", path),
		tagfile = tf,
		tag     = tt,
		audio   = ap,
	}

	return m, true
}

// Destructor
mp3_free :: proc(m: ^MP3_File) {
	tl.file_free(m.tagfile)
	delete_string(m.path)
	m^ = {}
}

// Singleton
Loader :: struct {
	files: [dynamic]MP3_File,
}

// Constructs Loader
loader_init :: proc() -> ^Loader {
	l, e := new(Loader)
	if e != nil do fmt.panicf("Failed to allocate Loader. This should never happen, you fucked up - %v", e)
	return l
}

// Destructor
loader_free :: proc(l: ^Loader) {
	for &f in l.files do mp3_free(&f)
	delete(l.files)
	free(l)
	tl.tag_free_strings()
}


// Ensure given file_info is a directory
loader_validate_directory_from_file_info :: proc(file: os.File_Info) -> bool {
	if file.type != .Directory do return false
	return true
}

// Ensures given path is a directory, wraps loader_validate_directory_from_file_info
loader_validate_directory_from_string :: proc(path: string) -> bool {
	i, e := os.stat(path, context.allocator)
	if e != nil do return false
	defer os.file_info_delete(i, context.allocator)
	return loader_validate_directory_from_file_info(i)
}

// Ensure given file_info is a .mp3 file
loader_validate_file_from_file_info :: proc(file: os.File_Info) -> bool {
	if file.type != .Regular do return false
	if os.ext(file.name) != ".mp3" do return false
	return true
}

// Ensure given path is a .mp3 file, wraps loader_validate_file_from_file_info
loader_validate_file_from_string :: proc(path: string) -> bool {
	f, e := os.stat(path, context.allocator)
	if e != nil do return false
	defer os.file_info_delete(f, context.allocator)
	return loader_validate_file_from_file_info(f)
}

// Create and append MP3_File to Loader
loader_append_mp3 :: proc(loader: ^Loader, path: string) -> bool {
	p := fmt.caprintf("%s", path)
	defer delete_cstring(p)
	f, ok := mp3_create(p)
	if !ok do return false
	if _, e := append(&loader.files, f); e != nil do fmt.panicf("Failed to append MP3_File to Loader: %v", e)
	return true
}

// Attempts to load file from given path
loader_load_file :: proc(loader: ^Loader, path: string) -> bool {
	if !loader_validate_file_from_string(path) do return false
	return loader_append_mp3(loader, path)
}

// Attempts to load all valid files inside given path
loader_load_directory :: proc(loader: ^Loader, path: string) -> bool {
	if !loader_validate_directory_from_string(path) do return false

	files, err := os.read_all_directory_by_path(path, context.allocator)
	if err != nil {
		fmt.eprintfln("Failed to read directory: %v", err)
		return false
	}
	defer {
		for f in files do os.file_info_delete(f, context.allocator)
		delete(files)
	}

	for f in files do if !loader_load_path(loader, f.fullpath) do continue
	return true
}

// Attempts to load given path, calling either loader_load_directory or loader_load_file based on type
loader_load_path :: proc(loader: ^Loader, path: string) -> bool {
	if loader_validate_directory_from_string(path) {
		return loader_load_directory(loader, path)
	} else if loader_validate_file_from_string(path) {
		return loader_load_file(loader, path)
	} else {
		return false
	}
}

// Attempts to call loader_load_path on each given string. Prints error message if invalid path is given
// however, does not break the loop until are paths have been attempted
loader_load_path_slice :: proc(loader: ^Loader, paths: []string) {
	for p, i in paths {
		if !loader_load_path(loader, p) {
			fmt.eprintfln(
				"Invalid path: %s - Expected either directory containing .mp3 files, or a path to an .mp3 file\nSkipping",
				p,
			)
			continue
		}
	}
}
