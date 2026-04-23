# EDA Insights Summary
**Research question:** Do countries compensate for low deceased donation with higher living donation?  

---

## Key Numbers

| Metric | Value |
|---|---|
| Countries analysed | 89 (≥ 10 years of data in both indicators) |
| Spearman rho | +0.111 |
| p-value (Spearman) | 0.302 |
| Pearson r | +0.076 |
| p-value (Pearson) | 0.477 |
| Compensator countries | 19 / 89 (21%) |
| Median deceased donors pmp | 4.86 |
| Median living kidney transplants pmp | 4.67 |

---

## Main Finding

No global compensation pattern. The correlation between deceased donation rate (X) and living-donor kidney transplantation rate (Y) is weakly positive and not statistically significant (Spearman rho = +0.11, p = 0.30, n = 89). Countries with weak deceased donation systems do not systematically make up for it with more living donation — if anything the two move together, suggesting both reflect general healthcare capacity rather than a trade-off.

The group comparison points the same way: countries above the median on deceased donation also have higher average living donation (mean Y = 8.52 vs 5.73), the opposite of compensation.

---

## Four System Types

The quadrant plot splits countries by the median of each axis.

**High deceased / High living — "High capacity" (26 countries)**  
Strong on both. USA (X = 30.0, Y = 19.2) is the clearest example — the only country that leads globally on both measures. Netherlands (X = 15.1, Y = 24.1) and Iceland (X = 17.4, Y = 19.9) also stand out, unusually high on living donation for European countries.

**Low deceased / High living — "Compensators" (19 countries, 21%)**  
The most interesting group. Jordan (X = 0.04, Y = 22.2) has almost no deceased donation but one of the highest living rates in the dataset. Türkiye (X = 4.0, Y = 24.8) has the highest living kidney transplantation rate overall. Saudi Arabia (X = 3.0, Y = 17.9) and Japan (X = 0.8, Y = 10.4) follow the same pattern. These countries are concentrated in the Eastern Mediterranean and East Asia — regions where cultural or religious factors constrain deceased donation specifically.

**High deceased / Low living — "Deceased-only" (19 countries)**  
Spain (X = 39.4, Y = 5.3) holds the world record for deceased donation but has very low living donation. Croatia (X = 24.0, Y = 1.9) and Slovenia (X = 19.0, Y = 0.4) are even more extreme on the living side. Portugal and Belgium follow the same pattern. This is the dominant model across Western and Central Europe.

**Low deceased / Low living — "Low overall" (25 countries)**  
Limited activity on both dimensions, mostly lower-income countries in Africa and parts of the Americas.

---

## What the Plots Show

- **Histograms** — both X and Y are right-skewed, which is why we use Spearman rather than Pearson
- **Scatter plot** — regression line is nearly flat with a wide confidence band, confirming the near-zero correlation visually
- **Quadrant plot** — the compensator cluster in the upper-left is striking but small (21%) and geographically concentrated
- **Time trends** — the patterns for Türkiye, Jordan and Japan vs Spain, Croatia and Slovenia are stable over time, not just a snapshot from one year

---

## Suggested Interpretation for Part B

The data does not support a global compensation hypothesis. Instead, two distinct models emerge. A Western European model built around deceased donation, where living donation plays a minor role. And a Middle Eastern / East Asian model where cultural or religious constraints on deceased donation have pushed countries toward strong living-donor programmes instead. The USA is a case apart — high on both.

---

## Notes for Viz + Writing

- Quadrant plot and scatter are the two strongest figures for the report
- Time trends work well as supporting evidence or in an appendix
- Worth noting in the report: 61 of 124 countries have reporting gaps (see `issues_log.md`), so time trend plots should be read with that caveat
