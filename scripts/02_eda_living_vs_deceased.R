library(tidyverse)
library(ggrepel)

# 0. Load data
donors      <- read_csv(here::here("data", "clean", "godt_donors_long.csv"))
transplants <- read_csv(here::here("data", "clean", "godt_transplants_long.csv"))
coverage    <- read_csv(here::here("data", "clean", "coverage.csv"))

# 1. Build the two key variables
deceased_rows <- donors %>%
  filter(status == "actual", death_criterion == "total")

living_rows <- transplants %>%
  filter(organ == "kidney", source == "living")

# 2. Country-level averages and coverage filter
well_covered <- coverage %>%
  filter(n_donor_years >= 10, n_kidney_tx_years >= 10) %>%
  pull(country)

deceased_avg <- deceased_rows %>%
  filter(country %in% well_covered) %>%
  group_by(country, region) %>%
  summarise(X = mean(donors_pmp, na.rm = TRUE), .groups = "drop")

living_avg <- living_rows %>%
  filter(country %in% well_covered) %>%
  group_by(country) %>%
  summarise(Y = mean(transplants_pmp, na.rm = TRUE), .groups = "drop")

dat <- inner_join(deceased_avg, living_avg, by = "country")

n <- nrow(dat)
cat("Number of countries in analysis:", n, "\n")


# 3. Descriptive statistics
summary_stats <- dat %>%
  summarise(
    across(c(X, Y),
           list(mean   = ~ mean(.x,   na.rm = TRUE),
                median = ~ median(.x, na.rm = TRUE),
                sd     = ~ sd(.x,     na.rm = TRUE),
                min    = ~ min(.x,    na.rm = TRUE),
                max    = ~ max(.x,    na.rm = TRUE)),
           .names = "{.col}_{.fn}")
  )

print(summary_stats)

ggplot(dat, aes(x = X)) +
  geom_histogram(bins = 20, fill = "steelblue", colour = "white") +
  labs(
    title   = "Distribution of deceased donors pmp (country averages)",
    x       = "Deceased donors per million population",
    y       = "Number of countries",
    caption = "Source: GODT (WHO/ONT). Countries with >= 10 years of data."
  ) +
  theme_minimal()

ggplot(dat, aes(x = Y)) +
  geom_histogram(bins = 20, fill = "seagreen", colour = "white") +
  labs(
    title   = "Distribution of living-donor kidney transplants pmp",
    x       = "Living-donor kidney transplants per million population",
    y       = "Number of countries",
    caption = "Source: GODT (WHO/ONT)."
  ) +
  theme_minimal()

# 4. Scatter plot
label_these <- c(
  "Türkiye", "Jordan", "Saudi Arabia", "Japan",
  "United States of America", "Netherlands", "Iceland",
  "Spain", "Croatia", "Slovenia", "Portugal"
)

ggplot(dat, aes(x = X, y = Y)) +
  geom_point(aes(colour = region), size = 2.5, alpha = 0.85) +
  geom_smooth(method = "lm", se = TRUE,
              colour = "grey30", fill = "grey85", linewidth = 0.8) +
  geom_label_repel(
    data          = filter(dat, country %in% label_these),
    aes(label     = country),
    size          = 2.8,
    max.overlaps  = 20,
    label.padding = 0.15
  ) +
  scale_colour_brewer(palette = "Set2", name = "WHO region") +
  labs(
    title    = "Deceased donation vs living-donor kidney transplantation",
    subtitle = paste0("Country averages 2000-2024  |  n = ", n, " countries"),
    x        = "X: Deceased donors per million population (pmp)",
    y        = "Y: Living-donor kidney transplants pmp",
    caption  = "Source: GODT (WHO/ONT). Countries with >= 10 years of data."
  ) +
  theme_minimal(base_size = 12)

# 5. Correlation
pearson  <- cor.test(dat$X, dat$Y, method = "pearson")
spearman <- cor.test(dat$X, dat$Y, method = "spearman")

cat("\n--- Pearson correlation ---\n")
cat("r =", round(pearson$estimate, 3),
    "  p-value =", round(pearson$p.value, 4), "\n")

cat("\n--- Spearman rank correlation ---\n")
cat("rho =", round(spearman$estimate, 3),
    "  p-value =", round(spearman$p.value, 4), "\n")

# 6. Quadrant analysis
med_X <- median(dat$X)
med_Y <- median(dat$Y)

dat <- dat %>%
  mutate(
    quadrant = case_when(
      X >= med_X & Y >= med_Y ~ "High deceased / High living",
      X <  med_X & Y >= med_Y ~ "Low deceased / High living\n[compensators]",
      X >= med_X & Y <  med_Y ~ "High deceased / Low living",
      TRUE                    ~ "Low deceased / Low living"
    )
  )

print(count(dat, quadrant))

n_comp <- sum(dat$quadrant == "Low deceased / High living\n[compensators]")
cat("\nCompensator countries:", n_comp, "out of", n,
    sprintf("(%.0f%%)\n", n_comp / n * 100))

