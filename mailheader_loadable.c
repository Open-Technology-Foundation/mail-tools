/*
 * mailheader - Bash loadable builtin version
 * Extracts email headers (everything up to first blank line)
 */

/*
   This file is part of the mailheader bash loadable builtin.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include <errno.h>

#include "builtins.h"
#include "shell.h"

/* External function declarations */
extern char **make_builtin_argv();
extern void builtin_usage();
extern void builtin_error();

/* Helper function: process a line (remove \r, convert \t to space) */
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

/* Helper function: check if a line is blank */
static int is_blank_line(const char *line) {
    while (*line) {
        if (*line == '\n') return 1;
        if (!isspace((unsigned char)*line)) return 0;
        line++;
    }
    return 1;
}

/* Helper function: check if a line is a continuation line */
static int is_continuation_line(const char *line) {
    return (line[0] == ' ' || line[0] == '\t');
}

/* Core extraction function */
static int extract_headers(const char *filename, FILE *output) {
    FILE *file;
    char *line = NULL;
    char *next_line = NULL;
    size_t line_cap = 0, next_line_cap = 0;
    ssize_t line_len, next_line_len;
    int in_headers = 1;

    file = fopen(filename, "r");
    if (!file) {
        builtin_error("%s: cannot open: %s", filename, strerror(errno));
        return EXECUTION_FAILURE;
    }

    line_len = getline(&line, &line_cap, file);

    while (in_headers && line_len != -1) {
        QUIT;  /* Check for signals */

        if (is_blank_line(line)) {
            break;
        }

        process_line(line);

        next_line_len = getline(&next_line, &next_line_cap, file);

        if (next_line_len != -1 && is_continuation_line(next_line)) {
            line[strlen(line) - 1] = '\0';
            fprintf(output, "%s", line);
        } else {
            fprintf(output, "%s", line);
        }

        /* Swap line buffers */
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

    return EXECUTION_SUCCESS;
}

/* Bash builtin entry point */
int
mailheader_builtin(WORD_LIST *list)
{
    char **v;
    int c, r;

    /* Convert WORD_LIST to argc/argv */
    v = make_builtin_argv(list, &c);

    if (c != 2) {
        builtin_usage();
        free(v);
        return EX_USAGE;
    }

    QUIT;  /* Check for signals */

    r = extract_headers(v[1], stdout);

    free(v);
    return r;
}

/* Documentation strings */
char *mailheader_doc[] = {
    "Extract email headers from a file.",
    " ",
    "Read the specified FILE and display email headers (everything up to",
    "the first blank line). Continuation lines (starting with whitespace)",
    "are joined with the previous line.",
    " ",
    "Exit Status:",
    "Returns success unless the file cannot be opened or read.",
    (char *)NULL
};

/* Builtin metadata structure */
struct builtin mailheader_struct = {
    "mailheader",           /* builtin name */
    mailheader_builtin,     /* function implementing builtin */
    BUILTIN_ENABLED,        /* initial flags for builtin */
    mailheader_doc,         /* array of long documentation strings */
    "mailheader FILE",      /* usage synopsis */
    0                       /* reserved for internal use */
};
