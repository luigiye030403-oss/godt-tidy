# GODT cleaned data

This folder has the cleaned version of the GODT data (WHO / ONT, 2000 to 2024). The cleaning is done in `scripts/01_data_cleaning.R`. The raw file is in `../raw/`.

## Which file to open

If you want to make plots or do any analysis, use the long tables:

- `godt_donors_long.csv` - one row per donor observation
- `godt_transplants_long.csv` - one row per transplant observation

These two do not have any NA in the count column, because we dropped the missing rows when reshaping. So you don't really need to think about NAs when using them.

If you want to look up a specific country-year, or do math across columns in the same row, use `godt_wide.csv`. This one has NAs because not every country reports every indicator. This is expected. Please do not fill the NAs with 0, because "a country did not report" and "a country reported zero" are different things.

To decide which countries have enough data for your analysis, check `coverage.csv`. It tells you how many years each country reported for donors, kidney tx, liver tx, etc. There is also a column `has_gaps` which is TRUE if the country reported some years but skipped others in between.

`countries.csv` is just a lookup table (country, iso3 code, region). Useful if you want to join with another dataset, for example World Bank data.

`consistency_issues.csv` is a list of rows where something looks off (either the numbers don't add up, or they are medically implausible). We did not remove these rows from the cleaned data, we just flagged them. Some of them are actual errors, some are real medical phenomena. More details in `issues_log.md`.

## Columns

The wide table has columns like `donor_actual_dbd` or `tx_kidney_deceased`. We used this pattern on purpose so that `pivot_longer` can split them automatically.

For donors:

- `status` is either `actual` (organs were recovered from the donor) or `utilized` (organs were actually transplanted)
- `death_criterion` is `dbd` (brain death), `dcd` (circulatory death), or `total`

For transplants:

- `organ` is one of kidney / liver / heart / lung / pancreas / kidneypancreas / smallbowel
- `source` is deceased / living / domino / total

`population_m` is country population in millions. We also computed `donors_pmp` and `transplants_pmp`, which are the per-million-population rates. This is the standard way to compare across countries (Spain with 47 million people cannot be directly compared to USA with 330 million otherwise).

## A quick example

```r
library(tidyverse)

donors      <- read_csv("data/clean/godt_donors_long.csv")
transplants <- read_csv("data/clean/godt_transplants_long.csv")
coverage    <- read_csv("data/clean/coverage.csv")

# keep only countries with at least 15 years of kidney tx data
good <- coverage %>% filter(n_kidney_tx_years >= 15) %>% pull(country)

transplants %>%
  filter(country %in% good, organ == "kidney", source == "total") %>%
  ggplot(aes(year, transplants_pmp, colour = region)) +
  geom_line(aes(group = country), alpha = 0.4) +
  geom_smooth(se = FALSE)
```

## Things to be careful about

- The long tables still contain rows where `death_criterion == "total"` or `source == "total"`. If you just sum everything, you will double count, because the total is supposed to equal DBD + DCD (or deceased + living). So either filter `!= "total"` if you want the mutually exclusive breakdown, or filter `== "total"` if you want the top-line number.
- Do not fill NAs in the wide table with 0. A country not reporting is not the same thing as a country reporting 0.
- We dropped 68 countries that never reported anything in 25 years. They are still in `../raw/` if you want to look at reporting coverage as a research question.
- The number of countries reporting grows a lot over time (about 30 in 2000, about 100 after 2015). So if you plot a global trend and it goes up, part of that increase is just more countries joining the registry. Better to fix a set of countries, or aggregate per country first.
- See `issues_log.md` for the full list of problems we hit during cleaning and what we did with them.
