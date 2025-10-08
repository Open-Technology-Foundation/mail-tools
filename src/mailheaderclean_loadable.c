/*
 * mailheaderclean - Bash loadable builtin version
 * Filters non-essential email headers while preserving routing information
 */

/*
   This file is part of the mailheaderclean bash loadable builtin.

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
#include <fnmatch.h>

#include "builtins.h"
#include "shell.h"

/* External function declarations */
extern char **make_builtin_argv();
extern void builtin_usage();
extern void builtin_error();

/* Include shared header removal list */
#include "mailheaderclean_headers.h"

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

/* Case-insensitive string comparison */
static int strcasecmp_custom(const char *s1, const char *s2) {
    while (*s1 && *s2) {
        int c1 = tolower((unsigned char)*s1);
        int c2 = tolower((unsigned char)*s2);
        if (c1 != c2) return c1 - c2;
        s1++;
        s2++;
    }
    return tolower((unsigned char)*s1) - tolower((unsigned char)*s2);
}

/* Check if header should be removed
 * Supports wildcard patterns using shell glob syntax:
 *   X-*         matches any header starting with X-
 *   *-Status    matches any header ending with -Status
 *   X-MS-*      matches any header starting with X-MS-
 *   X-*-Status  matches X- followed by anything, ending in -Status
 */
static int should_remove_header(const char *header, char **removal_list, int removal_count) {
    int i;

    /* Check removal list with wildcard support */
    for (i = 0; i < removal_count; i++) {
        /* Use fnmatch for glob pattern matching (case-insensitive) */
#ifdef FNM_CASEFOLD
        /* GNU extension for case-insensitive matching */
        if (fnmatch(removal_list[i], header, FNM_CASEFOLD) == 0) {
            return 1;
        }
#else
        /* Fallback: convert both to lowercase for comparison */
        char pattern_lower[256], header_lower[256];
        const char *p_src = removal_list[i];
        const char *h_src = header;
        char *p_dst = pattern_lower;
        char *h_dst = header_lower;

        while (*p_src && p_dst < pattern_lower + 255) {
            *p_dst++ = tolower((unsigned char)*p_src++);
        }
        *p_dst = '\0';

        while (*h_src && h_dst < header_lower + 255) {
            *h_dst++ = tolower((unsigned char)*h_src++);
        }
        *h_dst = '\0';

        if (fnmatch(pattern_lower, header_lower, 0) == 0) {
            return 1;
        }
#endif
    }

    return 0;
}

/* Parse comma-separated header list from a string */
static int parse_csv_headers(const char *csv_string, char ***headers) {
    if (!csv_string || !*csv_string) {
        *headers = NULL;
        return 0;
    }

    /* Count headers (comma-separated) */
    int count = 1;
    const char *p = csv_string;
    while (*p) {
        if (*p == ',') count++;
        p++;
    }

    /* Allocate array */
    *headers = malloc(count * sizeof(char *));
    if (!*headers) return 0;

    /* Parse headers */
    char *env_copy = strdup(csv_string);
    if (!env_copy) {
        free(*headers);
        return 0;
    }

    int i = 0;
    char *token = strtok(env_copy, ",");
    while (token && i < count) {
        /* Trim whitespace */
        while (isspace((unsigned char)*token)) token++;
        char *end = token + strlen(token) - 1;
        while (end > token && isspace((unsigned char)*end)) *end-- = '\0';

        (*headers)[i++] = strdup(token);
        token = strtok(NULL, ",");
    }

    free(env_copy);
    return i;
}

/* Build the final removal list based on environment variables
 *
 * Processing order:
 *   1. MAILHEADERCLEAN (or built-in hardcoded list if not set) - establishes base
 *   2. MAILHEADERCLEAN_PRESERVE - removes headers from base (subtract)
 *   3. MAILHEADERCLEAN_EXTRA - adds headers to final list (add)
 *
 * Formula: (MAILHEADERCLEAN or built-in) - PRESERVE + EXTRA
 */
