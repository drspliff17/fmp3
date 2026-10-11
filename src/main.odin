package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import tl "taglib"

main :: proc() {
	loader := loader_init()
	defer loader_free(loader)

	state := CLI_State{}
	defer cli_state_free(&state)

	mode: CLI_MODES
	arg := os.args[1:]

	// Parse args
	for len(arg) > 0 {
		switch arg[0] {

		//
		case "-ge", "getext", "--get-ext":
			a := arg[1:]
			switch a[0] {
			case "-t", "title":
				a = a[1:]

			case "-a", "artist":
				a = a[1:]

			case "-A", "album":
				a = a[1:]

			case "-c", "comment":
				a = a[1:]

			case "-g", "genre":
				a = a[1:]

			case "-y", "year":
				a = a[1:]

			case "-n", "track":
				a = a[1:]

			}

		//
		case "-g", "get", "--get":
			a := arg[1:]
			for len(a) > 0 {
				switch a[0] {
				case "-l", "line", "--line":
					state.flag_get_single_line_entries = true
					a = a[1:]

				case "-o", "out", "--output":
					if len(a[1:]) == 0 {
						fmt.eprintln("Expected a path for output redirect")
						os.exit(1)
					}
					p := cli_validate_arg_output(a[1])
					state.unit_output_path.arg = p
					a = a[2:]

				case:
					append(&state.arg_paths, fmt.aprintf("%s", a[0]))
					a = a[1:]

				}
			}
			mode = .GET
			arg = {}

		//
		case "-clr", "clear", "--clear":
			for s in arg[1:] do append(&state.arg_paths, fmt.aprintf("%s", s))
			mode = .CLEAR
			arg = {}

		//
		case "-s", "set", "--set":
			a := arg[1:]
			if len(a) < 3 {
				fmt.eprintln(
					"Expected at least 3 arguments.\nUsage: fmp3 -s -t 'Title Here' -a Artist -A 'Album' path/to/file [path/to/dir]",
				)
				os.exit(1)
			}

			for len(a) > 0 {
				switch a[0] {
				case "-t", "title", "--title":
					if len(a) < 2 {
						fmt.eprintln("Expected a value to set title tag")
						os.exit(1)
					}
					state.unit_title.arg = fmt.aprintf("%s", a[1])
					a = a[2:]

				case "-a", "artist", "--artist":
					if len(a) < 2 {
						fmt.eprintln("Expected a value to set artist tag")
						os.exit(1)
					}
					state.unit_artist.arg = fmt.aprintf("%s", a[1])
					a = a[2:]

				case "-A", "album", "--album":
					if len(a) < 2 {
						fmt.eprintln("Expected a value to set album tag")
						os.exit(1)
					}
					state.unit_album.arg = fmt.aprintf("%s", a[1])
					a = a[2:]

				case "-c", "comment", "--comment":
					if len(a) < 2 {
						fmt.eprintln("Expected a value to set comment tag")
						os.exit(1)
					}
					state.unit_comment.arg = fmt.aprintf("%s", a[1])
					a = a[2:]

				case "-g", "genre", "--genre":
					if len(a) < 2 {
						fmt.eprintln("Expected a value to set genre tag")
						os.exit(1)
					}
					state.unit_genre.arg = fmt.aprintf("%s", a[1])
					a = a[2:]

				case "-y", "year", "--year":
					if len(a) < 2 {
						fmt.eprintln("Expected a value to set year tag")
						os.exit(1)
					}

					v, ok := strconv.parse_int(a[1], 10)
					if !ok {
						fmt.eprintln("Invalid value provided for year tag")
						os.exit(1)
					}
					state.unit_year.arg = v < 0 ? 0 : i32(v)
					a = a[2:]

				case "-n", "track", "--track":
					if len(a) < 2 {
						fmt.eprintln("Expected a value to set track tag")
						os.exit(1)
					}

					v, ok := strconv.parse_int(a[1], 10)
					if !ok {
						fmt.eprintln("Invalid value provided for track tag")
						os.exit(1)
					}
					state.unit_track.arg = v < 0 ? 0 : i32(v)
					a = a[2:]


				case:
					if !os.exists(a[0]) {
						fmt.eprintfln("Invalid argument or nonexistent path: %s", a[0])
						os.exit(1)
					}
					append(&state.arg_paths, fmt.aprintf("%s", a[0]))
					a = a[1:]
				}
			}
			mode = .SET
			arg = {}

		//
		case:
			fmt.eprintfln("Unknown argument: %s", arg[0])
			os.exit(1)
		}
	}


	// Dispatch mode
	switch mode {
	case .NONE:
		cli_print_help()
		return

	//
	case .SET:
		cli_load_paths(loader, &state)

		for f in loader.files {
			if state.unit_title.arg != "" {
				ct := fmt.caprintf("%s", state.unit_title.arg)
				tl.tag_set_title(f.tag, ct)
				delete_cstring(ct)
			}

			if state.unit_artist.arg != "" {
				ca := fmt.caprintf("%s", state.unit_artist.arg)
				tl.tag_set_artist(f.tag, ca)
				delete_cstring(ca)
			}

			if state.unit_album.arg != "" {
				cA := fmt.caprintf("%s", state.unit_album.arg)
				tl.tag_set_album(f.tag, cA)
				delete_cstring(cA)
			}

			if tl.file_save(f.tagfile) == .FALSE do fmt.eprintfln("Failed to set tags: %s", f.path)
		}

	//
	case .GET:
		cli_load_paths(loader, &state)

		if state.unit_output_path.arg == "" {
			for f in loader.files {
				s := cli_get_mp3_string(f, state.flag_get_single_line_entries)
				fmt.print(s)
				delete_string(s)
			}
		} else {
			ts := make([dynamic]string)
			defer {
				for s in ts do delete_string(s)
				delete(ts)
			}

			for f in loader.files {
				s := cli_get_mp3_string(f, state.flag_get_single_line_entries)
				append(&ts, s)
			}

			str := strings.concatenate(ts[:], context.allocator)
			defer delete_string(str)

			e := os.write_entire_file_from_string(state.unit_output_path.arg, str)
			if e != nil {
				fmt.eprintfln("Failed to write output: %s - %v", state.unit_output_path.arg, e)
				os.exit(1)
			}

		}

	//
	case .CLEAR:
		cli_load_paths(loader, &state)

		for f in loader.files {
			cf := fmt.caprintf("%s", f.path)
			if ok := tl.strip_mp3_tags(cf); ok == .FALSE do fmt.eprintfln("Failed to strip %s", f.path)
			delete_cstring(cf)
		}
	}

}
