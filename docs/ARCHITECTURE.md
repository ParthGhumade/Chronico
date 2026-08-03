# Chronico V0 -- Architecture

## Overview

Chronico V0 is a single-user AI pipeline that transforms rough Marathi
event narration and optional photos into a polished, printable PDF
report.

The system follows a sequential pipeline. Every AI component operates on
the same immutable context object to keep behavior predictable and easy
to debug.

------------------------------------------------------------------------

# High-Level Architecture

``` text
                 User Input
        ┌───────────────────────────┐
        │ School Settings           │
        │ Event Details             │
        │ Photos (optional)         │
        │ Narration                 │
        └─────────────┬─────────────┘
                      │
                      ▼
              Context Builder
                      │
                      ▼
               Shared Context
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
      Writer      Verifier     Critic
          │           ▲           │
          └────Retry──┘           │
              (max 3)             │
                      ▼
                 Final Report
                      │
                      ▼
                PDF Renderer
                      │
                      ▼
               Download PDF
```

------------------------------------------------------------------------

# Components

## Frontend (Flutter)

Responsibilities: - One-time school setup - Event creation - Photo
upload - Narration input - Report preview - PDF download

------------------------------------------------------------------------

## Backend (FastAPI)

Responsibilities: - Build context - Orchestrate AI pipeline - Manage
retry loop - Generate PDF - Persist events/settings

------------------------------------------------------------------------

## Database (SQLite)

### settings

-   school_name
-   address
-   principal
-   signatory
-   logo_path

### events

-   id
-   title
-   date
-   category
-   venue
-   narration
-   report
-   pdf_path
-   created_at

------------------------------------------------------------------------

# Shared Context

Every agent receives the same context.

``` json
{
  "school": {},
  "event": {},
  "photos": [],
  "narration": "",
  "draft": null
}
```

Only the `draft` field changes throughout the pipeline.

------------------------------------------------------------------------

# Agent Specifications

## Agent 1 --- Writer

### Input

-   Shared Context

### Responsibilities

-   Understand narration
-   Use school presets
-   Generate a complete formal Marathi report

### Output

-   Draft report

The writer should prioritize factual completeness over perfect wording.

------------------------------------------------------------------------

## Agent 2 --- Verifier

### Input

-   Shared Context
-   Draft report

### Responsibilities

Validate the report against the original inputs.

Checks include: - Missing activities - Missing people - Wrong dates -
Wrong names - Hallucinated facts - Logical inconsistencies

### Output

If valid:

``` json
{"status":"approved"}
```

Otherwise:

``` json
{
  "status":"retry",
  "issues":[
    "Missing prize distribution.",
    "Incorrect chief guest name."
  ]
}
```

The verifier never rewrites the report.

------------------------------------------------------------------------

## Retry Loop

Maximum iterations: **3**

``` text
Writer
   ↓
Verifier
   │
Approved?
   │
No
   │
Feedback
   │
Writer
```

If verification still fails after three attempts: - Return the best
draft - Surface verification warnings to the UI

------------------------------------------------------------------------

## Agent 3 --- Critic

### Input

-   Verified report

### Responsibilities

-   Grammar
-   Official Marathi tone
-   Paragraph flow
-   Formatting
-   Readability

### Constraints

Must not modify: - Names - Dates - Numerical values - Event facts

------------------------------------------------------------------------

## Agent 4 --- PDF Renderer

This is **not** an AI agent.

Uses ReportLab to: - Render school header - Title - Report body -
Uploaded images - Footer/page numbers (future)

Output: - Printable PDF

------------------------------------------------------------------------

# Storage

    data/
        settings.db

    uploads/
        photos/

    generated/
        reports/

------------------------------------------------------------------------

# Error Handling

## Missing Information

If required information is absent: - Continue generation - Mark
uncertain sections - Allow later editing

## AI Failure

If an LLM request fails: - Retry once - Return a meaningful error to the
frontend

## PDF Failure

Keep the generated report. Allow PDF regeneration.

------------------------------------------------------------------------

# Future Extensions

## V1

-   User correction loop
-   DOCX export
-   Better OCR

## V2

-   Authentication
-   Multi-school support
-   YouTube metadata generation
-   Social media outputs

## V3

-   Multiple specialized output agents
-   Annual report compilation
-   Event workspace
-   Cloud synchronization