static int build_removal_list(char ***removal_list) {
    char **base_list = NULL;
    int base_count = 0;
    char **preserve_list = NULL;
    int preserve_count = 0;
    char **extra_list = NULL;
    int extra_count = 0;
    int i, j, k;
    int found;

    /* Step 1: Get base removal list (MAILHEADERCLEAN or hardcoded) */
    char *env_mailheaderclean = getenv("MAILHEADERCLEAN");
    if (env_mailheaderclean && *env_mailheaderclean) {
        /* Use custom removal list from environment */
        base_count = parse_csv_headers(env_mailheaderclean, &base_list);
    } else {
        /* Use hardcoded list - count items first */
        for (i = 0; HEADERS_TO_REMOVE[i] != NULL; i++) {
            base_count++;
        }
        /* Copy hardcoded list to dynamic array */
        base_list = malloc(base_count * sizeof(char *));
        if (!base_list) return 0;
        for (i = 0; i < base_count; i++) {
            base_list[i] = strdup(HEADERS_TO_REMOVE[i]);
        }
    }

    /* Step 2: Parse preserve list and remove from base (MAILHEADERCLEAN_PRESERVE) */
    char *env_preserve = getenv("MAILHEADERCLEAN_PRESERVE");
    if (env_preserve && *env_preserve) {
        preserve_count = parse_csv_headers(env_preserve, &preserve_list);

        /* Remove preserved headers from base list */
        for (i = 0; i < preserve_count; i++) {
            for (j = 0; j < base_count; j++) {
                if (base_list[j] && strcasecmp_custom(preserve_list[i], base_list[j]) == 0) {
                    free(base_list[j]);
                    base_list[j] = NULL;  /* Mark as removed */
                }
            }
        }

        /* Cleanup preserve list */
        for (i = 0; i < preserve_count; i++) {
            free(preserve_list[i]);
        }
        free(preserve_list);
    }

    /* Step 3: Parse extra list and add to base (MAILHEADERCLEAN_EXTRA) */
    char *env_extra = getenv("MAILHEADERCLEAN_EXTRA");
    if (env_extra && *env_extra) {
        extra_count = parse_csv_headers(env_extra, &extra_list);
    }

    /* Compact base list (remove NULLs) and prepare for extra additions */
    int final_count = 0;
    for (i = 0; i < base_count; i++) {
        if (base_list[i]) final_count++;
    }
    final_count += extra_count;  /* Reserve space for extras */

    *removal_list = malloc(final_count * sizeof(char *));
    if (!*removal_list) {
        /* Cleanup on error */
        for (i = 0; i < base_count; i++) {
            if (base_list[i]) free(base_list[i]);
        }
        free(base_list);
        for (i = 0; i < extra_count; i++) {
            free(extra_list[i]);
        }
        free(extra_list);
        return 0;
    }

    /* Copy non-NULL entries from base */
    k = 0;
    for (i = 0; i < base_count; i++) {
        if (base_list[i]) {
            (*removal_list)[k++] = base_list[i];
        }
    }
    free(base_list);  /* Free the old array, but not the strings (they're copied to removal_list) */

    /* Add extra headers if not already in list */
    for (i = 0; i < extra_count; i++) {
        found = 0;
        for (j = 0; j < k; j++) {
            if (strcasecmp_custom(extra_list[i], (*removal_list)[j]) == 0) {
                found = 1;
                break;
            }
        }
        if (!found) {
            (*removal_list)[k++] = extra_list[i];
        } else {
            free(extra_list[i]);  /* Already in list, don't need duplicate */
        }
    }
    free(extra_list);  /* Free the array */

    return k;  /* Return actual count */
}

