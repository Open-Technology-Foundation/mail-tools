/*
mailheader - refactored version
Extracts email headers (everything up to first blank line) with improved performance
*/
#define _GNU_SOURCE
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>

static void process_line(char *line) {
    char *src = line, *dst = line;

    while (*src) {
        if (*src == '\r') {
            src++;
            continue;
        }
        if (*src == '\t') {
            *dst++ = ' ';
            src++;
            continue;
        }
        *dst++ = *src++;
    }
    *dst = '\0';
}

static int is_blank_line(const char *line) {
    while (*line) {
        if (*line == '\n') return 1;
        if (!isspace((unsigned char)*line)) return 0;
        line++;
    }
    return 1;
}

static int is_continuation_line(const char *line) {
    return (line[0] == ' ' || line[0] == '\t');
}

static void usage(const char *progname) {
    printf("Usage: %s FILE\n", progname);
    printf("Extract email headers from FILE (up to first blank line)\n");
}

int main(int argc, const char* argv[]) {
    FILE *file;
    char *line = NULL;
    char *next_line = NULL;
    size_t line_cap = 0, next_line_cap = 0;
    ssize_t line_len, next_line_len;
    int in_headers = 1;

    if (argc == 2 && (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)) {
        usage(argv[0]);
        return 0;
    }

    if (argc != 2) {
        fprintf(stderr, "%s: no args\n", argv[0]);
        return 2;
    }

    file = fopen(argv[1], "r");
    if (!file) {
        fprintf(stderr, "\n%s: %s could not be opened!\n", argv[0], argv[1]);
        return 1;
    }

    line_len = getline(&line, &line_cap, file);

    while (in_headers && line_len != -1) {
        if (is_blank_line(line)) {
            break;
        }

        process_line(line);

        next_line_len = getline(&next_line, &next_line_cap, file);

        if (next_line_len != -1 && is_continuation_line(next_line)) {
            line[strlen(line) - 1] = '\0';
            printf("%s", line);
        } else {
            printf("%s", line);
        }

        char *temp = line;
        line = next_line;
        next_line = temp;

        size_t temp_cap = line_cap;
        line_cap = next_line_cap;
        next_line_cap = temp_cap;

        line_len = next_line_len;
    }

    free(line);
    free(next_line);
    fclose(file);
    return 0;
}