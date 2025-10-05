/*
 * mailmessage - Bash loadable builtin version
 * Extracts email message body (everything after the first blank line)
 */

/*
   This file is part of the mailmessage bash loadable builtin.

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

/* Core extraction function */
static int extract_message(const char *filename, FILE *output) {
    FILE *file;
    char *line = NULL;
    size_t line_cap = 0;
    ssize_t line_len;
    int found_blank = 0;

    file = fopen(filename, "r");
    if (!file) {
        builtin_error("%s: cannot open: %s", filename, strerror(errno));
        return EXECUTION_FAILURE;
    }

    /* Skip header section - read until blank line */
    while ((line_len = getline(&line, &line_cap, file)) != -1) {
        QUIT;  /* Check for signals */

        if (is_blank_line(line)) {
            found_blank = 1;
            break;
        }
    }

    /* Output everything after the blank line (the message body) */
    if (found_blank) {
        while ((line_len = getline(&line, &line_cap, file)) != -1) {
            QUIT;  /* Check for signals */

            process_line(line);
            fprintf(output, "%s", line);
        }
    }

    free(line);
    fclose(file);

    return EXECUTION_SUCCESS;
}

/* Bash builtin entry point */
int
mailmessage_builtin(WORD_LIST *list)
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

    r = extract_message(v[1], stdout);

    free(v);
    return r;
}

/* Documentation strings */
char *mailmessage_doc[] = {
    "Extract email message body from a file.",
    " ",
    "Read the specified FILE and display the email message body (everything",
    "after the first blank line). The headers section is skipped.",
    " ",
    "Exit Status:",
    "Returns success unless the file cannot be opened or read.",
    (char *)NULL
};

/* Builtin metadata structure */
struct builtin mailmessage_struct = {
    "mailmessage",           /* builtin name */
    mailmessage_builtin,     /* function implementing builtin */
    BUILTIN_ENABLED,         /* initial flags for builtin */
    mailmessage_doc,         /* array of long documentation strings */
    "mailmessage FILE",      /* usage synopsis */
    0                        /* reserved for internal use */
};
