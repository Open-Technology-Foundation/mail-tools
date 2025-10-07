/*
mailmessage - extract email message body
Extracts email message body (everything after the first blank line)
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

static void usage(const char *progname) {
    printf("Usage: %s FILE\n", progname);
    printf("Extract email message body from FILE (after first blank line)\n");
}

int main(int argc, const char* argv[]) {
    FILE *file;
    char *line = NULL;
    size_t line_cap = 0;
    ssize_t line_len;
    int found_blank = 0;

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

    /* Skip header section - read until blank line */
    while ((line_len = getline(&line, &line_cap, file)) != -1) {
        if (is_blank_line(line)) {
            found_blank = 1;
            break;
        }
    }

    /* Output everything after the blank line (the message body) */
    if (found_blank) {
        while ((line_len = getline(&line, &line_cap, file)) != -1) {
            process_line(line);
            printf("%s", line);
        }
    }

    free(line);
    fclose(file);
    return 0;
}
