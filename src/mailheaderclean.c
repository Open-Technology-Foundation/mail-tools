/*
mailheaderclean - filter non-essential email headers
Removes bloat headers while preserving essential routing information
*/
#define _GNU_SOURCE
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>

/* Include shared header removal list */
#include "mailheaderclean_headers.h"

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

/* Check if header should be removed */
static int should_remove_header(const char *header, char **removal_list, int removal_count) {
    int i;

    /* Check removal list */
    for (i = 0; i < removal_count; i++) {
        if (strcasecmp_custom(header, removal_list[i]) == 0) {
            return 1;
        }
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

/* Build the final removal list based on environment variables */
static int build_removal_list(char ***removal_list) {
    char **base_list = NULL;
    int base_count = 0;
    char **preserve_list = NULL;
    int preserve_count = 0;
    char **extra_list = NULL;
    int extra_count = 0;
    int i, j, k;
    int found;

    /* Step 1: Get base removal list */
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

    /* Step 2: Parse preserve list and remove from base */
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

    /* Step 3: Parse extra list and add to base (if not already present) */
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

static void usage(const char *progname) {
    printf("Usage: %s FILE\n", progname);
    printf("Filter non-essential email headers from FILE\n");
    printf("\nEnvironment variables:\n");
    printf("  MAILHEADERCLEAN          Replace built-in removal list\n");
    printf("  MAILHEADERCLEAN_PRESERVE Exclude headers from removal\n");
    printf("  MAILHEADERCLEAN_EXTRA    Add headers to removal list\n");
}

int main(int argc, const char* argv[]) {
    FILE *file;
    char *line = NULL;
    size_t line_cap = 0;
    ssize_t line_len;
    int in_headers = 1;
    int keep_current_header = 1;
    int first_received_seen = 0;
    char **removal_list = NULL;
    int removal_count = 0;

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

    /* Build removal list from environment variables */
    removal_count = build_removal_list(&removal_list);

    while ((line_len = getline(&line, &line_cap, file)) != -1) {
        if (in_headers) {
            /* Check for end of headers */
            if (is_blank_line(line)) {
                in_headers = 0;
                printf("%s", line);  /* Output blank line separator */
                continue;
            }

            /* Check for continuation line */
            if (is_continuation_line(line)) {
                if (keep_current_header) {
                    process_line(line);
                    printf("%s", line);
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
                        printf("%s", line);
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
                    printf("%s", line);
                }
            } else {
                /* Not a valid header line, output as-is */
                process_line(line);
                printf("%s", line);
            }
        } else {
            /* In body section - output everything unchanged */
            printf("%s", line);
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
    return 0;
}
