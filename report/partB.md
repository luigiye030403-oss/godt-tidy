# Part B: content
**Project title:** Stats Project 2026 — Living vs Deceased Donation  
**Team members + student IDs:** [Name1, ID] • [Name2, ID] • [Name3, ID] • [Name4, ID]

## Research question
Do countries compensate for low deceased donation with higher living donation?

## Data
We use the WHO–ONT Transplant Observatory export database (2000–2024) and follow the official questionnaire definitions (WHO–ONT, n.d.-a; WHO–ONT, n.d.-b). Our two indicators are: (X) deceased donors per million population (pmp) and (Y) living-donor kidney transplants pmp. We restrict to countries with at least 10 years of data in both indicators (n = 89). Data were reshaped and analysed following tidy data principles (Wickham, 2014).

## Methods
We compute country-level averages over 2000–2024. Because both X and Y are right-skewed, we use Spearman rank correlation as the primary global test (Pearson correlation as a robustness check). To characterise “system types”, we split countries into four quadrants using the sample medians (median X = 4.86 pmp; median Y = 4.67 pmp). Figures were produced in R using ggplot2 (Wickham, 2016).

## Findings
We find no evidence of a global compensation pattern. The relationship between X and Y is weakly positive and not statistically significant (Spearman ρ = 0.111, p = 0.302; Pearson r = 0.076, p = 0.477; n = 89). A simple group comparison points the same way: countries above the median on deceased donation have higher average living donation (mean Y = 8.52 vs 5.73), the opposite of compensation.

The quadrant analysis reveals heterogeneity across countries. A small “compensator” cluster (low deceased / high living) contains 19 of 89 countries (21%), including Jordan (X = 0.04, Y = 22.2), Türkiye (X = 4.0, Y = 24.8), Saudi Arabia (X = 3.0, Y = 17.9) and Japan (X = 0.8, Y = 10.4). In contrast, a “deceased-only” model (high deceased / low living) is common in Western/Central Europe, with Spain (X = 39.4, Y = 5.3), Croatia (X = 24.0, Y = 1.9) and Slovenia (X = 19.0, Y = 0.4) as clear examples. The USA is high on both dimensions (X = 30.0, Y = 19.2), standing out as a special case.

## Interpretation & limitations
Overall, the data do not support a universal substitution/compensation hypothesis. Instead, distinct regional system models appear: a Western European model centred on deceased donation and a smaller set of countries where living donation is relatively strong despite weak deceased donation. We do not test causal mechanisms. Finally, many countries have reporting gaps, so time trends should be interpreted with caution (see issues_log.md).

## Figures to include in the final 2-page PDF
**Figure 1 (scatter):** `outputs/figures/fig1_scatter.(png/pdf)`  
Caption: Deceased donation vs living-donor kidney transplantation (country averages 2000–2024). n = 89 (≥10 years coverage in both indicators). Spearman ρ = 0.111 (p = 0.302). Units: pmp. Source: GODT (WHO/ONT).

**Figure 2 (quadrant):** `outputs/figures/fig2_quadrant.(png/pdf)`  
Caption: Quadrant analysis using medians (X = 4.86 pmp, Y = 4.67 pmp). Compensators (low X / high Y) are 19/89 (21%). Units: pmp. Source: GODT (WHO/ONT).

(Optional if space) **Figure 3 (boxplot):** `outputs/figures/fig3_boxplot.(png/pdf)`  
Caption: Living-donor kidney transplants pmp by deceased-donation group (above vs below median X). Mean Y = 8.52 vs 5.73.

## References
- Wickham, H. (2014). *Tidy Data*. *Journal of Statistical Software*, 59(10), 1–23.
- WHO–ONT. (n.d.-a). *Transplant Observatory – Export database (2000–2024)*. Accessed: **DD Month YYYY**.
- WHO–ONT. (n.d.-b). *Transplant Observatory Questionnaire* [PDF]. Accessed: **DD Month YYYY**.
- Wickham, H. (2016). *ggplot2: Elegant Graphics for Data Analysis*. Springer.
- Wickham, H., & Grolemund, G. (2017). *R for Data Science*. O’Reilly.
