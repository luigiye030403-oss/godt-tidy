library(tidyverse)
library(readxl)
library(countrycode)
library(here)

raw <- read_excel(here("data", "raw", "GODT_official_download.xlsx"))

raw <- raw %>%
  mutate(POPULATION = as.numeric(gsub(",", "", POPULATION)))

wide <- raw %>%
  rename(
    region                  = REGION,
    country                 = COUNTRY,
    year                    = REPORTYEAR,
    population_m            = POPULATION,
    donor_actual_total      = `TOTAL Actual DD`,
    donor_actual_dbd        = `Actual DBD`,
    donor_actual_dcd        = `Actual DCD`,
    donor_utilized_total    = `Total Utilized DD`,
    donor_utilized_dbd      = `Utilized DBD`,
    donor_utilized_dcd      = `Utilized DCD`,
    tx_kidney_deceased      = `DD Kidney Tx`,
    tx_kidney_living        = `LD Kidney Tx`,
    tx_kidney_total         = `TOTAL Kidney Tx`,
    tx_liver_deceased       = `DD Liver Tx`,
    tx_liver_domino         = `DOMINO Liver Tx`,
    tx_liver_living         = `LD Liver Tx`,
    tx_liver_total          = `TOTAL Liver TX`,
    tx_heart_total          = `Total Heart TX`,
    tx_lung_deceased        = `DD Lung Tx`,
    tx_lung_living          = `LD Lung Tx`,
    tx_lung_total           = `TOTAL Lung Tx`,
    tx_pancreas_total       = `Pancreas Tx`,
    tx_kidneypancreas_total = `Kidney Pancreas Tx`,
    tx_smallbowel_total     = `Small Bowel Tx`
  )

indicator_cols <- setdiff(names(wide), c("region", "country", "year", "population_m"))

silent <- wide %>%
  group_by(country) %>%
  summarise(n = sum(!is.na(across(all_of(indicator_cols))))) %>%
  filter(n == 0) %>%
  pull(country)

wide <- wide %>% filter(!country %in% silent)

check_sum <- function(df, total, comps, label) {
  df %>%
    filter(!is.na(.data[[total]]), if_all(all_of(comps), ~ !is.na(.))) %>%
    mutate(expected = rowSums(across(all_of(comps))),
           diff = .data[[total]] - expected) %>%
    filter(diff != 0) %>%
    transmute(country, year, check = label,
              value_a = .data[[total]], value_b = expected, diff)
}

check_le <- function(df, a, b, scale_b, label) {
  df %>%
    filter(.data[[a]] > .data[[b]] * scale_b) %>%
    transmute(country, year, check = label,
              value_a = .data[[a]],
              value_b = .data[[b]] * scale_b,
              diff    = .data[[a]] - .data[[b]] * scale_b)
}

consistency_issues <- bind_rows(
  check_sum(wide, "donor_actual_total",   c("donor_actual_dbd",   "donor_actual_dcd"),   "actual_total = dbd + dcd"),
  check_sum(wide, "donor_utilized_total", c("donor_utilized_dbd", "donor_utilized_dcd"), "utilized_total = dbd + dcd"),
  check_sum(wide, "tx_kidney_total",      c("tx_kidney_deceased", "tx_kidney_living"),   "kidney_total = DD + LD"),
  check_sum(wide, "tx_lung_total",        c("tx_lung_deceased",   "tx_lung_living"),     "lung_total = DD + LD"),
  check_le (wide, "donor_utilized_total", "donor_actual_total", 1, "utilized_total > actual_total"),
  check_le (wide, "donor_utilized_dbd",   "donor_actual_dbd",   1, "utilized_dbd > actual_dbd"),
  check_le (wide, "donor_utilized_dcd",   "donor_actual_dcd",   1, "utilized_dcd > actual_dcd"),
  check_le (wide, "tx_kidney_deceased",   "donor_actual_total", 2, "DD kidney tx > 2 x actual donors"),
  check_le (wide, "tx_liver_deceased",    "donor_actual_total", 1, "DD liver tx > actual donors"),
  check_le (wide, "tx_heart_total",       "donor_actual_total", 1, "heart tx > actual donors"),
  check_le (wide, "tx_lung_total",        "donor_actual_total", 2, "lung tx > 2 x actual donors")
)

