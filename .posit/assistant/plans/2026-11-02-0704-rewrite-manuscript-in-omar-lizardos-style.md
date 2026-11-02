# Plan: Rewriting the Manuscript in Omar Lizardo's Writing Style

## Context and Objective

The user requested a substantive rewrite of the working draft `kk-index-b-two-mode.tex` so that it aligns closely with Omar Lizardo's writing style—moving away from technical, stilted, and overly mechanical prose toward an intellectually engaging, conceptually elevated, and big-picture narrative.

Inspection of Omar Lizardo's writing samples in the mounted Google Drive (`/mnt/chromeos/GoogleDrive/MyDrive/Promotion Materials/` and `Review and Promotion Materials (Notre Dame)/`), including solo-authored articles on two-mode networks, correspondence analysis, conceptual ambiguity, and sociological theory (e.g., Lizardo 2021, 2023, 2024, 2025), reveals a very distinctive and compelling academic voice:
- **Authorial confidence and intellectual clarity**: First-person authorial framing ("In this paper, I examine...", "My central claim is...", "I argue that...").
- **Conceptual and theoretical framing**: Every empirical technique (two-mode networks, duality, maximum spanning trees, latent Dirichlet allocation) is introduced not merely as a mechanical procedure, but as an analytical lens addressing substantive questions in the sociology of culture, relational sociology, and the cognitive history of social scientific concepts.
- **Dynamic, engaging prose**: Elimination of dry data-accounting formulas ("Table 1 gives summary statistics. The first three rows show...", "The nearest-neighbor rows show the other side...", "First, we have...", "Finally, we have...", "Last but certainly not least..."). In their place, prose that moves with narrative momentum, interpreting patterns, contrasting unexpected findings, and explaining *why* a result matters.
- **Substantive synthesis**: Clear articulation of the broader stakes—how mid-century anthropologists and sociologists struggled to demarcate "culture," why an "ur-vocabulary" of foundational concepts anchors the discipline, why synthetic thinkers like David Bidney and John Gillin become critical structural bridges, and why K&K's top-down taxonomy fails when confronted with bottom-up computational text models.

---

## Current Diagnostic of `kk-index-b-two-mode.tex`

1. **Stilted, AI-like, and mechanical phrasing**:
   - The opening jumps directly into OCR transcription details and variant splits rather than setting up the intellectual puzzle.
   - Section 2 describes Table 1 line by line ("The first three rows show node and edge counts. The 'degree' rows count connections...").
   - Section 3 walks through quotations with repetitive throat-clearing ("First, we have C-II-4...", "Finally, we have C-II-3...", "Last but certainly not least...").
   - Section 4 lists LDA topics and top quotations mechanically without elevating their sociological meaning.
2. **Missing Discussion Section**:
   - Lines 405–408 contain an empty `\section{Discussion}` with nothing beneath it.
3. **Artifacts / Glitches**:
   - Lines 474–476 contain stray shell commands (`Rscript scripts/analysis-mst-definitions-index-b.R`, etc.) pasted after `\end{document}`.
4. **Overly technical minutiae in the main text**:
   - Lengthy discussions of manual OCR fixing rules, split edge assignments, and transcription edge counts belong in the Appendix (where they are already documented), freeing the main text to focus on substantive arguments.

---

## Detailed Section-by-Section Rewrite Plan

### 1. Title, Abstract, and Introduction
- **Voice & Tone**: First-person authorial framing ("In this paper, I investigate...", "I draw on...").
- **Intellectual Hook**: Frame Kroeber and Kluckhohn's (1952) *Culture: A Critical Review of Concepts and Definitions* as a watershed moment in mid-century American social science—a heroic, post-war campaign by anthropologists and sociologists to establish disciplinary jurisdiction and forge conceptual consensus around the culture concept.
- **Analytical Frame**: Introduce the two-mode relational perspective (Breigerian duality). Definitions and concepts do not exist in isolation; they mutually constitute each other. A definition is an assembly of concepts, and a concept is defined by the company of definitions it keeps.
- **Core Questions**:
  1. What is the latent structural architecture of this conceptual space? Is it modular and fragmented, or organized around a core-periphery backbone?
  2. Which conceptual formulations and theoretical statements serve as structural bridges linking divergent intellectual traditions?
  3. Does K&K's famous deductive taxonomy (Descriptive, Historical, Normative, Psychological, Structural, Genetic) correspond to the bottom-up thematic structure of the actual texts, or was it an editorial convenience imposed from above?

### 2. Macro-Topology and the Core-Periphery Architecture (Section 2)
- **Eliminate mechanical table-reading**: Remove "The first three rows show...", "The degree rows count...", etc.
- **Substantive Focus**:
  - Focus on the extreme asymmetry between concepts and definitions.
  - The concept space displays a steep, heavy-tailed distribution: an "ur-vocabulary" of ubiquitous super-connectors (\textbf{social}, \textbf{society}, \textbf{group}, \textbf{behavior}, \textbf{ideas}, \textbf{customs}) anchors mid-century culture theorizing, while the vast majority of concepts are peripheral or idiosyncratic.
  - Definitions, by contrast, display a well-behaved, unimodal distribution: most theorists avoid conceptual minimalism while also eschewing boundless profligacy, typically combining a small selection of foundational concepts with a tailored cluster of specialized terms.
  - Interpret the negative degree correlation and nearest-neighbor patterns substantively as a relational balancing act between broad anchor terms and specific qualifying concepts.

