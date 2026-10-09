package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import tl "taglib"

CLI_PROMPT_RETURN :: enum {
	POSITIVE,
	NEGATIVE,
	INVALID,
}

CLI_MODES :: enum {
	NONE,
	SET,
	GET,
	CLEAR,
}

CLI_State :: struct {
	// Represents the target files/directories parsed from arguments
	arg_paths:                    [dynamic]string,

	// When set, GET dispatch will output data to this path, instead of stdout
	arg_output_path:              string,

	//
	arg_title:                    string,
	arg_artist:                   string,
	arg_album:                    string,

	//
	flag_get_single_line_entries: bool,
}

//TODO:
cli_print_help :: proc() {
	fmt.printfln(`fmp3
`)
}

// Wrapper for loading CLI_State.arg_paths (loader_load_path_slice), prints error and exits program
// if no paths are given. Optionally, error if no files are loaded after loader_load_path_slice() executes
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

// CLI_State Destructor
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
// Optionally, can treat_invalid_as_negative, to prevent returning .INVALID, when input does not match
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

// Prints error and exits program if:
// Fails to resolve cwd, fails to resolve output path, or
// confirmation prompt returns .NEGATIVE
// Else - returns allocated path string
cli_validate_arg_output :: proc(
	a: string,
	allocator: mem.Allocator = context.allocator,
) -> string {
	if os.is_absolute_path(a) {
		if os.exists(a) {
			fmt.eprintln("[WARN] Output redirect path already exists. Confirm overwrite: [Y/n]")
			conf := cli_confirmation_prompt(": ", true, allocator = allocator)
			if conf == .NEGATIVE {
				fmt.eprintfln("Aborting")
				os.exit(0)
			}
		}
		return fmt.aprintf("%s", a)
	} else {
		dir, de := os.get_working_directory(allocator)
		if de != nil {
			fmt.eprintfln("Failed to resolve current working directory: %v", de)
			os.exit(1)
		}
		defer delete_string(dir, allocator)

		path, e := os.join_path({dir, a}, allocator)
		if e != nil {
			fmt.eprintfln("Failed to resolve output redirect path: %s - %v", a, e)
			os.exit(1)
		}
		if os.exists(path) {
			fmt.eprintln("[WARN] Output redirect path already exists. Confirm overwrite: [Y/n]")
			conf := cli_confirmation_prompt(": ", true, allocator = allocator)
			if conf == .NEGATIVE {
				fmt.eprintfln("Aborting")
				os.exit(0)
			}
		}
		return path
	}
}

// Returns allocated string, for MP3_File tags. Optionally in single line per entry format
cli_get_mp3_string :: proc(
	file: MP3_File,
	single_line_entry: bool,
	allocator: mem.Allocator = context.allocator,
) -> string {
	title := tl.tag_title(file.tag)
	artist := tl.tag_artist(file.tag)
	album := tl.tag_album(file.tag)
	if single_line_entry {
		return fmt.aprintfln(
			"%s - T = %s - Ar = %s - Al = %s",
			file.path,
			title,
			artist,
			album,
			allocator = allocator,
		)
	} else {
		return fmt.aprintf(
			"%s\n - Title  =  %s\n - Artist =  %s\n - Album  =  %s\n\n",
			file.path,
			title,
			artist,
			album,
			allocator = allocator,
		)
	}
}
