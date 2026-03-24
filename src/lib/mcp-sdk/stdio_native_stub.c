#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef uint8_t *moonbit_bytes_t;
extern moonbit_bytes_t moonbit_make_bytes(int32_t len, int init);

#ifndef MOONBIT_FFI_EXPORT
#if defined(_WIN32)
#define MOONBIT_FFI_EXPORT __declspec(dllexport)
#else
#define MOONBIT_FFI_EXPORT __attribute__((visibility("default")))
#endif
#endif

MOONBIT_FFI_EXPORT moonbit_bytes_t codeiq_read_stdin_line_ffi() {
  size_t cap = 256;
  size_t len = 0;
  char *buf = (char *)malloc(cap);
  if (buf == NULL) {
    return moonbit_make_bytes(0, 0);
  }

  int ch = 0;
  while ((ch = fgetc(stdin)) != EOF) {
    if (len + 1 >= cap) {
      size_t next_cap = cap * 2;
      char *next = (char *)realloc(buf, next_cap);
      if (next == NULL) {
        free(buf);
        return moonbit_make_bytes(0, 0);
      }
      buf = next;
      cap = next_cap;
    }
    buf[len++] = (char)ch;
    if (ch == '\n') {
      break;
    }
  }

  if (ch == EOF && len == 0) {
    free(buf);
    return moonbit_make_bytes(0, 0);
  }

  moonbit_bytes_t out = moonbit_make_bytes((int32_t)len, 0);
  memcpy(out, buf, len);
  free(buf);
  return out;
}