countries <- wide %>%
  distinct(country, region) %>%
  mutate(iso3 = countrycode(country, "country.name", "iso3c")) %>%
  select(country, iso3, region) %>%
  arrange(region, country)

donors_long <- wide %>%
  select(country, year, population_m, starts_with("donor_")) %>%
  pivot_longer(
    cols           = starts_with("donor_"),
    names_to       = c("prefix", "status", "death_criterion"),
    names_sep      = "_",
    values_to      = "donors",
    values_drop_na = TRUE
  ) %>%
  select(-prefix) %>%
  mutate(donors_pmp = donors / population_m) %>%
  left_join(select(countries, country, region), by = "country") %>%
  relocate(region, .before = country) %>%
  arrange(country, year, status, death_criterion)

transplants_long <- wide %>%
  select(country, year, population_m, starts_with("tx_")) %>%
  pivot_longer(
    cols           = starts_with("tx_"),
    names_to       = c("prefix", "organ", "source"),
    names_sep      = "_",
    values_to      = "transplants",
    values_drop_na = TRUE
  ) %>%
  select(-prefix) %>%
  mutate(transplants_pmp = transplants / population_m) %>%
  left_join(select(countries, country, region), by = "country") %>%
  relocate(region, .before = country) %>%
  arrange(country, year, organ, source)

pmp_issues <- bind_rows(
  donors_long %>%
    filter(donors_pmp > 100) %>%
    transmute(country, year,
              check   = paste0("donors_pmp > 100 [", status, "_", death_criterion, "]"),
              value_a = donors_pmp,
              value_b = NA_real_,
              diff    = NA_real_),
  transplants_long %>%
    filter(transplants_pmp > 200) %>%
    transmute(country, year,
              check   = paste0("tx_pmp > 200 [", organ, "_", source, "]"),
              value_a = transplants_pmp,
              value_b = NA_real_,
              diff    = NA_real_)
)

consistency_issues <- bind_rows(consistency_issues, pmp_issues) %>%
  arrange(country, year, check)

gaps <- wide %>%
  filter(!is.na(donor_actual_total)) %>%
  group_by(country) %>%
  summarise(
    first_year = min(year),
    last_year  = max(year),
    has_gaps   = n() < (last_year - first_year + 1),
    .groups = "drop"
  )

coverage <- wide %>%
  group_by(country, region) %>%
  summarise(
    years_total       = n(),
    n_donor_years     = sum(!is.na(donor_actual_total)),
    n_kidney_tx_years = sum(!is.na(tx_kidney_total)),
    n_liver_tx_years  = sum(!is.na(tx_liver_total)),
    n_heart_tx_years  = sum(!is.na(tx_heart_total)),
    n_lung_tx_years   = sum(!is.na(tx_lung_total)),
    .groups = "drop"
  ) %>%
  left_join(select(gaps, country, has_gaps), by = "country") %>%
  mutate(has_gaps = replace_na(has_gaps, FALSE)) %>%
  arrange(desc(n_donor_years))

dir.create(here("data", "clean"), showWarnings = FALSE, recursive = TRUE)

write_csv(countries,          here("data", "clean", "countries.csv"))
write_csv(wide,               here("data", "clean", "godt_wide.csv"))
write_csv(donors_long,        here("data", "clean", "godt_donors_long.csv"))
write_csv(transplants_long,   here("data", "clean", "godt_transplants_long.csv"))
write_csv(consistency_issues, here("data", "clean", "consistency_issues.csv"))
write_csv(coverage,           here("data", "clean", "coverage.csv"))
