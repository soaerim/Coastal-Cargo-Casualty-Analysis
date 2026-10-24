# Coastal Cargo Vessel Casualty Analysis

**Reproducible Stata code for analyzing human casualty occurrence and severity in coastal cargo vessel accidents in Korean waters (2014–2023)**

This repository contains the analysis code associated with a research manuscript on factors associated with human casualty occurrence and casualty severity in accidents involving coastal cargo vessels in Korean waters.

The code is provided to document the data-processing decisions, model specifications, supplementary analyses, and estimation procedures. **The underlying accident-level dataset is not included in this repository.** Consequently, independent execution requires authorized access to the corresponding dataset.

## Study overview

- **Study period:** 2014–2023
- **Geographic scope:** Korean waters, as defined in the study dataset
- **Vessel categories:** General cargo vessels, tankers, tugboats, and barges
- **Unit of observation:** Vessel–accident record (a single accident event may involve multiple vessels)
- **Original analytical dataset:** 3,144 vessel–accident records
- **Casualty outcomes:** 2,867 records with no human casualty, 187 injury records, and 90 death/missing records
- **Statistical approach:** Binary logistic regression and a partial proportional odds (PPO) model, supplemented by cross-tabulations and sensitivity analyses

The estimates describe **associations among recorded vessel–accident observations**, not causal effects or population-level accident rates. In particular, the analysis does not include a denominator for vessel exposure, such as operating hours, voyages, or distance traveled.

## Repository contents

| File | Description |
| --- | --- |
| [`coastal_casualty_Analysis(261025).do`](./coastal_casualty_Analysis%28261025%29.do) | Integrated Stata analysis: data preparation, descriptive statistics, accident-type cross-tabulations, primary models, and reduced-model sensitivity analyses |
| `README.md` | Documentation of the research code and execution requirements |

The do-file contains detailed **Korean-language comments** explaining the variable definitions and individual analysis steps.

## Outcome definitions

The source workbook contains three related outcome variables:

| Variable in the do-file | Definition |
| --- | --- |
| `casualty_any` | 0 = no human casualty; 1 = injury, death, or missing person |
| `severity` | 0 = no human casualty; 1 = injury; 2 = death/missing |
| `fatal` | Among casualty-positive observations: 0 = injury; 1 = death/missing |

Where more than one casualty outcome is recorded for a vessel–accident observation, the severity classification represents the most severe outcome.

## Analysis specifications

| Analysis | Outcome / purpose | Regression sample |
| --- | --- | ---: |
| **Model 1** | Binary logistic regression of any human casualty | 3,079 |
| **Model 1-A** | Model 1 with vessel age added | 2,404 |
| **Model 2** | Binary logistic regression of death/missing versus injury, restricted to casualty-positive observations | 273 |
| **Model 3 (PPO)** | Ordered casualty severity with selected nonparallel vessel-type effects | 3,079 |
| **Model 1-S** | Model 1 re-estimated after excluding two safety-accident categories | 2,847 |
| **Reduced Model 2: A / B** | Parsimonious sensitivity specifications using the same complete-case sample as Model 2 | 273 |
| **Reduced Model 1-S: A / B** | Parsimonious sensitivity specifications using the same complete-case sample as Model 1-S | 2,847 |

The regressions use **accident-event-level cluster-robust standard errors** via `vce(cluster case_id)` or the corresponding `gologit2` cluster option, accounting for multiple vessel records from the same accident event.

### Partial proportional odds model

The ordered outcome has two cumulative thresholds:

1. **Threshold 1:** Injury or death/missing versus no casualty.
2. **Threshold 2:** Death/missing versus no casualty or injury.

**Threshold 2 is not conditional on casualty occurrence.** The conditional comparison between death/missing and injury is conducted separately in **Model 2**.

### Accident-type sensitivity analysis

The code reports casualty severity by recorded accident type and groups two original classifications—`안전사고` and `안전사고(인명사상)`—as safety-accident categories. These categories account for **235 of 3,144 observations** and **220 of 277 casualty-positive observations** in the original data.

The safety-excluded regression uses **2,847 complete-case records**, including **56 casualty-positive records**. The 57 casualty-positive records obtained immediately after excluding safety accidents differ by one because of covariate missingness in the regression sample.

