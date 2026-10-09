package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

CLI_PROMPT_RETURN :: enum {
	POSITIVE,
	NEGATIVE,
	INVALID,
}

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

// Simple In/Out prompt, displays given string, returns allocated user input data
cli_generic_prompt :: proc(
	display_msg: string,
	allocator: mem.Allocator = context.allocator,
) -> string {
	fmt.print(display_msg)
	buf: [1]u8
	out: [256]u8
	i := 0
	for {
		n, err := os.read(os.stdin, buf[:])
		if err != nil || n == 0 do break
		if buf[0] == '\n' do break
		if i < len(out) {
			out[i] = buf[0]
			i += 1
		}
	}
	return fmt.aprintf("%s", string(out[:i]))
}

// Extends genericPrompt, checks if input is within  defaults [y/yes - n/no] (case insensitive)
// Optionally, can set treat_invalid_as_negative, to prevent returning Prompt_Return.InvalidInput, when input does not match
// p_valid or n_valid
cli_confirmation_prompt :: proc(
	display_msg: string,
	treat_invalid_as_negative: bool,
	allocator: mem.Allocator = context.allocator,
) -> CLI_PROMPT_RETURN {
	p_valid := []string{"y", "yes"}
	n_valid := []string{"n", "no"}

	input := cli_generic_prompt(display_msg, allocator)
	linput := strings.to_lower(input, allocator)
	defer {
		delete_string(input)
		delete_string(linput)
	}

	for pk in p_valid do if linput == pk do return .POSITIVE
	for nk in n_valid do if linput == nk do return .NEGATIVE
	if treat_invalid_as_negative do return .NEGATIVE
	return .INVALID
}
