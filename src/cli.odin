package main

import "core:fmt"
import "core:os"

// Core CLI modes, effectively dispatchers
CLI_MODES :: enum {
	NONE,
	SET,
	GET,
	CLEAR,
}

print_help :: proc() {
	fmt.printfln(`fmp3
`)
}

CLI_State :: struct {
	arg_paths:                    [dynamic]string,
	arg_title:                    string,
	arg_artist:                   string,
	arg_album:                    string,
	arg_output_path:              string,
	flag_get_single_line_entries: bool,
}

// Wrapper for loading CLI_State.arg_paths (loader_load_path_slice), prints error and exits program
// if no paths are given. Optionally error if no files are loaded after loader_load_path_slice() executes
cli_load_paths :: proc(l: ^Loader, s: ^CLI_State, err_if_none_loaded: bool = true) {
	if len(s^.arg_paths) == 0 {
		fmt.eprintln("Expected atleast one path")
		os.exit(1)
	}
	loader_load_path_slice(l, s^.arg_paths[:])
	if err_if_none_loaded && len(l.files) == 0 {
		fmt.eprintfln("No .mp3 files loaded")
		os.exit(1)
	}
}

cli_state_free :: proc(state: ^CLI_State) {
	if len(state.arg_title) > 0 do delete_string(state.arg_title)
	if len(state.arg_artist) > 0 do delete_string(state.arg_artist)
	if len(state.arg_album) > 0 do delete_string(state.arg_album)
	if len(state.arg_output_path) > 0 do delete_string(state.arg_output_path)
	for s in state.arg_paths do delete_string(s)
	delete(state.arg_paths)
}
