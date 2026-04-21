# Issues we found and what we did about them

This is a log of the main problems we hit while cleaning the raw GODT data, and how we handled each one.

### 1. Population was stored as text

The `POPULATION` column in the Excel file was stored as text instead of a number. Most of the values looked normal (like `"47.4"`), but the values for China and India had thousands separators in them (`"1,277.60"` and `"1,013.70"`). If you just run `as.numeric()` on those, they become NA, which would make us lose China and India completely from any analysis that uses population. So we strip the comma first, and then convert. After that, zero values are missing.

### 2. Column names were a mess

The raw names are not consistent at all. Some use all caps, some use mixed case, some have spaces. For example: `"TOTAL Actual DD"`, `"Actual DBD"`, `"DD Kidney Tx"`, `"TOTAL Liver TX"`. Even the casing of "Tx" vs "TX" changes from one column to another. We renamed everything to one consistent pattern:

- donor columns: `donor_{status}_{criterion}`, for example `donor_actual_dbd`
- transplant columns: `tx_{organ}_{source}`, for example `tx_kidney_deceased`

Two of the organ names had a space inside them (`"Kidney Pancreas"` and `"Small Bowel"`). We wrote those as one word (`kidneypancreas` and `smallbowel`) so that underscore stays a clean separator. Otherwise `pivot_longer` would split the name in the wrong place.

### 3. Column names encoded more than one variable

This is actually the main "untidy data" problem that Wickham talks about. A column name like `"DD Kidney Tx"` means two things at the same time: the organ is kidney, and the donor source is DD (deceased). After we renamed everything to `tx_kidney_deceased`, we can use `pivot_longer(names_sep = "_")`, which splits the name into three parts and gives us proper separate columns for `organ` and `source`.

### 4. The raw table mixes different kinds of things

The raw file has donor counts, transplant counts, country region, and population all in the same table. These are really different types of observations. Tidy data says each type of thing should have its own table. So we split into:

- `countries.csv`: country, iso3, region
- `godt_donors_long.csv`: donor observations
- `godt_transplants_long.csv`: transplant observations

We also kept `godt_wide.csv`, which is not strictly tidy but is convenient for lookups.

### 5. Some countries never report anything

Out of 194 countries in the WHO list, 68 of them have not reported a single value in all 25 years. They just make the table bigger with 25 empty rows per country. We removed them from the cleaned files. They are still present in the raw file, so if anyone wants to study the question "who does not report", they can find them there.

### 6. Reported totals do not always match the parts

Some country-years have `donor_actual_total` that is not equal to `dbd + dcd` added together. The same thing happens with `kidney_total` vs `DD + LD`. We ran 4 of these checks and found 24 rows that do not add up. We did NOT try to fix them automatically, because the real value could be either the reported total or the sum. We saved these rows in `consistency_issues.csv` so that anyone using those specific country-years can know and decide.

### 7. Medical plausibility checks

We added a few "this should not be possible physically" checks. We found 56 rows with problems in total.

- `utilized > actual` (3 rows). A donor from whom no organ was recovered cannot have an organ utilized. This is just impossible. Example: Nicaragua 2017 says 0 actual DCD donors but 1 utilized DCD donor. These look like data entry errors.
- `DD liver tx > actual donors` (26 rows, mostly Germany, Sweden, Portugal). At first this seems impossible because each donor has only one liver. But actually this is a real medical thing called split-liver transplantation. One donor liver is divided into two pieces, and each piece is given to a different recipient (usually one adult and one child). So these rows are not really errors, they just reflect that split livers happen.
- `DD kidney tx > 2 × actual donors` (27 rows, mostly Luxembourg, Sweden, UAE, Estonia). Small countries like Luxembourg are part of Eurotransplant, which means they can receive kidneys that were donated in another country. The transplant operation happens in Luxembourg but the donor is counted in another country. So these rows are not errors either, they are just showing organ imports.

We flagged all 56 rows in `consistency_issues.csv` but we did not remove them. The goal of cleaning is not to delete the weird rows, it's to make sure we know that they are weird.

### 8. PMP sanity check

We also flagged rows where `donors_pmp > 100` or `transplants_pmp > 200`. The reason is that Spain (the world record for donation rate) is around 50 pmp for donors. Anything way above that would be a calculation error, for example using population in thousands instead of millions. It turned out that 0 rows failed this check, which is actually a good sign. The per-million rates look clean.

### 9. Reporting gaps

Some countries report for a few years, then skip one year, then report again. For example, Australia reports 2000 to 2004, skips 2005, then reports 2006 onward. This is different from a country that only started reporting in a later year. We added a `has_gaps` column to `coverage.csv` which is TRUE if the country has at least one gap in its donor time series. Out of 124 donor-reporting countries, 61 have at least one gap. If someone makes time-series plots, they probably want to filter to `has_gaps == FALSE`, or otherwise be careful.

### 10. Lots of missing values

About 55 to 75 percent of the cells in the raw wide table are NA. There are two main reasons. Smaller and poorer countries often do not report, and also a lot of countries only started reporting in more recent years. We handled this as follows:

- The long tables drop NA rows at the reshape step (`values_drop_na = TRUE`). So if a country did not report kidney transplants for a given year, that row simply does not exist in the long table. No NA in the count column.
- The wide table keeps NAs as they are, so that it is honest about what is missing.
- We made `coverage.csv` to help the analysis team pick countries that have enough data for whatever question they are working on.

### 11. More countries join the registry over time

In 2000, only about 30 countries reported the main indicators. By 2015 it was about 100. This is not really a cleaning problem, but it matters for any global trend. If you plot a worldwide line and it goes up, part of the increase is just more countries joining. The analysis team should probably fix a country set, or do per-country trends and aggregate afterwards.

### 12. The export is actually 6 files

The GODT website export tool only lets you download one WHO region at a time. So the "all countries" file is really 6 regional files stitched together. Our downloaded copy is already the combined version, so we did not need to combine anything. Just mentioning it here in case anyone tries to re-download.
