package main

import "core:fmt"
import "core:os"
import tl "taglib"

//NOTE:
// - Old default was to set the tags (which would be prompted, if not already set via options)
//   of every file in the current working directory.
// - Alt mode, only set the tags to the specified files (-f option, then each following arg was treated as a file path).
// - Get mode, to dump the meta of specified files.
// - Get missing, to return the paths of any files missing an album tag (From legacy process).
// - Set files missing an album to current tags. (From legacy process).
// - Trim mode, delete all tags from the file. (From legacy process).
// - Target album, set the tags of only matching specified album tag (From legacy process, with prompt).
// - Dump all, performs eyeD3 on every file in current working directory.
// - Debug dump, lazily added recently, dumps only files in the current working directory that match the
//   specified album tag.

MODES :: enum {
	NONE,
	SET,
	GET,
}

State :: struct {
	arg_paths:                    [dynamic]string,
	arg_title:                    string,
	arg_artist:                   string,
	arg_album:                    string,
	flag_get_single_line_entries: bool,
}

print_help :: proc() {
	fmt.printfln(`fmp3
`)
}


main :: proc() {
	loader := loader_init()
	defer loader_free(loader)

	state := State{}
	defer {
		if len(state.arg_title) > 0 do delete_string(state.arg_title)
		if len(state.arg_artist) > 0 do delete_string(state.arg_artist)
		if len(state.arg_album) > 0 do delete_string(state.arg_album)
		for s in state.arg_paths do delete_string(s)
		delete(state.arg_paths)
	}

	mode: MODES
	arg := os.args[1:]
	for len(arg) > 0 {
		switch arg[0] {
		case "-g", "get", "--get":
			switch arg[1] {
			case "-l", "line", "--line":
				state.flag_get_single_line_entries = true
				arg = arg[1:]
			}

			for s in arg[1:] do append(&state.arg_paths, fmt.aprintf("%s", s))
			mode = .GET
			arg = {}
		case:
			fmt.eprintfln("Unknown argument: %s", arg[0])
			os.exit(1)
		}
	}

	switch mode {
	case .NONE:
		print_help()
		return

	case .SET:

	case .GET:
		if len(state.arg_paths) == 0 {
			fmt.eprintln("Expected atleast one path")
			os.exit(1)
		}

		for p, i in state.arg_paths {
			if loader_validate_directory(p) {
				loader_load_directory(loader, p)
			} else if loader_validate_from_string(p) {
				loader_load_file(loader, p)
			} else {
				fmt.eprintfln(
					"Invalid path: %s - Expected either directory containing .mp3 files, or a path to an .mp3 file\nSkipping",
					p,
				)
				if i == len(state.arg_paths) - 1 {
					fmt.eprintfln("Aborting")
					os.exit(1)
				}
				continue
			}
		}

		if len(loader.files) == 0 {
			fmt.eprintfln("No .mp3 files loaded")
			os.exit(1)
		}

		for f in loader.files {
			title := tl.tag_title(f.tag)
			artist := tl.tag_artist(f.tag)
			album := tl.tag_album(f.tag)
			if state.flag_get_single_line_entries {
				fmt.printfln("%s - T = %s - Ar = %s - Al = %s", f.path, title, artist, album)
			} else {
				fmt.printf(
					"%s\n - Title  =  %s\n - Artist =  %s\n - Album  =  %s\n\n",
					f.path,
					title,
					artist,
					album,
				)
			}
		}

	}

}