### 3. Structural Backbones and Conceptual Bridges (Section 3: Spanning Trees)
- **Framing MSTs**: Present maximum spanning trees not as an esoteric algorithmic trick, but as an analytical strategy to extract the structural *backbone* of dense one-mode projections under Breigerian duality.
- **The Concept Backbone**:
  - Synthesize the semantic geography of the tree shown in Figure 2.
  - Show how \textbf{group}, \textbf{social}, \textbf{society}, and \textbf{behavior} act as regional hubs anchoring distinct substantive vocabularies (social organization, normative/customary traditions, behavioral/psychological processes).
  - Highlight the peripheralization of acquisition and genetic concepts (\textbf{learning}, \textbf{transmission}), which connect to the core almost exclusively through \textbf{group}.
- **The Definition Backbone & Bridging Synthesizers**:
  - Revise the walk-through of central definitions, completely stripping out formulaic transitions ("First, we have...", "Finally...", "Last but not least...").
  - Center the substantive insight: high tree-betweenness marks *synthetic, integrative theorizing*.
  - **John Gillin (1942; C-I-6)**: Highlight its role as the dominant structural bridge. Gillin's high centrality is not simply an artifact of verbosity, but reflects an integrative formulation that binds customs, social behavior, group patterns, and generational transmission.
  - **David Bidney (1942, 1946, 1947)**: Emphasize Bidney's remarkable theoretical presence. Bidney accounts for three of the top ten bridging definitions (A-16, C-II-4, C-II-3), despite concise, compact prose. Bidney self-consciously sought an "integral or holistic" definition of culture that reconciled behavioral/psychological reality with normative and institutional ideals.
  - **The Tylor Paradox (A-1)**: Reframe Edward B. Tylor's 1871 founding definition ("that complex whole..."). While revered historically as the founding charter of the anthropological concept, in the mid-20th-century network backbone it is structurally peripheral—anchoring an early descriptive/antiquarian cluster rather than mediating contemporary theoretical debates.

### 4. Bottom-Up Thematic Structure: Latent Dirichlet Allocation (Section 4)
- **Analytical Framing**: Frame LDA as an unsupervised computational interrogation of the texts themselves. We strip away K&K's pre-assigned category labels and ask: What latent thematic spaces emerge from the actual words used in the definition clauses?
- **The 12 Latent Themes**:
  - Characterize the thematic landscape (transmitted group behavior, ways of life of a people, human products and results, biological needs and adjustment, etc.).
  - Discuss the most representative definitions (Table 5) as concrete exemplars of these latent themes.
- **Taxonomy vs. Lexical Reality (The Breakdown of K&K's Categories)**:
  - Reframe the chi-square and Sankey results into a major conceptual finding.
  - While statistically non-random, K&K's seven categories (A–G) fail to partition the conceptual space cleanly. Definitions are pervasive mixtures; categories are dispersed across multiple topics; and dominant topics cut horizontally across K&K's categories.
  - Draw the key theoretical inference: K&K's categories represent an *external, editorial-bibliographic classification scheme* rather than an internal, latent semantic reality of how culture was conceptualized by practicing social scientists.

### 5. Writing a Brand New Discussion Section (Section 5)
Synthesize the entire study into four big-picture themes in Omar Lizardo's signature style:
1. **The Relational Duality of Disciplinary Concepts**: Demonstrating the analytical power of Breigerian duality for the history of ideas and the cognitive sociology of science.
2. **The Core-Periphery Architecture of Disciplinary Consensus**: Explaining why social scientific concepts tend to accumulate a shared core of generalized vocabulary while maintaining boundless peripheral variety.
3. **Synthetic Theorizing vs. Deductive Taxonomies**: Why synthetic, bridging thinkers (like Bidney and Gillin) are vital for intellectual integration, and why top-down deductive taxonomies (like K&K's) often obscure the actual relational structure of scientific discourse.
4. **Implications for Contemporary Culture Theory and Computational Concept Analysis**: How combining relational network methods with computational text models provides a roadmap for modern cultural sociology and the study of concept formation.

### 6. Appendix & Technical Clean-up
- Retain the exact construction documentation and provenance in Appendix A.
- Remove the stray terminal execution commands at lines 474–476.
- Ensure strict adherence to project rules:
  - Keep `\citealt` for K&K definition references.
  - Preserve bolding/italics conventions for concepts.
  - Avoid sentence-opening pronouns without clear referents.
  - American English spelling throughout.
  - Verify that all numerical values, percentages, sample sizes, and citations match the verified data exactly.
  - Run LaTeX compilation checks in a clean scratch environment to ensure zero errors or warnings.

---

## Verification & Execution Steps

1. **Plan Approval**: Present the plan to the user via `ExitMode`.
2. **Drafting**: Rewrite `kk-index-b-two-mode.tex` systematically section by section, carefully maintaining LaTeX syntax and all data points.
3. **Compilation Check**: Copy `.tex`, `.bib`, and figures to a scratch environment; compile with `pdflatex`, `bibtex`, `pdflatex` twice. Verify zero undefined citations or overfull boxes.
4. **Review & Diff**: Check `git diff` to ensure that empirical numbers and references are faithfully preserved while the prose is completely transformed.
