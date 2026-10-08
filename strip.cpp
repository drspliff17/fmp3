#include <mpegfile.h>

extern "C" int strip_mp3_tags(const char *path) {
  try {
    TagLib::MPEG::File f(path, false);
    return f.isValid() && !f.readOnly()
      && f.strip(TagLib::MPEG::File::AllTags);
  } catch (...) {
    return 0;
  }
}