ggplot(dat, aes(x = X, y = Y)) +
  geom_vline(xintercept = med_X, linetype = "dashed", colour = "grey60") +
  geom_hline(yintercept = med_Y, linetype = "dashed", colour = "grey60") +
  geom_point(aes(colour = region), size = 2.5, alpha = 0.85) +
  geom_label_repel(
    data          = filter(dat, country %in% label_these),
    aes(label     = country),
    size          = 2.8,
    max.overlaps  = 20,
    label.padding = 0.15
  ) +
  annotate("text", x = med_X * 0.45, y = max(dat$Y) * 0.93,
           label = "Compensators", fontface = "bold",
           colour = "firebrick", size = 3.5) +
  annotate("text", x = max(dat$X) * 0.75, y = max(dat$Y) * 0.93,
           label = "High capacity", fontface = "bold",
           colour = "darkgreen", size = 3.5) +
  scale_colour_brewer(palette = "Set2", name = "WHO region") +
  labs(
    title    = "Quadrant analysis: four donor-system types",
    subtitle = "Dashed lines = median of each axis",
    x        = "X: Deceased donors pmp",
    y        = "Y: Living-donor kidney transplants pmp",
    caption  = "Source: GODT (WHO/ONT)."
  ) +
  theme_minimal(base_size = 12)

# 7. Group comparison
group_summary <- dat %>%
  mutate(deceased_group = if_else(X < med_X,
                                  "Low deceased (below median X)",
                                  "High deceased (above median X)")) %>%
  group_by(deceased_group) %>%
  summarise(
    n        = n(),
    mean_Y   = round(mean(Y),   2),
    median_Y = round(median(Y), 2),
    sd_Y     = round(sd(Y),     2),
    .groups  = "drop"
  )

print(group_summary)

dat %>%
  mutate(deceased_group = if_else(X < med_X,
                                  "Low deceased\n(below median X)",
                                  "High deceased\n(above median X)")) %>%
  ggplot(aes(x = deceased_group, y = Y, fill = deceased_group)) +
  geom_boxplot(alpha = 0.7, show.legend = FALSE) +
  geom_jitter(width = 0.15, alpha = 0.5, size = 1.5) +
  scale_fill_manual(values = c("Low deceased\n(below median X)"  = "lightyellow",
                               "High deceased\n(above median X)" = "lightblue")) +
  labs(
    title   = "Living-donor kidney tx pmp by deceased-donation group",
    x       = NULL,
    y       = "Y: Living-donor kidney transplants pmp",
    caption = "Source: GODT (WHO/ONT)."
  ) +
  theme_minimal(base_size = 12)

# 8. Time trends for selected countries
compensators <- c("Türkiye", "Jordan", "Japan")
reference    <- c("Spain", "Croatia", "Slovenia")
highlight    <- c(compensators, reference)

deceased_rows %>%
  filter(country %in% highlight) %>%
  mutate(group = if_else(country %in% compensators,
                         "Compensator", "Reference (high deceased)")) %>%
  ggplot(aes(x = year, y = donors_pmp, colour = country, linetype = group)) +
  geom_line(linewidth = 0.9, na.rm = TRUE) +
  scale_linetype_manual(values = c("Compensator"              = "solid",
                                   "Reference (high deceased)" = "dashed")) +
  scale_colour_brewer(palette = "Dark2") +
  labs(
    title    = "Deceased donors pmp over time",
    subtitle = "Solid = compensator countries  |  Dashed = high-deceased reference",
    x        = "Year",
    y        = "Deceased donors per million population",
    colour   = "Country", linetype = "Group",
    caption  = "Source: GODT (WHO/ONT)."
  ) +
  theme_minimal(base_size = 12)

living_rows %>%
  filter(country %in% highlight) %>%
  mutate(group = if_else(country %in% compensators,
                         "Compensator", "Reference (high deceased)")) %>%
  ggplot(aes(x = year, y = transplants_pmp, colour = country, linetype = group)) +
  geom_line(linewidth = 0.9, na.rm = TRUE) +
  scale_linetype_manual(values = c("Compensator"              = "solid",
                                   "Reference (high deceased)" = "dashed")) +
  scale_colour_brewer(palette = "Dark2") +
  labs(
    title    = "Living-donor kidney transplants pmp over time",
    subtitle = "Solid = compensator countries  |  Dashed = high-deceased reference",
    x        = "Year",
    y        = "Living-donor kidney transplants per million population",
    colour   = "Country", linetype = "Group",
    caption  = "Source: GODT (WHO/ONT)."
  ) +
  theme_minimal(base_size = 12)

# 9. Key numbers
cat("\n=== KEY NUMBERS FOR WRITE-UP ===\n")
cat("N countries analysed:  ", n, "\n")
cat("Spearman rho:          ", round(spearman$estimate, 3), "\n")
cat("  p-value:             ", round(spearman$p.value,  4), "\n")
cat("Pearson r:             ", round(pearson$estimate,  3), "\n")
cat("  p-value:             ", round(pearson$p.value,   4), "\n")
cat("Compensator countries: ", n_comp,
    sprintf("(%.0f%%)\n", n_comp / n * 100))

cat("\nTop 10 compensators:\n")
dat %>%
  filter(quadrant == "Low deceased / High living\n[compensators]") %>%
  arrange(desc(Y)) %>%
  select(country, region, X, Y) %>%
  slice_head(n = 10) %>%
  print()
