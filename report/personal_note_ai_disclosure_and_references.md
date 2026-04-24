# Personal note for the team: AI-tool disclosure + reference rationale
*Updated: 24 April 2026*

This short commentary is written by me as a **Part B companion note** to help the team understand:

1. what I disclosed in **Part A (Q1)** about AI-tool use **for producing the Part B figures**, and
2. why these specific references appear in **Part B** (including why some include a **retrieval date**).
---

### How I used ChatGPT (limited scope)

I used ChatGPT **only for figure/image production and formatting** in Part B (e.g., generating or refining plot output, improving layout/readability such as label overlap and spacing).

I **did not** use ChatGPT to decide the research question, define variables, choose statistical methods, select the sample, or interpret results. All analytical decisions were made by the team.

### What I (and the team) did **without AI**
**Data preparation + sample definition**
- Cleaned and reshaped the WHO–ONT/GODT export into analysis-ready data.
- Defined the inclusion rule: countries with **≥ 10 years coverage in both indicators** → **n = 89**.
- Cleaned input files used for the figures:
  - `data/clean/godt_donors_long.csv`
  - `data/clean/godt_transplants_long.csv`
  - `data/clean/coverage.csv`

**Research design + analysis decisions**
- Research question + variable definitions:
  - **X** = deceased donors per million population (pmp)
  - **Y** = living-donor kidney transplants per million population (pmp)
- Methods:
  - Spearman rank correlation as the primary test (skewed variables)
  - Median split to create the 4 quadrants
- Plot choices:
  - Scatter + trend line (Figure 1)
  - Median-split quadrant classification (Figure 2)

### How I used ChatGPT (limited scope)
I used ChatGPT only to:
- translate my already-decided design into R plotting code,
- troubleshoot formatting (label overlap, spacing, readability),
- iterate until the final figures were readable.

All analytical choices stayed human-made and were checked by me.

---

## 2) Why some references include “Retrieved 24 April 2026”
Some references are **web pages / online documents** that can change over time.
The retrieval date records **when I accessed that page**, so others can reproduce what I saw if the page updates later.

---

## 3) Why these references are included (where they are used)

- **Wickham (2014)**: supports the tidy-data reshaping logic used in the data pipeline.
- **GODT “How to quote / use GODT data”**: official guidance for how to cite and use the provider’s dataset correctly.
- **GODT Questionnaire 2020 (PDF)**: formal indicator definitions for X/Y (measurement validity).
- **NIST/SEMATECH Spearman page**: authoritative justification for using Spearman correlation with skewed variables.
- **Streit et al. (2023)**: peer-reviewed context for interpreting “deceased-donation–centered” systems (e.g., Spain).

---

## References (same as Part B)

- Wickham, H. (2014). *Tidy Data*. *Journal of Statistical Software*, 59(10), 1–23. https://doi.org/10.18637/jss.v059.i10
- Global Observatory on Donation and Transplantation (GODT) — WHO/ONT. (n.d.). *How to quote / use GODT data*. Retrieved 24 April 2026, from https://www.transplant-observatory.org/uses-of-data/
- Global Observatory on Donation and Transplantation (GODT) — WHO/ONT. (2020). *Transplant Observatory Questionnaire 2020* [PDF]. Retrieved 24 April 2026, from https://www.transplant-observatory.org/download/questionnaire-2020/
- NIST/SEMATECH. (n.d.). *e-Handbook of Statistical Methods: Spearman’s rank correlation coefficient*. Retrieved 24 April 2026, from https://www.itl.nist.gov/div898/software/dataplot/refman1/auxillar/spearc.htm
- Streit, S., Johnston-Webber, C., Mah, J., Prionas, A., Wharton, G., Casanova, D., Mossialos, E., & Papalois, V. (2023). Ten lessons from the Spanish model of organ donation and transplantation. *Transplant International*, 36, 11009. https://doi.org/10.3389/ti.2023.11009
