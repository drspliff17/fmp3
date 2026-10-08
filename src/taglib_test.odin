package main

import "core:os"
import "core:testing"

@(test)
read_mp3_tags :: proc(t: ^testing.T) {
	path: cstring = "/home/drspliff/dev/Odin/fmp3/test/All_Signs_Point_To_Lauderdale.mp3"
	file := file_new(path)
	if !testing.expect(t, file != nil, "file_new returned nil") do return
	defer file_free(file)

	tag := file_tag(file)
	if !testing.expect(t, tag != nil, "file_tag returned nil") do return
	defer tag_free_strings()

	title := tag_title(tag)
	artist := tag_artist(tag)
	album := tag_album(tag)

	if testing.expect(t, title != nil, "title returned nil") do testing.expect(t, len(string(title)) > 0, "title is empty")
	if testing.expect(t, artist != nil, "artist returned nil") do testing.expect(t, len(string(artist)) > 0, "artist is empty")
	if testing.expect(t, album != nil, "album returned nil") do testing.expect(t, len(string(album)) > 0, "album is empty")
}

@(test)
edit_mp3_tags :: proc(t: ^testing.T) {
	og_path: cstring = "/home/drspliff/dev/Odin/fmp3/test/All_Signs_Point_To_Lauderdale.mp3"
	new_path: cstring = "/home/drspliff/dev/Odin/fmp3/test/Edited_Tags_All_Signs_Point_To_Lauderdale.mp3"

	if os.exists(string(new_path)) {
		remove_err := os.remove(string(new_path))
		if !testing.expect(t, remove_err == nil, "failed to remove old test file") do return
	}

	if !testing.expect(t, !os.exists(string(new_path)), "failed to clean test file") do return

	copy_err := os.copy_file(string(new_path), string(og_path))
	if !testing.expect(t, copy_err == nil, "failed to copy test file") do return

	// Close the writer before reopening the file
	{
		file := file_new(new_path)
		if !testing.expect(t, file != nil, "file_new returned nil") do return
		defer file_free(file)

		tag := file_tag(file)
		if !testing.expect(t, tag != nil, "file_tag returned nil") do return

		tag_set_title(tag, "Test Title")
		tag_set_artist(tag, "Test Artist")
		tag_set_album(tag, "Test Album")

		saved := file_save(file)
		if !testing.expect(t, saved != 0, "file_save failed") do return
	}

	file := file_new(new_path)
	if !testing.expect(t, file != nil, "reopening edited file failed") do return
	defer file_free(file)
	defer tag_free_strings()

	tag := file_tag(file)
	if !testing.expect(t, tag != nil, "file_tag returned nil") do return

	title := tag_title(tag)
	artist := tag_artist(tag)
	album := tag_album(tag)

	if testing.expect(t, title != nil, "title returned nil") do testing.expect_value(t, string(title), "Test Title")
	if testing.expect(t, artist != nil, "artist returned nil") do testing.expect_value(t, string(artist), "Test Artist")
	if testing.expect(t, album != nil, "album returned nil") do testing.expect_value(t, string(album), "Test Album")
}

@(test)
read_mp3_tags_manual_strings :: proc(t: ^testing.T) {
	set_string_management_enabled(.FALSE)
	defer set_string_management_enabled(.TRUE)

	path: cstring = "/home/drspliff/dev/Odin/fmp3/test/All_Signs_Point_To_Lauderdale.mp3"
	file := file_new(path)
	if !testing.expect(t, file != nil, "file_new returned nil") do return
	defer file_free(file)

	tag := file_tag(file)
	if !testing.expect(t, tag != nil, "file_tag returned nil") do return

	title := tag_title(tag)
	if title != nil do defer free(cast(rawptr)title)

	artist := tag_artist(tag)
	if artist != nil do defer free(cast(rawptr)artist)

	album := tag_album(tag)
	if album != nil do defer free(cast(rawptr)album)

	if testing.expect(t, title != nil, "title returned nil") do testing.expect(t, len(string(title)) > 0, "title is empty")
	if testing.expect(t, artist != nil, "artist returned nil") do testing.expect(t, len(string(artist)) > 0, "artist is empty")
	if testing.expect(t, album != nil, "album returned nil") do testing.expect(t, len(string(album)) > 0, "album is empty")
}
