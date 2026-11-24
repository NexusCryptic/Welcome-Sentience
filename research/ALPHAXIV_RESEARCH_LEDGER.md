# AlphaXiv Research Ledger — GAIA / NEXUS

**Ledger ID:** TDOC-GAIA-ALPHAXIV-LEDGER-0001  
**Discovery date:** 2026-11-24  
**Purpose:** Publicly verifiable research references for review against GAIA/NEXUS engineering claims.

## Acceptance policy

AlphaXiv is the discovery and review surface. Discovery does not itself constitute project endorsement. Each paper remains a **candidate reference** until a reviewer has read the paper, identified the exact claim it supports, assessed limitations, and recorded an explicit acceptance decision. Do not cite a paper as proof of a project implementation or production capability merely because it is listed here.

## Candidate references

| Paper | Topic relevance | State |
|---|---|---|
| [CPM-LDPC Codes Attaining the Minimum-Distance Bound](https://www.alphaxiv.org/abs/2609.16836) · arXiv:2609.16836 · 2026-09-15 | QC-LDPC construction and minimum-distance properties | Candidate — review required |
| [Non-binary LDPC codes for Data Storage](https://www.alphaxiv.org/abs/2605.08500) · arXiv:2605.08500 · 2026-05-08 | Non-binary LDPC codes and comparison with MDS / Reed–Solomon methods | Candidate — review required |
| [Why No Consensus on Consensus? A Deep Dive into Blockchain Consensus Protocols](https://www.alphaxiv.org/abs/2603.08629) · arXiv:2603.08629 · 2026-03-09 | Comparative blockchain consensus protocol survey | Candidate — review required |
| [Would Learning Help? Adaptive CRC-QC-LDPC Selection for Integrity in 5G-NR V2X](https://www.alphaxiv.org/abs/2604.04277) · arXiv:2604.04277 · 2026-04-05 | Adaptive CRC/QC-LDPC selection and communication integrity | Candidate — review required |
| [Explicit Reed-Solomon Subspace Designs: Optimal List and Line Decoding](https://www.alphaxiv.org/abs/2610.36215) · arXiv:2610.36215 · 2026-10-26 | Reed–Solomon list-decoding constructions and bounds | Candidate — review required |

## Review record template

For each paper, record:
- canonical paper ID and URL;
- reviewer and review date;
- exact proposition, method, or empirical result relied upon;
- assumptions, limitations, and reproducibility notes;
- linked GAIA/NEXUS implementation, test, or design decision;
- disposition: accepted for a named claim, reference only, rejected, or superseded.

## Provenance

Initial candidates were returned by AlphaXiv paper discovery on 2026-11-24 using the project terms HCCGN, QC-LDPC, Reed-Solomon, distributed consensus, and Koopman dynamics. Titles, identifiers, and publication dates should be checked against the canonical paper records before a formal acceptance decision.

**Integrity boundary:** a public paper record establishes a traceable research source, not the truth of every claim in it and not correctness of any GAIA/NEXUS implementation.

## LaTeX and computational-publication integration

The five candidate references are represented in the publication's BibTeX file at `living-system/manuscript/references.bib`, linked from the LaTeX manuscript, and retained as clickable AlphaXiv URLs. This is a bibliographic integration layer; it does not alter, mirror, or reproduce the papers themselves. Their disposition remains **candidate — review required** until a reviewer records a claim-specific decision.

The publication pipeline converts reviewed Markdown blocks to LaTeX, compiles mathematical blocks, generates a hyperlinked index from block terms, places editorial annotations in the page margin, and embeds the exact JSONL ledger, manuscript, bibliography, and HTMX editorial companion as PDF attachments. HTMX runs in the browser companion, not inside a conventional PDF page.
