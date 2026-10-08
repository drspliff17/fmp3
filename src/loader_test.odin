package main

import "core:os"
import "core:testing"

@(test)
load_single_file_test :: proc(t: ^testing.T) {
	p := "/home/drspliff/dev/Odin/fmp3/test/All_Signs_Point_To_Lauderdale.mp3"
	if !testing.expect(t, os.exists(string(p)), "expected test file is missing") do return

	loader := loader_init()
	defer loader_free(loader)

	loader_append_mp3(loader, p)
}

@(test)
load_dir_test :: proc(t: ^testing.T) {
	p: cstring = "/home/drspliff/dev/Odin/fmp3/test"
	if !testing.expect(t, os.exists(string(p)), "expected test file is missing") do return

	l := loader_init()
	defer loader_free(l)

	di, e := os.stat(string(p), context.allocator)
	if !testing.expect(t, e == nil, "failed to stat directory path") do return
	defer os.file_info_delete(di, context.allocator)

	files, err := os.read_all_directory_by_path(string(p), context.allocator)
	if !testing.expect(t, err == nil, "failed to read directory") do return
	defer {
		for f in files do os.file_info_delete(f, context.allocator)
		delete(files)
	}

	if !testing.expect(t, len(files) >= 2, "expected atleast 2 test files") do return

	for f in files {
		if f.type != .Regular do continue
		if os.ext(f.name) != ".mp3" do continue
		loader_append_mp3(l, f.fullpath)
	}

	if !testing.expect(t, len(l.files) > 0, "no loaded files") do return
}
