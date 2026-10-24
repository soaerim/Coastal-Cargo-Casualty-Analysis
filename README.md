# Coastal Cargo Vessel Casualty Analysis

**연구 주제:** 내항화물선 해양사고의 인명피해 발생 및 피해 심각도 관련요인 분석: 단계별 위험구조와 사고유형 민감도를 중심으로

**언어 / Language:** [한국어](#한국어-안내) · [English](#english-documentation)

## 한국어 안내

### 1. 저장소 소개

본 저장소는 **2014~2023년 국내 내항화물선 해양사고**를 대상으로 인명피해의 발생 여부와 피해 심각도 관련요인을 분석한 연구의 **Stata 분석 코드(do-file)**를 공개하기 위한 공간입니다. 연구에 사용된 자료 처리 방식, 모형 사양, 사고유형별 교차표 및 민감도 분석 절차를 문서화하여 분석의 투명성과 검증 가능성을 높이고자 합니다.

**본 저장소에는 해양사고 원자료 또는 분석용 Excel 파일이 포함되어 있지 않습니다.** 코드를 독립적으로 실행하려면 이용 권한이 있는 호환 원자료가 필요합니다. 따라서 분석 코드의 공개와 데이터까지 포함한 완전한 재현은 구분해야 합니다.

### 2. 연구 개요

| 구분 | 내용 |
| --- | --- |
| 분석기간 | 2014~2023년 |
| 공간적 범위 | 분석자료에서 정의한 국내 해역 |
| 대상 선종 | 일반화물선, 유조선, 예인선, 부선 |
| 분석단위 | 선박-사고 관측치(vessel–accident observation) |
| 전체 관측치 | 3,144건 |
| 인명피해 분포 | 무인명피해 2,867건 / 부상 187건 / 사망·실종 90건 |
| 통계분석 | 이항 로지스틱 회귀분석, 부분비례승산모형(PPO), 사고유형 교차분석 및 민감도 분석 |
| 표준오차 | 사고번호 기준 군집강건표준오차(cluster-robust standard errors) |

하나의 사고 사건에 복수의 선박이 포함될 수 있으므로, 분석단위인 **선박-사고 관측치의 수는 고유 사고 사건의 수와 다를 수 있습니다.**

### 3. 파일 구성

| 파일 | 설명 |
| --- | --- |
| [coastal_casualty_Analysis(261025).do](./coastal_casualty_Analysis%28261025%29.do) | 자료 불러오기, 변수 생성, 기초통계, 사고유형 교차표, 회귀모형, PPO 및 축약모형 추정 등을 수행하는 통합 분석 코드 |
| README.md | 연구 개요와 변수 정의, 분석방법, 실행 방법 및 데이터 공개 범위 안내 |

do-file에는 각 분석의 목적, 변수의 기준범주와 모형 해석 시 주의사항을 **한글 주석**으로 작성하였습니다.

### 4. 주요 종속변수

| 변수명 | 정의 |
| --- | --- |
| **casualty_any** | 0 = 인명피해 없음 / 1 = 부상 또는 사망·실종 발생 |
| **severity** | 0 = 인명피해 없음 / 1 = 부상 / 2 = 사망·실종 |
| **fatal** | 인명피해 발생 사례에 한정하여 0 = 부상 / 1 = 사망·실종 |

하나의 관측치에서 복수 유형의 인명피해가 발생한 경우에는 **가장 높은 피해심각도**를 기준으로 분류합니다.

### 5. 분석모형

| 모형 | 분석 목적 | 회귀분석 표본 |
| --- | --- | ---: |
| **Model 1** | 전체 관측치에서 인명피해 발생 여부 분석(이항 로짓) | 3,079건 |
| **Model 1-A** | Model 1에 선령을 추가한 확장모형 | 2,404건 |
| **Model 2** | 인명피해 발생 관측치에서 부상 대비 사망·실종 여부 분석(이항 로짓) | 273건 |
| **Model 3 (PPO)** | 무인명피해·부상·사망실종의 순서형 피해심각도 분석 | 3,079건 |
| **Model 1-S** | 안전사고 계열 제외 후 인명피해 발생 여부 재추정 | 2,847건 |
| **Model 2 축약모형 A/B** | 적은 사망·실종 사건 수를 고려한 모형 사양의 민감도 검토 | 각 273건 |
| **Model 1-S 축약모형 A/B** | 안전사고 제외 표본에서 설명변수 축소에 따른 추정결과 비교 | 각 2,847건 |

#### PPO 모형의 두 누적경계

- **Threshold 1:** 무인명피해(0) 대 부상·사망/실종(1·2)
- **Threshold 2:** 무인명피해·부상(0·1) 대 사망/실종(2)

**Threshold 2는 인명피해가 이미 발생한 사고만을 대상으로 한 조건부 분석이 아닙니다.** 인명피해가 발생한 사례에서 부상과 사망·실종을 직접 비교하는 분석은 **Model 2**에 해당합니다.

#### 사고유형별 교차표 및 안전사고 제외 분석

원자료의 두 유형인 **‘안전사고’**와 **‘안전사고(인명사상)’**를 안전사고 계열로 정의합니다. 두 유형은 전체 3,144개 관측치 중 **235건**이며, 전체 인명피해 발생 관측치 277건 중 **220건(79.4%)**을 차지합니다.

안전사고 계열을 제외한 원자료의 인명피해 관측치는 57건이나, 설명변수 결측치를 제외한 **Model 1-S의 실제 회귀분석 표본에는 56건**이 포함됩니다. 원자료 교차표의 빈도와 회귀분석에 사용한 완전사례 표본을 구분하여 해석해야 합니다.

#### 축약모형의 구성

- **Reduced A:** 선종, ln(총톤수), 다선박 사고 여부, 발생연도(기울기 계수 6개)
- **Reduced B:** Reduced A에 04:00~08:00 시간대 여부 더미를 추가(기울기 계수 7개)
- **전체모형(Full):** 선종, ln(총톤수), 다선박 여부, 6개 시간대, 계절, 해역, 연도(기울기 계수 17개)

축약모형은 **각 전체모형과 동일한 완전사례 표본**에서 추정합니다. 단, 전체모형의 04:00~08:00 시간대는 **08:00~12:00 대비**, Reduced B는 **그 외 모든 시간대 대비**이므로 두 시간대 오즈비를 같은 기준으로 직접 비교해서는 안 됩니다.

### 6. 실행 환경 및 방법

**필요한 환경**

- Stata **15.1 이상**
- PPO 모형 추정을 위한 사용자 작성 명령어 **gologit2**
- do-file에서 요구하는 시트 및 한글 열 이름을 갖춘 **이용 권한이 있는 Excel 원자료**

**실행 순서**

1. GitHub에서 [통합 Stata do-file](./coastal_casualty_Analysis%28261025%29.do)을 내려받습니다.
2. 별도로 확보한 Excel 분석자료를 작업 폴더에 저장합니다.
3. do-file 상단의 **ROOT**, **DATA** 경로 및 파일명을 확인합니다.
4. 원자료에 **분석데이터_국내영해** 시트와 예상 변수명이 있는지 확인합니다.
5. Stata **Do-file Editor에서 파일 전체를 실행**합니다. 명령문이나 중괄호 구문을 임의로 한 줄씩 실행하지 않는 것을 권장합니다.
6. 출력된 표본 수, 오즈비(OR), 유의확률 및 군집강건표준오차 적용 여부를 논문과 대조합니다.

현재 코드의 주요 설정은 다음과 같습니다.

~~~stata
global ROOT "."
cd "$ROOT"
global DATA "최근10년_해양사고_국내영해_분석용_3.3_4.1_최종표.xlsx"
global OUT "output"
local RUN_PPO 1
local RUN_MNL 0
~~~

**gologit2**가 설치되지 않았다면 코드는 SSC를 통한 설치를 시도하며, 설치가 불가능할 때에는 PPO 모형을 건너뜁니다. 선택적 다항로짓(MNL)은 기본 설정에서 실행하지 않습니다.

### 7. 실행 결과 파일

정상적으로 실행되면 작업 폴더 아래 **output/** 폴더에 다음 파일이 생성됩니다.

| 파일명 | 내용 |
| --- | --- |
| **coastal_casualty_integrated.log** | 기술통계, 회귀추정 및 검정 결과가 기록된 Stata 로그 |
| **accident_type_severity_full.csv** | 사고유형 전체 × 피해심각도 교차표 |
| **accident_type_severity_compact.csv** | 논문 본문용 사고유형별 압축 교차표 |
| **coastal_casualty_analysis_final.dta** | 변수 생성 및 분석 준비가 완료된 Stata 자료 |

Stata의 **estimates table** 출력은 기본적으로 로그오즈(log-odds) 계수이며, 논문에 제시하는 오즈비(OR)와 구분해야 합니다. 오즈비 및 신뢰구간은 **logistic** 추정결과 등을 확인하시기 바랍니다.

### 8. 자료 공개와 재현성

본 저장소는 **분석 코드만 공개**하며, 해양사고 원자료, 선박별 기록 및 분석용 Excel 자료는 공개하지 않습니다. 원자료의 이용 및 제3자 재배포 가능 여부는 관련 자료 제공기관의 이용조건과 소속기관의 규정에 따라 별도로 확인해야 합니다.

원자료를 제공하지 않으므로, 저장소의 코드만으로 모든 분석을 즉시 재현할 수 있는 것은 아닙니다. 다만 **변수 정의, 모형 사양, 기대 표본 수, 분석 절차 및 출력 구조**를 공개하여 검증 가능성을 높이고자 합니다.

아울러 분석 결과는 **이미 발생하여 기록된 사고의 인명피해 결과에 대한 관련성**을 나타냅니다. 운항시간·운항거리·운항횟수 등 사고 노출량을 직접 고려하지 못했으므로 선박의 사고 발생률이나 특정 요인의 인과적 효과로 해석해서는 안 됩니다. Model 2와 안전사고 제외 분석은 결과 사건 수가 적어 추정의 불확실성에 유의해야 합니다.

### 9. 논문 및 코드 인용

**연구 제목(원고):** 「내항화물선 해양사고의 인명피해 발생 및 피해 심각도 관련요인 분석: 단계별 위험구조와 사고유형 민감도를 중심으로」

저널명, 권·호, 페이지 및 DOI는 **논문 게재 확정 후 추가할 예정**입니다. 현재 코드를 인용하거나 확인할 때는 다음 저장소 주소를 사용합니다.

https://github.com/soaerim/Coastal-Cargo-Casualty-Analysis

향후 최종 투고·게재 버전을 확정하면 GitHub **Release**를 생성하여 분석 코드의 버전을 고정하는 것을 권장합니다.

**논문에 활용 가능한 코드 공개 문구**

> 본 연구의 자료 전처리, 회귀모형 추정 및 민감도 분석에 사용한 Stata 분석 코드는 GitHub(https://github.com/soaerim/Coastal-Cargo-Casualty-Analysis)에 공개하였다. 다만 분석에 사용한 원자료는 관련 이용조건 및 재배포 제한에 따라 저장소에 포함하지 않았다.

---


## English documentation

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
