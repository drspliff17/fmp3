package main

import "core:os"
import "core:testing"

@(test)
get_file_test :: proc(t: ^testing.T) {
	path := "/home/drspliff/dev/Odin/fmp3/test/All_Signs_Point_To_Lauderdale.mp3"
	if !testing.expect(t, os.exists(path), "expected test file not found") do return

	_, stdout, stderr, err := os.process_exec(
		os.Process_Desc{command = []string{"fmp3", "-g", path}},
		context.allocator,
	)
	defer {
		delete(stdout)
		delete(stderr)
	}

	if !testing.expect(t, err == nil, "fmp3 process failed to execute") do return
	if !testing.expect(t, len(stderr) == 0, "fmp3 returned error") do return
	if !testing.expect(t, len(stdout) > 0, "fmp3 did not return any data") do return
}

@(test)
get_file_line_test :: proc(t: ^testing.T) {
	path := "/home/drspliff/dev/Odin/fmp3/test/All_Signs_Point_To_Lauderdale.mp3"
	if !testing.expect(t, os.exists(path), "expected test file not found") do return

	_, stdout, stderr, err := os.process_exec(
		os.Process_Desc{command = []string{"fmp3", "-g", "-l", path}},
		context.allocator,
	)
	defer {
		delete(stdout)
		delete(stderr)
	}

	if !testing.expect(t, err == nil, "fmp3 process failed to execute") do return
	if !testing.expect(t, len(stderr) == 0, "fmp3 returned error") do return
	if !testing.expect(t, len(stdout) > 0, "fmp3 did not return any data") do return
}

@(test)
get_output_test :: proc(t: ^testing.T) {
	path := "/home/drspliff/dev/Odin/fmp3/test/All_Signs_Point_To_Lauderdale.mp3"
	if !testing.expect(t, os.exists(path), "expected test file not found") do return

	wd := "/home/drspliff/dev/Odin/fmp3/test"
	tp, _ := os.join_path({wd, "test.txt"}, context.allocator)
	defer delete_string(tp)

	if os.exists(tp) {
		e := os.remove(tp)
		if !testing.expect(t, e == nil, "failed to remove existing test file") do return
	}

	_, stdout, stderr, err := os.process_exec(
		os.Process_Desc {
			working_dir = wd,
			command = []string {
				"fmp3",
				"-g",
				"-o",
				"text.txt",
				"All_Signs_Point_To_Lauderdale.mp3",
			},
		},
		context.allocator,
	)
	defer {
		delete(stdout)
		delete(stderr)
	}

	if !testing.expect(t, err == nil, "fmp3 process failed to execute") do return
}

@(test)
get_directory_test :: proc(t: ^testing.T) {
	path := "/home/drspliff/dev/Odin/fmp3/test"
	if !testing.expect(t, os.exists(path), "expected test directory not found") do return

	_, stdout, stderr, err := os.process_exec(
		os.Process_Desc{command = []string{"fmp3", "-g", path}},
		context.allocator,
	)
	defer {
		delete(stdout)
		delete(stderr)
	}

	if !testing.expect(t, err == nil, "fmp3 process failed to execute") do return
	if !testing.expect(t, len(stderr) == 0, "fmp3 returned error") do return
	if !testing.expect(t, len(stdout) > 0, "fmp3 did not return any data") do return
}

@(test)
get_directory_line_test :: proc(t: ^testing.T) {
	path := "/home/drspliff/dev/Odin/fmp3/test"
	if !testing.expect(t, os.exists(path), "expected test directory not found") do return

	_, stdout, stderr, err := os.process_exec(
		os.Process_Desc{command = []string{"fmp3", "-g", "-l", path}},
		context.allocator,
	)
	defer {
		delete(stdout)
		delete(stderr)
	}

	if !testing.expect(t, err == nil, "fmp3 process failed to execute") do return
	if !testing.expect(t, len(stderr) == 0, "fmp3 returned error") do return
	if !testing.expect(t, len(stdout) > 0, "fmp3 did not return any data") do return
}