/* Core filtering function */
static int filter_headers(const char *filename, FILE *output) {
    FILE *file;
    char *line = NULL;
    size_t line_cap = 0;
    ssize_t line_len;
    int in_headers = 1;
    int keep_current_header = 1;
    int first_received_seen = 0;
    char **removal_list = NULL;
    int removal_count = 0;

    file = fopen(filename, "r");
    if (!file) {
        builtin_error("%s: cannot open: %s", filename, strerror(errno));
        return EXECUTION_FAILURE;
    }

    /* Build removal list from environment variables */
    removal_count = build_removal_list(&removal_list);

    while ((line_len = getline(&line, &line_cap, file)) != -1) {
        QUIT;  /* Check for signals */

        if (in_headers) {
            /* Check for end of headers */
            if (is_blank_line(line)) {
                in_headers = 0;
                fprintf(output, "%s", line);  /* Output blank line separator */
                continue;
            }

            /* Check for continuation line */
            if (is_continuation_line(line)) {
                if (keep_current_header) {
                    process_line(line);
                    fprintf(output, "%s", line);
                }
                continue;
            }

            /* Extract header name */
            char header_name[256] = {0};
            const char *colon = strchr(line, ':');
            if (colon && (colon - line) < 255) {
                strncpy(header_name, line, colon - line);
                header_name[colon - line] = '\0';

                /* Special case: Received header - keep only first */
                if (strcasecmp_custom(header_name, "Received") == 0) {
                    if (!first_received_seen) {
                        first_received_seen = 1;
                        keep_current_header = 1;
                        process_line(line);
                        fprintf(output, "%s", line);
                    } else {
                        keep_current_header = 0;
                    }
                    continue;
                }

                /* Check if this header should be removed */
                if (should_remove_header(header_name, removal_list, removal_count)) {
                    keep_current_header = 0;
                } else {
                    keep_current_header = 1;
                    process_line(line);
                    fprintf(output, "%s", line);
                }
            } else {
                /* Not a valid header line, output as-is */
                process_line(line);
                fprintf(output, "%s", line);
            }
        } else {
            /* In body section - output everything unchanged */
            fprintf(output, "%s", line);
        }
    }

    /* Cleanup */
    if (removal_list) {
        for (int i = 0; i < removal_count; i++) {
            free(removal_list[i]);
        }
        free(removal_list);
    }
    free(line);
    fclose(file);

    return EXECUTION_SUCCESS;
}

/* Bash builtin entry point */
int
mailheaderclean_builtin(WORD_LIST *list)
{
    char **v;
    int c, r;
    char **removal_list = NULL;
    int removal_count = 0;

    /* Convert WORD_LIST to argc/argv */
    v = make_builtin_argv(list, &c);

    if (c < 2) {
        builtin_usage();
        free(v);
        return EX_USAGE;
    }

    QUIT;  /* Check for signals */

    /* Handle -l option (list removal headers) */
    if (c == 2 && strcmp(v[1], "-l") == 0) {
        removal_count = build_removal_list(&removal_list);
        for (int i = 0; i < removal_count; i++) {
            printf("%s\n", removal_list[i]);
        }
        /* Cleanup */
        if (removal_list) {
            for (int i = 0; i < removal_count; i++) {
                free(removal_list[i]);
            }
            free(removal_list);
        }
        free(v);
        return EXECUTION_SUCCESS;
    }

    if (c != 2) {
        builtin_usage();
        free(v);
        return EX_USAGE;
    }

    r = filter_headers(v[1], stdout);

    free(v);
    return r;
}

/* Documentation strings */
char *mailheaderclean_doc[] = {
    "Filter non-essential email headers from a file.",
    " ",
    "Read the specified FILE and output the entire email with bloat headers",
    "removed. Preserves essential routing headers and message body.",
    " ",
    "Removes Microsoft Exchange bloat, security vendor headers, tracking",
    "headers, and other non-essential metadata. Keeps only the first",
    "Received header.",
    " ",
    "Options:",
    "  -l    List currently active header removal list and exit",
    " ",
    "Environment Variables:",
    "  MAILHEADERCLEAN        Comma-separated list to replace built-in removal list",
    "  MAILHEADERCLEAN_PRESERVE  Comma-separated list to exclude from removal",
    "  MAILHEADERCLEAN_EXTRA  Comma-separated list of additional headers to remove",
    " ",
    "Precedence: MAILHEADERCLEAN (or built-in) - PRESERVE + EXTRA",
    " ",
    "Wildcard patterns supported (shell glob syntax):",
    "  X-*         Match any header starting with X-",
    "  *-Status    Match any header ending with -Status",
    "  X-MS-*      Match any header starting with X-MS-",
    " ",
    "Exit Status:",
    "Returns success unless the file cannot be opened or read.",
    (char *)NULL
};

/* Builtin metadata structure */
struct builtin mailheaderclean_struct = {
    "mailheaderclean",           /* builtin name */
    mailheaderclean_builtin,     /* function implementing builtin */
    BUILTIN_ENABLED,             /* initial flags for builtin */
    mailheaderclean_doc,         /* array of long documentation strings */
    "mailheaderclean [-l] FILE", /* usage synopsis */
    0                            /* reserved for internal use */
};
