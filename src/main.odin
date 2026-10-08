package main

import "core:fmt"
import "core:strings"

main :: proc() {
	path := strings.clone_to_cstring(
		"/home/drspliff/Music/Songs/2Pac/16_On_Death_Row.mp3",
		context.temp_allocator,
	)

	file := file_new(path)
	if file == nil {
		fmt.println("Could not open file")
		return
	}
	defer file_free(file)

	tag := file_tag(file)
	title := tag_title(tag)
	artist := tag_artist(tag)
	album := tag_album(tag)

	if title != nil do fmt.println("Title:", string(title))
	if artist != nil do fmt.println("Artist:", string(artist))
	if album != nil do fmt.println("Album:", string(album))
	tag_free_strings()
}
