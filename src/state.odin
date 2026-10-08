package main

import "core:fmt"

State :: struct {
	arg_paths:                    [dynamic]string,
	arg_title:                    string,
	arg_artist:                   string,
	arg_album:                    string,
	flag_get_single_line_entries: bool,
}

load_state_arg_paths :: proc(loader: ^Loader, paths: []string) {
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

state_free :: proc(state: ^State) {
	if len(state.arg_title) > 0 do delete_string(state.arg_title)
	if len(state.arg_artist) > 0 do delete_string(state.arg_artist)
	if len(state.arg_album) > 0 do delete_string(state.arg_album)
	for s in state.arg_paths do delete_string(s)
	delete(state.arg_paths)
}
