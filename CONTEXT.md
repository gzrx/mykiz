# MyKIZ — Glossary

## Actors

| Term | Definition |
|------|-----------|
| **Student** | A KIZ Resident — a UKM student who has been assigned accommodation at Kolej Ibu Zain for a given academic session. Identified by their Matric Number (e.g., `A123456`). |
| **Admin** | A KIZ office staff member with unrestricted access to all administrative features. Identified by their Staff ID (e.g., `S98765`). |

## Domain Concepts

| Term | Definition |
|------|-----------|
| **KIZ** | Kolej Ibu Zain — a premium residential college at Universiti Kebangsaan Malaysia (UKM). |
| **Matric Number** | The unique student identifier issued by UKM, used as the Student's login credential. Format: letter followed by digits (e.g., `A123456`). |
| **Staff ID** | The unique staff identifier used as the Admin's login credential. Format: letter `S` followed by digits (e.g., `S98765`). |
| **Announcement** | A broadcast message created by any Admin, visible to all Students. Has a title, body, and creation date. No draft state — published immediately upon creation. Soft-deleted (hidden from all users but preserved in database). |
| **Complaint** | A facility issue report submitted by a Student. Contains a text description, a free-text location, and an optional image (max 5 MB, JPEG/PNG). Follows a strict forward-only lifecycle: `submitted → in_progress → resolved`. Immutable after submission — only Admin can advance the status. |
| **Complaint Status** | A linear progression: `submitted` (initial, set on creation) → `in_progress` (Admin acknowledges) → `resolved` (issue fixed). No backward transitions, no rejection, no cancellation. |
