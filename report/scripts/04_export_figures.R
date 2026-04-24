# report/scripts/04_export_figures.R
# Reproducible export of Figure 1 (scatter) and Figure 2 (quadrant) using ggplot2

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(ggrepel)
  library(scales)
  library(here)
})

# ----------------------------
# 0) Paths
# ----------------------------
data_dir <- here("data", "clean")
out_dir  <- here("outputs", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

donors_path     <- file.path(data_dir, "godt_donors_long.csv")
tx_path         <- file.path(data_dir, "godt_transplants_long.csv")
coverage_path   <- file.path(data_dir, "coverage.csv")

stopifnot(file.exists(donors_path), file.exists(tx_path), file.exists(coverage_path))

# ----------------------------
# 1) Load data
# ----------------------------
donors <- read_csv(donors_path, show_col_types = FALSE)
tx     <- read_csv(tx_path, show_col_types = FALSE)
covg   <- read_csv(coverage_path, show_col_types = FALSE)

# Expected columns (roughly):
# donors: region,country,year,population_m,status,death_criterion,donors,donors_pmp
# tx: region,country,year,population_m,organ,source,transplants,transplants_pmp
# coverage: country,region,...,n_donor_years,n_kidney_tx_years,...

# ----------------------------
# 2) Filter: countries with >=10 years in both indicators
# ----------------------------
well_covered <- covg %>%
  filter(n_donor_years >= 10, n_kidney_tx_years >= 10) %>%
  distinct(country) %>%
  pull(country)

# X: deceased donors pmp (actual, total)
x_df <- donors %>%
  filter(country %in% well_covered,
         status == "actual",
         death_criterion == "total") %>%
  group_by(country, region) %>%
  summarise(
    x = mean(donors_pmp, na.rm = TRUE),
    n_years_x = sum(!is.na(donors_pmp)),
    .groups = "drop"
  )

# Y: living donor kidney transplants pmp
y_df <- tx %>%
  filter(country %in% well_covered,
         organ == "kidney",
         source == "living") %>%
  group_by(country, region) %>%
  summarise(
    y = mean(transplants_pmp, na.rm = TRUE),
    n_years_y = sum(!is.na(transplants_pmp)),
    .groups = "drop"
  )

xy <- x_df %>%
  inner_join(y_df, by = "country") %>%
  mutate(
    # keep one region label (prefer donors region if exists)
    region = coalesce(region.x, region.y)
  ) %>%
  select(country, region, x, y, n_years_x, n_years_y) %>%
  filter(is.finite(x), is.finite(y))

cat("N countries in final XY:", nrow(xy), "\n")

# ----------------------------
# 3) Stats: Spearman correlation
# ----------------------------
spearman <- suppressWarnings(cor.test(xy$x, xy$y, method = "spearman", exact = FALSE))
rho <- unname(spearman$estimate)
pval <- spearman$p.value

# Medians (use computed; round for display)
x_med <- median(xy$x, na.rm = TRUE)
y_med <- median(xy$y, na.rm = TRUE)

# If you MUST match the reported values exactly, uncomment:
# x_med <- 4.86
# y_med <- 4.67

comp_n <- sum(xy$x < x_med & xy$y > y_med)

subtitle_scatter <- paste0(
  "n = ", nrow(xy), " countries (≥10 years coverage).  ",
  "Spearman ρ = ", sprintf("%.3f", rho), " (p = ", sprintf("%.3f", pval), ")."
)

subtitle_quad <- paste0(
  "Medians: X = ", sprintf("%.2f", x_med), " pmp,  Y = ", sprintf("%.2f", y_med),
  " pmp.  Compensators: ", comp_n, "/", nrow(xy), " (", round(100*comp_n/nrow(xy)), "%)."
)

# Countries to label (edit freely)
label_countries <- c(
  "Jordan", "Türkiye", "Saudi Arabia", "Japan",
  "Spain", "Croatia", "Slovenia", "Portugal",
  "United States of America", "Netherlands", "Iceland"
)

xy <- xy %>%
  mutate(label = ifelse(country %in% label_countries, country, NA_character_))

# ----------------------------
# 4) Theme helper (bigger spacing; avoids title/subtitle sticking)
# ----------------------------
base_theme <- theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 22, face = "bold", margin = margin(b = 14)),
    plot.subtitle = element_text(size = 14, margin = margin(b = 22)),
    axis.title = element_text(size = 16, margin = margin(t = 10, r = 10, b = 10, l = 10)),
    axis.text = element_text(size = 13),
    legend.title = element_text(size = 14),
    legend.text = element_text(size = 12),
    legend.position = "right",
    plot.margin = margin(16, 16, 16, 16),
    panel.grid.minor = element_blank()
  )

