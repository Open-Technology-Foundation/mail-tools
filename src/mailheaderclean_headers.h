/*
mailheaderclean_headers.h - Shared header removal list

This file contains the hardcoded list of non-essential email headers
to be removed by mailheaderclean. It is shared between the standalone
binary (mailheaderclean.c) and the bash loadable builtin (mailheaderclean_loadable.c).

To modify the removal list, edit this file only - both implementations
will automatically use the updated list.
*/

#ifndef MAILHEADERCLEAN_HEADERS_H
#define MAILHEADERCLEAN_HEADERS_H

/* Hardcoded list of headers to remove
 *
 * This list has been optimized using wildcard patterns to reduce
 * maintenance burden while maintaining identical functionality.
 *
 * Wildcards use shell glob syntax (fnmatch):
 *   X-MS-*        matches all X-MS- headers
 *   List-*        matches all List- headers
 *   X-Spam-*      matches all X-Spam- headers
 *
 * Original count: 207 headers
 * Optimized count: ~60 entries (wildcards + individual headers)
 */
static const char *HEADERS_TO_REMOVE[] = {
    /* Microsoft Exchange / Office365 bloat (was 32 individual headers) */
    "X-MS-*",                /* All X-MS-Exchange-*, X-MS-Office365-*, X-MS-Has-Attach, etc. */
    "X-Microsoft-*",         /* All X-Microsoft-Antispam* headers */
    "X-Forefront-*",         /* All X-Forefront-Antispam-Report* headers */
    "X-ClientProxiedBy",
    "X-EOPAttributedMessage",
    "msip_labels",
    "Thread-Index",
    "Thread-Topic",
    "Deferred-Delivery",

    /* ARC email forwarding validation (was 3 headers) */
    "ARC-*",                 /* ARC-Authentication-Results, ARC-Message-Signature, ARC-Seal */
    "Authentication-Results*", /* authentication-results, Authentication-Results-Original */
    "auto-submitted",

    /* Organization tracking */
    "X-OriginatorOrg",
    "Organization",
    "X-Organization",
    "X-Country",

    /* Client preferences */
    "Accept-Language",
    "Content-Language",

    /* Email client/software identification */
    "X-Mailer",
    "User-Agent",
    "X-Mailer-Version",
    "X-MimeOLE",
    "X-MSMail-Priority",

    /* Priority/importance */
    "X-Priority",
    "Importance",
    "Priority",
    "Precedence",

    /* Tracking/receipts */
    "Disposition-Notification-To",
    "X-Confirm-Reading-To",
    "Return-Receipt-To",
    "X-Auto-Response-Suppress",

    /* Security vendors - consolidated with wildcards (was 47 individual headers) */
    "X-Proofpoint-*",        /* Proofpoint (4 headers) */
    "X-Mimecast-*",          /* Mimecast (4 headers) */
    "X-IronPort-*",          /* IronPort (3 headers) */
    "X-Barracuda-*",         /* Barracuda (4 headers) */
    "X-Sophos-*",            /* Sophos (8 headers) */
    "X-LASED-*",             /* LASED spam filter (6 headers) */
    "X-Spampanel-*",         /* Spampanel (4 headers) */
    "X-YourOrg-MailScanner*", /* MailScanner (5 headers) */
    "X-TM-AS-*",             /* Trend Micro (2 headers) */
    "X-Sonic*",              /* Sonic (3 headers: X-SONIC-DKIM-SIGN, X-Sonic-ID, X-Sonic-MF) */
    "X-FireEye",
    "X-Amavis-Modified",
    "X-AntiAbuse",
    "X-Antivirus",
    "X-Antivirus-Status",
    "X-Virus-Scanned",

    /* Email providers - consolidated (was 18 headers) */
    "X-Google*",             /* Google (X-Google-*, X-GoogleForms-*) */
    "X-Gm-*",                /* Gmail specific (4 headers) */
    "X-Yahoo-*",             /* Yahoo (2 headers) */
    "X-YMail-*",             /* Yahoo Mail (2 headers) */
    "X-AOL-*",               /* AOL (2 headers) */

    /* Mailing list headers (was 10 headers) */
    "List-*",                /* List-Id, List-Unsubscribe, List-Post, List-Help, etc. */
    "X-BeenThere",
    "X-Mailman-Version",

    /* Sender tracking */
    "X-Originating-IP",
    "X-Sender-IP",
    "X-Get-Message-Sender-Via",
    "X-Originating-Email",
    "X-Authenticated-Sender",
    "X-Sender",
    "X-IP",

    /* Cloud security / filtering services (was 10 headers) */
    "X-cloud-security*",     /* All X-cloud-security variants (7 headers) */
    "X-CMAE-*",              /* X-CMAE-Analysis, X-CMAE-Envelope */
    "X-Greylist",

    /* Tracking services (was 4 headers) */
    "X-CodeTwo*",            /* X-CodeTwo-MessageID, X-CodeTwoProcessed */

    /* Service provider / hosting metadata */
    "X-AliDM-RcptTo",
    "X-Postal-MsgID",
    "X-PPE-TRUSTED",
    "X-PPP-*",               /* X-PPP-Message-ID, X-PPP-Vhost */
    "X-SECURESERVER-ACCT",
    "X-SG-EID",
    "X-RSMIdSession",

    /* Message tracking/identification */
    "X-Entity-ID",
    "X-EnvId",
    "X-Filter-ID",
    "X-MDID*",               /* X-MDID, X-MDID-O */
    "Feedback-ID",
    "X-Forwarded-Encrypted",
    "X-Received",
    "X-Recommended-Action",
    "X-Report-Abuse-To",
    "X-Source*",             /* X-Source, X-Source-Args, X-Source-Dir */

    /* Obsolete/rarely used RFC headers (was 10 headers) */
    "Comments",
    "Keywords",
    "Resent-*",              /* Resent-From, Resent-Date, Resent-To, Resent-Message-ID, Resent-Sender */
    "Status",
    "X-Status",
    "X-UID",

    /* Post-delivery metadata */
    "Delivered-To",
    "Return-Path",
    "X-Original-To",

    /* Authentication signatures */
    "DKIM-Signature",
    "DKIM-Filter",
    "Received-SPF",

    /* Spam filtering metadata (was 7 headers) */
    "X-Spam-*",              /* X-Spam-Checker-Version, X-Spam-Status, X-Spam-Flag, etc. */

    NULL  /* sentinel */
};

#endif /* MAILHEADERCLEAN_HEADERS_H */
