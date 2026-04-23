library(tidyverse)
library(ggrepel)
library(here)

# ---- 0) Setup output folder ----
fig_dir <- here::here("outputs", "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# ---- 1) Load data ----
donors      <- readr::read_csv(here::here("data", "clean", "godt_donors_long.csv"), show_col_types = FALSE)
transplants <- readr::read_csv(here::here("data", "clean", "godt_transplants_long.csv"), show_col_types = FALSE)
coverage    <- readr::read_csv(here::here("data", "clean", "coverage.csv"), show_col_types = FALSE)

# ---- 2) Build key variables ----
deceased_rows <- donors %>%
  filter(status == "actual", death_criterion == "total")

living_rows <- transplants %>%
  filter(organ == "kidney", source == "living")

# Coverage filter: keep countries with >=10 years in both indicators
well_covered <- coverage %>%
  filter(n_donor_years >= 10, n_kidney_tx_years >= 10) %>%
  pull(country)

# Country averages
deceased_avg <- deceased_rows %>%
  filter(country %in% well_covered) %>%
  group_by(country, region) %>%
  summarise(X = mean(donors_pmp, na.rm = TRUE), .groups = "drop")

living_avg <- living_rows %>%
  filter(country %in% well_covered) %>%
  group_by(country) %>%
  summarise(Y = mean(transplants_pmp, na.rm = TRUE), .groups = "drop")

dat <- inner_join(deceased_avg, living_avg, by = "country")
n   <- nrow(dat)

# Correlations
pearson  <- cor.test(dat$X, dat$Y, method = "pearson")
spearman <- cor.test(dat$X, dat$Y, method = "spearman")

# Medians and quadrant label
med_X <- median(dat$X, na.rm = TRUE)
med_Y <- median(dat$Y, na.rm = TRUE)

dat <- dat %>%
  mutate(
    quadrant = case_when(
      X >= med_X & Y >= med_Y ~ "High deceased / High living",
      X <  med_X & Y >= med_Y ~ "Low deceased / High living (compensators)",
      X >= med_X & Y <  med_Y ~ "High deceased / Low living",
      TRUE                    ~ "Low deceased / Low living"
    )
  )

n_comp <- sum(dat$quadrant == "Low deceased / High living (compensators)")

label_these <- c(
  "Türkiye", "Jordan", "Saudi Arabia", "Japan",
  "United States of America", "Netherlands", "Iceland",
  "Spain", "Croatia", "Slovenia", "Portugal"
)

base_theme <- theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

# ---- FIGURE 1: Scatter ----
p1 <- ggplot(dat, aes(x = X, y = Y)) +
  geom_point(aes(colour = region), size = 2.5, alpha = 0.85) +
  geom_smooth(method = "lm", se = TRUE,
              colour = "grey30", fill = "grey85", linewidth = 0.8) +
  geom_label_repel(
    data = filter(dat, country %in% label_these),
    aes(label = country),
    size = 2.8, max.overlaps = 20, label.padding = 0.15
  ) +
  scale_colour_brewer(palette = "Set2", name = "WHO region") +
  labs(
    title    = "Figure 1. Deceased donation vs living-donor kidney transplantation",
    subtitle = paste0("Country averages 2000–2024 | n = ", n,
                      " | Spearman rho = ", round(spearman$estimate, 3),
                      " (p = ", signif(spearman$p.value, 3), ")",
                      " | inclusion: >=10 years coverage"),
    x        = "X: Deceased donors per million population (pmp)",
    y        = "Y: Living-donor kidney transplants per million population (pmp)",
    caption  = "Source: GODT (WHO/ONT)."
  ) +
  base_theme

ggsave(file.path(fig_dir, "fig1_scatter.png"), p1, width = 8.5, height = 5.5, dpi = 300)
ggsave(file.path(fig_dir, "fig1_scatter.pdf"), p1, width = 8.5, height = 5.5)

# ---- FIGURE 2: Quadrant ----
p2 <- ggplot(dat, aes(x = X, y = Y)) +
  geom_vline(xintercept = med_X, linetype = "dashed", colour = "grey60") +
  geom_hline(yintercept = med_Y, linetype = "dashed", colour = "grey60") +
  geom_point(aes(colour = region), size = 2.5, alpha = 0.85) +
  geom_label_repel(
    data = filter(dat, country %in% label_these),
    aes(label = country),
    size = 2.8, max.overlaps = 20, label.padding = 0.15
  ) +
  scale_colour_brewer(palette = "Set2", name = "WHO region") +
  labs(
    title    = "Figure 2. Quadrant analysis: four donor-system types",
    subtitle = paste0("Dashed lines = medians | X = ", round(med_X, 2),
                      " pmp, Y = ", round(med_Y, 2),
                      " pmp | compensators: ", n_comp, "/", n,
                      " (", round(100 * n_comp / n), "%)"),
    x        = "X: Deceased donors pmp",
    y        = "Y: Living-donor kidney transplants pmp",
    caption  = "Source: GODT (WHO/ONT)."
  ) +
  base_theme

ggsave(file.path(fig_dir, "fig2_quadrant.png"), p2, width = 8.5, height = 5.5, dpi = 300)
ggsave(file.path(fig_dir, "fig2_quadrant.pdf"), p2, width = 8.5, height = 5.5)

# ---- FIGURE 3: Boxplot (group comparison) ----
dat2 <- dat %>%
  mutate(deceased_group = if_else(X < med_X,
                                  "Low deceased (below median X)",
                                  "High deceased (above median X)"))

group_summary <- dat2 %>%
  group_by(deceased_group) %>%
  summarise(mean_Y = mean(Y, na.rm = TRUE), .groups = "drop")

mean_low  <- group_summary$mean_Y[group_summary$deceased_group == "Low deceased (below median X)"]
mean_high <- group_summary$mean_Y[group_summary$deceased_group == "High deceased (above median X)"]

p3 <- ggplot(dat2, aes(x = deceased_group, y = Y, fill = deceased_group)) +
  geom_boxplot(alpha = 0.7, show.legend = FALSE) +
  geom_jitter(width = 0.15, alpha = 0.5, size = 1.5, show.legend = FALSE) +
  labs(
    title    = "Figure 3. Living-donor kidney transplants by deceased-donation group",
    subtitle = paste0("Mean Y (high vs low deceased): ",
                      round(mean_high, 2), " vs ", round(mean_low, 2), " pmp"),
    x        = NULL,
    y        = "Y: Living-donor kidney transplants pmp",
    caption  = "Source: GODT (WHO/ONT)."
  ) +
  base_theme

ggsave(file.path(fig_dir, "fig3_boxplot.png"), p3, width = 8.5, height = 5.0, dpi = 300)
ggsave(file.path(fig_dir, "fig3_boxplot.pdf"), p3, width = 8.5, height = 5.0)

# ---- FIGURE 4: Histograms (one figure with facets) ----
dat_long <- dat %>%
  select(X, Y) %>%
  pivot_longer(cols = c(X, Y), names_to = "metric", values_to = "value") %>%
  mutate(metric = recode(metric,
                         X = "X: Deceased donors pmp",
                         Y = "Y: Living kidney transplants pmp"))

p4 <- ggplot(dat_long, aes(x = value)) +
  geom_histogram(bins = 20, colour = "white") +
  facet_wrap(~ metric, scales = "free_x") +
  labs(
    title   = "Figure 4. Distributions of X and Y (country averages)",
    subtitle= "Both distributions are right-skewed (motivation for Spearman correlation).",
    x       = NULL,
    y       = "Number of countries",
    caption = "Source: GODT (WHO/ONT)."
  ) +
  base_theme

ggsave(file.path(fig_dir, "fig4_histograms.png"), p4, width = 8.5, height = 5.0, dpi = 300)
ggsave(file.path(fig_dir, "fig4_histograms.pdf"), p4, width = 8.5, height = 5.0)

# ---- FIGURE 5: Time trends (one figure with facets) ----
compensators <- c("Türkiye", "Jordan", "Japan")
reference    <- c("Spain", "Croatia", "Slovenia")
highlight    <- c(compensators, reference)

time_deceased <- deceased_rows %>%
  filter(country %in% highlight) %>%
  select(country, year, value = donors_pmp) %>%
  mutate(series = "Deceased donors pmp")

time_living <- living_rows %>%
  filter(country %in% highlight) %>%
  select(country, year, value = transplants_pmp) %>%
  mutate(series = "Living kidney transplants pmp")

time_dat <- bind_rows(time_deceased, time_living) %>%
  mutate(group = if_else(country %in% compensators,
                         "Compensator", "Reference (high deceased)"))

p5 <- ggplot(time_dat, aes(x = year, y = value, colour = country, linetype = group)) +
  geom_line(linewidth = 0.9, na.rm = TRUE) +
  facet_wrap(~ series, scales = "free_y") +
  scale_colour_brewer(palette = "Dark2") +
  labs(
    title    = "Figure 5. Time trends for selected countries (2000–2024)",
    subtitle = "Solid = compensators | Dashed = high-deceased reference countries",
    x        = "Year",
    y        = NULL,
    colour   = "Country",
    linetype = "Group",
    caption  = "Source: GODT (WHO/ONT). Interpret with caution due to reporting gaps."
  ) +
  base_theme

ggsave(file.path(fig_dir, "fig5_time_trends.png"), p5, width = 10, height = 5.5, dpi = 300)
ggsave(file.path(fig_dir, "fig5_time_trends.pdf"), p5, width = 10, height = 5.5)

cat("\nSaved figures to: ", fig_dir, "\n")
cat("n countries: ", n, "\n")
cat("Spearman rho: ", round(spearman$estimate, 3), " (p=", signif(spearman$p.value,3), ")\n", sep = "")
cat("Pearson r: ", round(pearson$estimate, 3), " (p=", signif(pearson$p.value,3), ")\n", sep = "")
cat("Compensators: ", n_comp, "/", n, " (", round(100*n_comp/n), "%)\n", sep = "")