### Parsimonious specifications

For both Model 2 and Model 1-S:

- **Reduced A:** Vessel type, log gross tonnage, multi-vessel accident indicator, and year (six slope coefficients).
- **Reduced B:** Reduced A plus a binary indicator for 04:00–08:00 (seven slope coefficients).

The original full models include vessel type, log gross tonnage, multi-vessel indicator, time-of-day bands, season, accident area, and year (17 slope coefficients).

**Important:** The full model compares 04:00–08:00 with 08:00–12:00, whereas Reduced B compares 04:00–08:00 with all other time periods. Those two time coefficients do **not** represent identical contrasts.

## Software requirements

- **Stata 15.1 or later**, as declared in the do-file.
- The user-written Stata command **`gologit2`** for the PPO model.
- Access to the original Excel analysis workbook with the expected sheet name and Korean variable headers.

The do-file attempts to install `gologit2` from SSC if it is unavailable. Installation may require internet access and appropriate permissions. If `gologit2` cannot be installed, the script skips the PPO estimation.

## How to run

1. Download the [Stata do-file](./coastal_casualty_Analysis%28261025%29.do).
2. Obtain authorized access to the source Excel workbook. It is **not distributed here**.
3. Save the workbook in the working directory, or edit the `ROOT` and `DATA` settings near the beginning of the do-file.
4. Check that the required worksheet and Korean column names match those expected by the code.
5. Open the do-file in the Stata Do-file Editor and run it from the beginning.

The current file settings are:

```stata
global ROOT "."
cd "$ROOT"
global DATA "최근10년_해양사고_국내영해_분석용_3.3_4.1_최종표.xlsx"
global OUT "output"
local RUN_PPO 1
local RUN_MNL 0
```

The default configuration runs the PPO model and skips the optional multinomial logit (MNL) analysis. The source Excel workbook must retain the worksheet `분석데이터_국내영해` and the expected original column names.

The integrated do-file uses complete-case samples for regression analyses; sample sizes therefore differ from the original 3,144 observations.

## Generated outputs

When execution completes successfully, the do-file writes these files into the `output/` subdirectory:

| Output | Contents |
| --- | --- |
| `coastal_casualty_integrated.log` | Stata results log, including model estimates and statistical tests |
| `accident_type_severity_full.csv` | Full accident-type × severity frequency table |
| `accident_type_severity_compact.csv` | Condensed accident-type × severity table for manuscript reporting |
| `coastal_casualty_analysis_final.dta` | Processed analytical data containing generated variables |

**Note:** Model comparison tables displayed by Stata's `estimates table` command contain **log-odds coefficients**, not odds ratios. The `logistic` estimation outputs provide odds ratios and confidence intervals for manuscript reporting.

## Data availability and reproducibility

The analytical dataset is not included in this public repository. Availability of the underlying Korean maritime accident records and permission to redistribute derived datasets must be assessed under the relevant data-provider terms and institutional requirements.

The script documents the analysis workflow but **code availability alone does not constitute full data-and-code reproducibility**. Running the script requires a compatible, lawfully obtained input workbook. The expected sample totals and model specifications are documented above to facilitate independent checks.

## Citation and manuscript information

This repository is intended to accompany a research manuscript concerning casualty occurrence and severity in Korean coastal cargo vessel accidents. **The final journal citation and DOI should be added after publication.**

When referencing the analysis code before publication, please link to this repository:

https://github.com/soaerim/Coastal-Cargo-Casualty-Analysis

For a fixed, citable software version, consider creating a GitHub release after the manuscript and code have been finalized.

## Code availability statement

> The Stata code for data preparation, model estimation, and sensitivity analyses is publicly available at https://github.com/soaerim/Coastal-Cargo-Casualty-Analysis. The analytical dataset is not distributed in the repository; access and redistribution are subject to the applicable data-provider and institutional conditions.

## Limitations

These analyses are based on **recorded accidents**, not on all vessel operations. Consequently, findings concern the relative severity of observed accident outcomes rather than the probability of an accident occurring during a voyage. Model 2 and the safety-excluded models also contain relatively few outcome events, so their coefficients and confidence intervals should be interpreted cautiously.

---

**Repository maintenance:** Please update this README when the published paper title, DOI, data access conditions, or final analysis code change.
