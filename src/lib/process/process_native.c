#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>

#include "moonbit.h"

#ifdef _WIN32
#define CODEIQ_POPEN _popen
#define CODEIQ_PCLOSE _pclose
#else
#define CODEIQ_POPEN popen
#define CODEIQ_PCLOSE pclose
#endif

static moonbit_bytes_t codeiq_make_bytes_from_cstr(const char *s) {
  size_t len = strlen(s);
  moonbit_bytes_t out = moonbit_make_bytes((int)len, 0);
  if (len > 0) {
    memcpy(out, s, len);
  }
  return out;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t *codeiq_process_run_command_capture(
    moonbit_bytes_t command) {
  moonbit_bytes_t *result =
      (moonbit_bytes_t *)moonbit_make_ref_array(3, NULL);

  size_t cmd_len = strlen((const char *)command);
  size_t wrapped_len = cmd_len + strlen(" 2>&1") + 1;
  char *wrapped = (char *)malloc(wrapped_len);
  if (wrapped == NULL) {
    result[0] = codeiq_make_bytes_from_cstr("127");
    result[1] = codeiq_make_bytes_from_cstr("");
    result[2] = codeiq_make_bytes_from_cstr("failed to allocate command buffer");
    return result;
  }

  snprintf(wrapped, wrapped_len, "%s 2>&1", (const char *)command);

  FILE *pipe = CODEIQ_POPEN(wrapped, "r");
  free(wrapped);
  if (pipe == NULL) {
    result[0] = codeiq_make_bytes_from_cstr("127");
    result[1] = codeiq_make_bytes_from_cstr("");
    result[2] = codeiq_make_bytes_from_cstr("failed to start process");
    return result;
  }

  size_t cap = 4096;
  size_t len = 0;
  char *buffer = (char *)malloc(cap);
  if (buffer == NULL) {
    CODEIQ_PCLOSE(pipe);
    result[0] = codeiq_make_bytes_from_cstr("127");
    result[1] = codeiq_make_bytes_from_cstr("");
    result[2] = codeiq_make_bytes_from_cstr("failed to allocate output buffer");
    return result;
  }

  int c = 0;
  while ((c = fgetc(pipe)) != EOF) {
    if (len + 1 >= cap) {
      cap *= 2;
      char *next = (char *)realloc(buffer, cap);
      if (next == NULL) {
        free(buffer);
        CODEIQ_PCLOSE(pipe);
        result[0] = codeiq_make_bytes_from_cstr("127");
        result[1] = codeiq_make_bytes_from_cstr("");
        result[2] = codeiq_make_bytes_from_cstr("failed to grow output buffer");
        return result;
      }
      buffer = next;
    }
    buffer[len++] = (char)c;
  }
  buffer[len] = '\0';

  int status = CODEIQ_PCLOSE(pipe);
  int exit_code = status;
#ifndef _WIN32
  if (WIFEXITED(status)) {
    exit_code = WEXITSTATUS(status);
  }
#endif

  char exit_buf[32];
  snprintf(exit_buf, sizeof(exit_buf), "%d", exit_code);

  result[0] = codeiq_make_bytes_from_cstr(exit_buf);
  result[1] = codeiq_make_bytes_from_cstr(buffer);
  result[2] = codeiq_make_bytes_from_cstr("");

  free(buffer);
  return result;
}
