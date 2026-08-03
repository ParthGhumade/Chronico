# Chronico V0 -- Product Requirements Document (PRD)

## Overview

**Project:** Chronico **Version:** V0 (Single User MVP)

Chronico is an AI-powered phone app that converts rough
Marathi event notes and optional photos into formal school event reports
and exports them as PDFs.

## Problem

Teachers spend 30--60 minutes manually preparing school event reports.
Chronico reduces this to under 5 minutes.

## Goals

-   High-quality formal Marathi reports
-   Minimal user input
-   Factual accuracy
-   Editable output
-   PDF export

## Non-Goals

-   Authentication
-   Multi-user support
-   Multi-school support
-   Cloud sync
-   YouTube integration
-   Social media generation
-   DOCX export

## Target User

Single teacher/administrator using the application.

## User Flow

### First Launch

One-time setup: - School Name - School Address - Principal /
Headmaster - Default Signatory - School Logo (optional)

### Create Event

-   Event Name
-   Event Date
-   Category
-   Venue (optional)

### Upload Photos

Optional supporting evidence.

### Narration

Large text box. User types or uses Gboard Marathi Voice Typing.

## AI Pipeline

### Shared Context

Contains: - School Profile - Event Details - Narration - Photos

### Agent 1 --- Writer

Generates the complete Marathi report.

### Agent 2 --- Verifier

Checks: - Hallucinations - Missing facts - Wrong names - Wrong dates -
Contradictions

If issues exist, returns structured feedback to Writer. Maximum retries:
3.

### Agent 3 --- Critic

Improves: - Grammar - Official Marathi style - Readability - Formatting

Must not change facts.

### Agent 4 --- PDF Renderer

Uses ReportLab to: - Render title - Render report - Insert images -
Export PDF

## Data

### Settings

-   School Name
-   Address
-   Principal
-   Signatory
-   Logo

### Event

-   Title
-   Date
-   Category
-   Venue
-   Narration
-   Photos
-   Report
-   PDF Path

## Functional Requirements

-   Save school settings locally
-   Create unlimited events
-   Accept Marathi narration
-   Generate formal Marathi reports
-   Verify factual consistency
-   Export PDF

## Tech Stack

Frontend: Flutter

Backend: FastAPI

Database: SQLite

PDF: ReportLab

LLM: GPT or equivalent Marathi-capable model

## Future

### V1

-   User feedback loop
-   Better OCR
-   DOCX export

### V2

-   Authentication
-   Multiple schools
-   YouTube metadata generation
-   Social media posts

### V3

-   Event workspace
-   Annual report generation
-   Collaboration
