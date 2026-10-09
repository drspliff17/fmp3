package main

import "core:fmt"
import "core:os"
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
					state.arg_output_path = fmt.aprint("%s", a[1])
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
					state.arg_title = fmt.aprintf("%s", a[1])
					a = a[2:]

				case "-a", "artist", "--artist":
					if len(a) < 2 {
						fmt.eprintln("Expected a value to set artist tag")
						os.exit(1)
					}
					state.arg_artist = fmt.aprintf("%s", a[1])
					a = a[2:]

				case "-A", "album", "--album":
					if len(a) < 2 {
						fmt.eprintln("Expected a value to set album tag")
						os.exit(1)
					}
					state.arg_album = fmt.aprintf("%s", a[1])
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
		print_help()
		return

	//
	case .SET:
		cli_load_paths(loader, &state)

		for f in loader.files {
			if state.arg_title != "" {
				ct := fmt.caprintf("%s", state.arg_title)
				tl.tag_set_title(f.tag, ct)
				delete_cstring(ct)
			}

			if state.arg_artist != "" {
				ca := fmt.caprintf("%s", state.arg_artist)
				tl.tag_set_artist(f.tag, ca)
				delete_cstring(ca)
			}

			if state.arg_album != "" {
				cA := fmt.caprintf("%s", state.arg_album)
				tl.tag_set_album(f.tag, cA)
				delete_cstring(cA)
			}

			if tl.file_save(f.tagfile) == .FALSE do fmt.eprintfln("Failed to set tags: %s", f.path)
		}

	//
	case .GET:
		cli_load_paths(loader, &state)

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