# ----------------------------
# 5) Figure 1: scatter + trendline + labels
# ----------------------------
p1 <- ggplot(xy, aes(x = x, y = y, colour = region)) +
  geom_point(size = 3, alpha = 0.85) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1, colour = "steelblue") +
  geom_text_repel(
    aes(label = label),
    na.rm = TRUE,
    size = 4.3,
    box.padding = 0.6,
    point.padding = 0.35,
    min.segment.length = 0,
    max.overlaps = Inf
  ) +
  labs(
    title = "Deceased donation vs living-donor kidney transplantation (country averages, 2000–2024)",
    subtitle = subtitle_scatter,
    x = "X: Deceased donors per million population (pmp)",
    y = "Y: Living-donor kidney transplants per million population (pmp)",
    colour = "WHO region"
  ) +
  base_theme

ggsave(filename = file.path(out_dir, "fig1_scatter.png"), plot = p1, width = 13.5, height = 8.5, dpi = 300)
ggsave(filename = file.path(out_dir, "fig1_scatter.pdf"), plot = p1, width = 13.5, height = 8.5)

# ----------------------------
# 6) Figure 2: quadrant + median lines + quadrant labels + labels
# ----------------------------
# positions for quadrant text (tuned to avoid label collisions)
x_max <- max(xy$x, na.rm = TRUE)
y_max <- max(xy$y, na.rm = TRUE)

p2 <- ggplot(xy, aes(x = x, y = y, colour = region)) +
  geom_point(size = 3, alpha = 0.85) +
  geom_vline(xintercept = x_med, linetype = "dashed", linewidth = 0.9, colour = "steelblue") +
  geom_hline(yintercept = y_med, linetype = "dashed", linewidth = 0.9, colour = "steelblue") +
  # Quadrant labels (spread out)
  annotate("text", x = 0.3 * x_med, y = y_max - 1.2,
           label = "Low X / High Y\n(compensators)", hjust = 0, vjust = 1, size = 5) +
  annotate("text", x = x_max - 0.35 * (x_max - x_med), y = y_max - 1.2,
           label = "High X / High Y\n(high capacity)", hjust = 0, vjust = 1, size = 5) +
  annotate("text", x = 0.3 * x_med, y = 0.9,
           label = "Low X / Low Y\n(low overall)", hjust = 0, vjust = 0, size = 5) +
  annotate("text", x = x_max - 0.35 * (x_max - x_med), y = 0.9,
           label = "High X / Low Y\n(deceased-only)", hjust = 0, vjust = 0, size = 5) +
  geom_text_repel(
    aes(label = label),
    na.rm = TRUE,
    size = 4.3,
    box.padding = 0.6,
    point.padding = 0.35,
    min.segment.length = 0,
    max.overlaps = Inf
  ) +
  labs(
    title = "Quadrant analysis: deceased donation vs living kidney transplantation",
    subtitle = subtitle_quad,
    x = "X: Deceased donors pmp (country average, 2000–2024)",
    y = "Y: Living-donor kidney transplants pmp (country average, 2000–2024)",
    colour = "WHO region"
  ) +
  base_theme

ggsave(filename = file.path(out_dir, "fig2_quadrant.png"), plot = p2, width = 13.5, height = 8.5, dpi = 300)
ggsave(filename = file.path(out_dir, "fig2_quadrant.pdf"), plot = p2, width = 13.5, height = 8.5)

cat("Saved figures to:", out_dir, "\n")
