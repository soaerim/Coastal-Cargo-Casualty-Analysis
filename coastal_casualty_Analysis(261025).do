
*******************************************************************************
* 국내 해역 일반화물선·유조선·예인선·부선 해양사고 인명피해 분석
* 통합 Stata Do-file - 한 줄 명령어 방식
** Reproducible Stata do-file
*
* 연구기간/대상: 2014~2023년 / 국내 해역에서 발생한 4개 선종의 사고
* 표본 선정: 사고 발생 해역과 선종 기준(선박 국적/내항·외항 사업등록 무관)
* 외국적 선박 포함. 국적·운항형태 미통제 관련성은 인과효과로 해석하지 않음
* 자료 입력: 별도 전처리에서 선종 표준화를 완료한 Excel 분석자료
* 원자료 분류정비: 기타선(부선) 226건 부선 통합, 기타선 188건 부선·4건 예인선 재분류
* 재분류 원칙: 단일선박 사건이고 사건명으로 선종을 명확하게 식별한 경우에 한함
* 위 건수는 전체 원자료 기준이며 이 do-file은 원자료 표준화를 재실행하지 않음
* 인명피해: 사고 전체 값을 복수 선박에 배분하지 않고 선박별 귀속값 사용
* 분석단위: 선박-사고 관측치
* 군집표준오차: 사고 사건번호(case_id) 기준
*
* 포함 분석
* 1. 기술통계
* 2. 사고유형별 피해심각도 교차표
* 3. Model 1: 인명피해 발생 여부
* 4. Model 1-A: 선령 추가
* 5. Model 2: 인명피해 발생 시 사망·실종 여부
* 6. Model 3: PPO 모형
* 7. Model 1-S: 안전사고 계열 제외
* 8. Model 2 및 Model 1-S 축약모형
*
* 주의: 모든 분석 명령어를 한 줄로 작성함.
*******************************************************************************

version 15.1
clear all
set more off
set linesize 255


*==============================================================================
* 0. 분석 환경 및 파일 경로
*==============================================================================

* ROOT: 원자료가 있는 폴더
* DATA: 원자료 Excel 파일
* OUT : 결과 저장 폴더

global ROOT "."
cd "$ROOT"

global DATA "최근10년_해양사고_국내영해_분석용_3.3_4.1_최종표.xlsx"
global OUT "output"

* 선택 분석 실행 여부
* 1 = 실행 / 0 = 미실행

local RUN_PPO 1
local RUN_MNL 0

capture confirm file "$DATA"

if _rc {
    display as error "원자료 Excel 파일을 찾을 수 없습니다."
    display as error "작업 폴더와 파일명을 확인하세요."
    pwd
    exit 601
}

capture mkdir "$OUT"
capture log close _all

log using "$OUT/coastal_casualty_integrated.log", text replace

display as result "=============================================================="
display as result "국내 해역 4개 선종 해양사고 인명피해 분석 시작"
display as result "=============================================================="


*==============================================================================
* 1. 원자료 불러오기 및 변수명 통일
*==============================================================================

* 원자료의 분석 시트를 불러온다.
* Excel 첫 행을 변수명으로 사용한다.

import excel using "$DATA", sheet("분석데이터_국내영해") firstrow clear

* 사고 식별정보
rename 사건번호 case_id_raw
rename 사건명 case_name
rename 사고유형 accident_type

* 발생 시점 및 해역
rename 연도 year
rename 시간대 time_group
rename 계절 season
rename 발생해역 area
rename 세부해역 area_detail

* 선박 특성
rename 선박명 vessel_name
rename 선령 age
rename 총톤수 gt
rename 선종 ship_type

* 사고 및 인명피해 정보
rename 사건정보결측 case_info_missing
rename 다선박여부 multi_vessel
rename 인명피해여부 casualty_any
rename 피해심각도 severity
rename 사망실종여부 fatal

* 분석용 파생변수
rename ln_총톤수 ln_gt
rename 선령결측 age_missing
rename 총톤수_유효 gt_valid

capture rename no record_no

* 중요사항 : 이 논문은 동일 사고에 포함된 여러 선박을 하나의 사고번호로 묶었따. 
* 회귀분석에서는 사고번호별 군집표준오차를 사용한다.

egen long case_id = group(case_id_raw)


*==============================================================================
* 2. 회귀분석용 범주형 변수 생성
*==============================================================================


*------------------------------------------------------------------------------
* 2.1 선종
*------------------------------------------------------------------------------
*
* 기준집단: 일반화물선(1)
*
* 1 일반화물선
* 2 유조선
* 3 예인선
* 4 부선
*
* 선종의 오즈비는 일반화물선 대비 상대적인 오즈를 의미한다.
*------------------------------------------------------------------------------

gen byte ship_type_n = .

replace ship_type_n = 1 if inlist(ship_type, "화물선", "일반화물선")
replace ship_type_n = 2 if ship_type == "유조선"
replace ship_type_n = 3 if ship_type == "예인선"
replace ship_type_n = 4 if ship_type == "부선"

label define ship_lbl 1 "General cargo vessel" 2 "Tanker" 3 "Tugboat" 4 "Barge", replace
label values ship_type_n ship_lbl


*------------------------------------------------------------------------------
* 2.2 사고 발생 시간대
*------------------------------------------------------------------------------
*
* 하루를 4시간 단위로 구분한다.
* 기준집단: 08:00~12:00(3)
*
* 시간대별 사고 노출량을 통제하지 못하므로
* 시간대 효과를 안전성의 인과효과로 해석하지 않는다.
*------------------------------------------------------------------------------

gen byte time_n = .

replace time_n = 1 if time_group == "0-4시"
replace time_n = 2 if time_group == "4-8시"
replace time_n = 3 if time_group == "8-12시"
replace time_n = 4 if time_group == "12-16시"
replace time_n = 5 if time_group == "16-20시"
replace time_n = 6 if time_group == "20-24시"

label define time_lbl 1 "00-04" 2 "04-08" 3 "08-12" 4 "12-16" 5 "16-20" 6 "20-24", replace
label values time_n time_lbl


*------------------------------------------------------------------------------
* 2.3 계절
*------------------------------------------------------------------------------
*
* 기준집단: 봄(1)
*------------------------------------------------------------------------------

gen byte season_n = .

replace season_n = 1 if season == "봄"
replace season_n = 2 if season == "여름"
replace season_n = 3 if season == "가을"
replace season_n = 4 if season == "겨울"

label define season_lbl 1 "Spring" 2 "Summer" 3 "Autumn" 4 "Winter", replace
label values season_n season_lbl


*------------------------------------------------------------------------------
* 2.4 사고 발생 해역
*------------------------------------------------------------------------------
*
* 기준집단: 개항 및 진입수로(1)
*------------------------------------------------------------------------------

gen byte area_n = .

replace area_n = 1 if area == "개항 및 진입수로"
replace area_n = 2 if area == "남해영해"
replace area_n = 3 if area == "서해영해"
replace area_n = 4 if area == "동해영해"

label define area_lbl 1 "Port/approach" 2 "South Sea" 3 "West Sea" 4 "East Sea", replace
label values area_n area_lbl


*------------------------------------------------------------------------------
* 2.5 안전사고 계열 구분
*------------------------------------------------------------------------------
*
* 안전사고 계열:
* ① 안전사고
* ② 안전사고(인명사상)
*
* safety_accident = 1 : 안전사고 계열
* safety_accident = 0 : 그 외 사고유형
*
* 논문 4.5절의 안전사고 제외 민감도 분석에 사용한다.
*------------------------------------------------------------------------------

gen byte safety_accident = inlist(accident_type, "안전사고", "안전사고(인명사상)") if !missing(accident_type)

label define safety_lbl 0 "Other accident types" 1 "Safety accident categories", replace
label values safety_accident safety_lbl


*------------------------------------------------------------------------------
* 2.6 축약모형용 04~08시 더미
*------------------------------------------------------------------------------
*
* time_0408 = 1 : 04:00~08:00
* time_0408 = 0 : 나머지 모든 시간대
*
* 중요:
* 전체모형의 04~08시 기준집단은 08~12시이다.
* 축약모형 B의 기준집단은 04~08시를 제외한 모든 시간대이다.
* 두 OR은 기준집단이 달라 직접 비교할 수 없다.
*------------------------------------------------------------------------------

gen byte time_0408 = (time_n == 2) if !missing(time_n)

label define time0408_lbl 0 "Other hours" 1 "04:00-08:00", replace
label values time_0408 time0408_lbl


*------------------------------------------------------------------------------
* 2.7 종속변수 라벨
*------------------------------------------------------------------------------

label define severity_lbl 0 "No casualty" 1 "Injury" 2 "Death/missing", replace
label values severity severity_lbl

label define fatal_lbl 0 "Injury" 1 "Death/missing", replace
label values fatal fatal_lbl


*==============================================================================
* 3. 원자료 검증
*==============================================================================
*
* 기존 논문 표본: 총 3,144건
* 무인명피해: 2,867건
* 부상: 187건
* 사망·실종: 90건
*
* assert 명령은 예상 조건을 충족하지 못하면 실행을 중단한다.
*==============================================================================

assert _N == 3144

assert inlist(casualty_any, 0, 1) if !missing(casualty_any)
assert inlist(severity, 0, 1, 2) if !missing(severity)

assert casualty_any == 0 if severity == 0
assert casualty_any == 1 if inlist(severity, 1, 2)

assert fatal == 0 if severity == 1
assert fatal == 1 if severity == 2

quietly count if missing(ship_type_n)
assert r(N) == 0

quietly count if missing(time_n)
assert r(N) == 0

quietly count if missing(season_n)
assert r(N) == 0

quietly count if missing(area_n)
assert r(N) == 0

tab ship_type_n, missing
tab time_n, missing
tab season_n, missing
tab area_n, missing
tab multi_vessel, missing
tab casualty_any, missing
tab severity, missing

count if missing(case_id)
count if missing(multi_vessel)
count if missing(age)
count if missing(gt) | gt <= 0
count if missing(ln_gt)

display as result "원자료 검증 완료"


*==============================================================================
* 4. 기본 기술통계
*==============================================================================
*
* 선종, 시간대, 계절, 해역 및 다선박 여부에 따른
* 인명피해 발생과 피해심각도 분포를 확인한다.
*
* row 옵션은 각 범주의 행 비율을 출력한다.
*==============================================================================

tab severity
tab casualty_any

* 선종
tab ship_type_n severity, row
tab ship_type_n casualty_any, row
tab ship_type_n fatal if casualty_any == 1, row

* 시간대
tab time_n severity, row
tab time_n casualty_any, row
tab time_n fatal if casualty_any == 1, row

* 계절
tab season_n severity, row
tab season_n casualty_any, row
tab season_n fatal if casualty_any == 1, row

* 해역
tab area_n severity, row
tab area_n casualty_any, row
tab area_n fatal if casualty_any == 1, row

* 다선박 여부
tab multi_vessel severity, row
tab multi_vessel casualty_any, row
tab multi_vessel fatal if casualty_any == 1, row


*==============================================================================
* 5. 사고유형별 피해심각도 교차표(심사의견 반영한 부분)
*==============================================================================
*
* 심사위원 1의 대응 분석
*
* 사고유형별로 무인명피해, 부상, 사망·실종이
* 어떻게 분포하는지 확인한다.
*
* 분석단위는 선박-사고 관측치이다.
*==============================================================================

display as result "=============================================================="
display as result "사고유형별 피해심각도 교차표"
display as result "=============================================================="

tab accident_type severity, row
tab safety_accident severity, row
tab safety_accident casualty_any, row
tab accident_type severity if safety_accident == 1, row


*------------------------------------------------------------------------------
* 5.1 안전사고 계열의 표본 및 인명피해 집중도
*------------------------------------------------------------------------------
*
* 안전사고 계열의 표본 비중과 인명피해 집중도를 계산한다.
*
* 기존 분석 참고값:
* 안전사고 계열 235건
* 안전사고 계열 인명피해 220건
* 전체 인명피해 277건
*------------------------------------------------------------------------------

quietly count
local N_all = r(N)

quietly count if casualty_any == 1
local N_cas = r(N)

quietly count if severity == 2
local N_fatal = r(N)

quietly count if safety_accident == 1
local N_safety = r(N)

quietly count if safety_accident == 1 & casualty_any == 1
local N_safety_cas = r(N)

quietly count if safety_accident == 1 & severity == 2
local N_safety_fatal = r(N)

display as result "전체 관측치: " `N_all'
display as result "전체 인명피해 관측치: " `N_cas'
display as result "전체 사망·실종 관측치: " `N_fatal'

display as result "안전사고 계열 관측치: " `N_safety'
display as result "안전사고 계열 인명피해: " `N_safety_cas'
display as result "안전사고 계열 사망·실종: " `N_safety_fatal'

display as result "안전사고 표본 비중(%): " %6.2f (100*`N_safety'/`N_all')
display as result "인명피해 중 안전사고 비중(%): " %6.2f (100*`N_safety_cas'/`N_cas')
display as result "사망·실종 중 안전사고 비중(%): " %6.2f (100*`N_safety_fatal'/`N_fatal')


*------------------------------------------------------------------------------
* 5.2 전체 사고유형 교차표 CSV
*------------------------------------------------------------------------------
*
* n0: 무인명피해
* n1: 부상
* n2: 사망·실종
*
* preserve/restore는 원자료를 보존하면서
* 교차표 생성용으로 임시 가공하기 위한 명령이다.
*------------------------------------------------------------------------------

preserve

keep accident_type severity
contract accident_type severity, freq(n)
reshape wide n, i(accident_type) j(severity)

foreach j in 0 1 2 {
    capture confirm variable n`j'
    if _rc {
        gen long n`j' = 0
    }
    replace n`j' = 0 if missing(n`j')
}

gen long total = n0 + n1 + n2
gen double casualty_rate = 100*(n1+n2)/total

format casualty_rate %6.1f

gsort -total accident_type

export delimited accident_type n0 n1 n2 total casualty_rate using "$OUT/accident_type_severity_full.csv", replace

restore


*------------------------------------------------------------------------------
* 5.3 논문 본문용 압축 교차표 CSV
*------------------------------------------------------------------------------
*
* 주요 사고유형을 개별 표시하고
* 나머지는 Other accident types로 통합한다.
*
* 이 통합은 교차표 표시용이며 회귀분석 자료는 변경하지 않는다.
*------------------------------------------------------------------------------

preserve

gen byte grp = 11

replace grp = 1 if accident_type == "충돌"
replace grp = 2 if accident_type == "해양오염"
replace grp = 3 if accident_type == "기관손상"
replace grp = 4 if accident_type == "화재"
replace grp = 5 if accident_type == "안전사고(인명사상)"
replace grp = 6 if accident_type == "좌초"
replace grp = 7 if accident_type == "안전사고"
replace grp = 8 if accident_type == "침몰"
replace grp = 9 if accident_type == "전복"
replace grp = 10 if accident_type == "폭발"

gen str64 accident_group = "Other accident types"

replace accident_group = "Collision" if grp == 1
replace accident_group = "Marine pollution" if grp == 2
replace accident_group = "Machinery damage" if grp == 3
replace accident_group = "Fire" if grp == 4
replace accident_group = "Safety accident (human casualty)" if grp == 5
replace accident_group = "Grounding" if grp == 6
replace accident_group = "Safety accident" if grp == 7
replace accident_group = "Sinking" if grp == 8
replace accident_group = "Capsizing" if grp == 9
replace accident_group = "Explosion" if grp == 10

contract grp accident_group severity, freq(n)
reshape wide n, i(grp accident_group) j(severity)

foreach j in 0 1 2 {
    capture confirm variable n`j'
    if _rc {
        gen long n`j' = 0
    }
    replace n`j' = 0 if missing(n`j')
}

gen long total = n0 + n1 + n2
gen double casualty_rate = 100*(n1+n2)/total

format casualty_rate %6.1f

quietly summarize n0, meanonly
local T0 = r(sum)

quietly summarize n1, meanonly
local T1 = r(sum)

quietly summarize n2, meanonly
local T2 = r(sum)

local T_all = `T0' + `T1' + `T2'
local last = _N + 1

set obs `last'

replace grp = 12 in L
replace accident_group = "Total" in L
replace n0 = `T0' in L
replace n1 = `T1' in L
replace n2 = `T2' in L
replace total = `T_all' in L
replace casualty_rate = 100*(`T1'+`T2')/`T_all' in L

sort grp

list accident_group n0 n1 n2 total casualty_rate, noobs abbreviate(32)

export delimited accident_group n0 n1 n2 total casualty_rate using "$OUT/accident_type_severity_compact.csv", replace

restore


*==============================================================================
* 6. Model 1: 인명피해 발생 여부
*==============================================================================
*
* 종속변수: casualty_any
* 0 = 무인명피해
* 1 = 인명피해 발생
*
* 분석방법: 이항 로짓
* 표준오차: 사고 사건별 군집화
*
* 기존 결과 참고값:
* N = 3,079
* ln(GT) OR 약 1.236
* 다선박 OR 약 0.166
* 04~08시 OR 약 0.482
* 연도 OR 약 0.948
*==============================================================================

display as result "=============================================================="
display as result "MODEL 1: 인명피해 발생 여부"
display as result "=============================================================="

logistic casualty_any ib1.ship_type_n c.ln_gt ib0.multi_vessel ib3.time_n ib1.season_n ib1.area_n c.year, vce(cluster case_id)

estimates store M1

* 총톤수가 2배 증가할 때의 오즈비
* exp(lnGT 계수 × ln(2))

nlcom exp(_b[ln_gt]*ln(2))


*==============================================================================
* 7. Model 1-A: 선령 추가 확장모형
*==============================================================================
*
* 선령을 추가하여 선박 노후화와 인명피해의 관련성을 검토한다.
*
* 선령 결측으로 표본이 감소하므로
* 선령 추가 효과와 표본 변화 효과를 구분할 필요가 있다.
*
* 기존 분석 참고값: N 약 2,404
*==============================================================================

display as result "=============================================================="
display as result "MODEL 1-A: 선령 추가"
display as result "=============================================================="

logistic casualty_any ib1.ship_type_n c.ln_gt c.age ib0.multi_vessel ib3.time_n ib1.season_n ib1.area_n c.year, vce(cluster case_id)

estimates store M1_age

* 동일한 선령 관측 표본에서 선령을 제외한 비교모형

logistic casualty_any ib1.ship_type_n c.ln_gt ib0.multi_vessel ib3.time_n ib1.season_n ib1.area_n c.year if !missing(age), vce(cluster case_id)

estimates store M1_age_sample_noage


*==============================================================================
* 8. Model 2: 인명피해 발생 시 사망·실종 여부
*==============================================================================
*
* 분석표본: casualty_any == 1
*
* 종속변수: fatal
* 0 = 부상
* 1 = 사망·실종
*
* 전체 사고가 아닌 인명피해 발생 사례만 분석한다.
*
* 기존 분석 참고값:
* N = 273
* 사망·실종 = 90
* 전체 Wald p 약 0.332
* 부선 OR 약 3.380
*
* 전체 Wald 검정의 비유의성과 개별 부선 계수의
* 유의성을 구분하여 해석해야 한다.
*==============================================================================

display as result "=============================================================="
display as result "MODEL 2: 사망·실종 여부"
display as result "=============================================================="

logistic fatal ib1.ship_type_n c.ln_gt ib0.multi_vessel ib3.time_n ib1.season_n ib1.area_n c.year if casualty_any == 1, vce(cluster case_id)

* 실제 전체모형 분석표본을 저장한다.
* 이후 축약모형에서도 같은 관측치만 사용한다.

gen byte sample_M2_full = e(sample)
local N_M2 = e(N)

estimates store M2

count if sample_M2_full == 1
count if sample_M2_full == 1 & fatal == 1

tab ship_type_n fatal if sample_M2_full == 1, row

* 선종 관련 계수들의 공동유의성 검정

testparm i.ship_type_n


*==============================================================================
* 9. Model 3: PPO 모형
*==============================================================================
*
* 종속변수: severity
* 0 = 무인명피해
* 1 = 부상
* 2 = 사망·실종
*
* PPO: 부분비례승산모형
*
* 경계 1: 무인명피해 vs 부상·사망실종
* 경계 2: 무인명피해·부상 vs 사망실종
*
* 주의:
* PPO의 경계 2는 Model 2처럼
* 인명피해 발생 사례에 한정한 조건부 분석이 아니다.
*
* gologit2 설치 필요
*==============================================================================

display as result "=============================================================="
display as result "MODEL 3: PPO"
display as result "=============================================================="

if `RUN_PPO' == 1 {

    capture which gologit2

    if _rc {
        display as text "gologit2 설치를 시도합니다."
        capture noisily ssc install gologit2
    }

    capture which gologit2

    if _rc {
        display as error "gologit2를 사용할 수 없어 PPO 분석을 건너뜁니다."
    }
    else {
        gologit2 severity ib1.ship_type_n c.ln_gt ib0.multi_vessel ib3.time_n ib1.season_n ib1.area_n c.year, autofit cluster(case_id) or
        estimates store M3_PPO
    }
}

* 기존 PPO 결과 참고값:
* 예인선 경계 1 OR 약 1.521 / 경계 2 OR 약 2.738
* 부선 경계 1 OR 약 1.208 / 경계 2 OR 약 2.636


*==============================================================================
* 10. 선택 분석: 다항로짓
*==============================================================================
*
* 기본값은 미실행이다.
* 실행하려면 RUN_MNL 값을 1로 변경한다.
*
* MNL은 PPO와 다른 모형이므로 계수 해석을 구분한다.
*==============================================================================

if `RUN_MNL' == 1 {

    * 기준 결과: 무인명피해
    mlogit severity ib1.ship_type_n c.ln_gt ib0.multi_vessel ib3.time_n ib1.season_n ib1.area_n c.year, baseoutcome(0) vce(cluster case_id) rrr
    estimates store MNL_base0

    * 기준 결과: 부상
    mlogit severity ib1.ship_type_n c.ln_gt ib0.multi_vessel ib3.time_n ib1.season_n ib1.area_n c.year, baseoutcome(1) vce(cluster case_id) rrr
    estimates store MNL_base1
}


*==============================================================================
* 11. 안전사고 계열의 표본 구성 진단
*==============================================================================
*
* 논문 4.5절 관련 내용임
*
* 안전사고 계열이 전체 인명피해에서 차지하는 비중과
* 단독·다선박 사고 및 선종별 분포를 확인한다.
*
* 사고유형 구성의 영향을 검토하는 기술적 분석이며
* 인과관계를 확정하는 분석은 아니다.
*==============================================================================

tab safety_accident

tab safety_accident casualty_any, row
tab safety_accident severity, row

tab multi_vessel safety_accident, row

tab safety_accident fatal if casualty_any == 1, row

tab ship_type_n fatal if casualty_any == 1 & safety_accident == 1, row
tab ship_type_n fatal if casualty_any == 1 & safety_accident == 0, row


*==============================================================================
* 12. Model 1-S: 안전사고 계열 제외
*==============================================================================
*
* 논문 4.5절 관련
*
* 분석표본: safety_accident == 0
* 종속변수: casualty_any
*
* 안전사고 계열을 제외해도
* 주요 변수의 방향과 유의성이 유지되는지 확인한다.
*
* 기존 결과 참고값:
* N = 2,847
* 인명피해 = 56
* 부선 OR 약 2.736
* ln(GT) OR 약 0.808
* 다선박 OR 약 0.967
*
* 안전사고 제외 직후 인명피해는 57건이나
* 완전사례 회귀분석에서는 56건이다.
*==============================================================================

display as result "=============================================================="
display as result "MODEL 1-S: 안전사고 계열 제외"
display as result "=============================================================="

logistic casualty_any ib1.ship_type_n c.ln_gt ib0.multi_vessel ib3.time_n ib1.season_n ib1.area_n c.year if safety_accident == 0, vce(cluster case_id)

gen byte sample_M1S_full = e(sample)
local N_M1S = e(N)

estimates store M1S

count if sample_M1S_full == 1
count if sample_M1S_full == 1 & casualty_any == 1

tab ship_type_n casualty_any if sample_M1S_full == 1, row
tab multi_vessel casualty_any if sample_M1S_full == 1, row

testparm i.ship_type_n


*==============================================================================
* 13. Model 2 축약모형
*==============================================================================
*
* 논문 4.6절 관련
*
* 전체모형: 17개 기울기 계수
* 축약모형 A: 6개 기울기 계수
* 축약모형 B: 7개 기울기 계수
*
* 축약모형 A:
* 선종 + ln(GT) + 다선박 여부 + 연도
*
* 축약모형 B:
* 축약모형 A + 04~08시 더미
*
* 동일한 전체모형 분석표본을 사용하여
* 표본 변화가 아닌 모형 사양 변화에 따른 민감도를 확인한다.
*==============================================================================


*------------------------------------------------------------------------------
* 13.1 Model 2 축약모형 A
*------------------------------------------------------------------------------

display as result "=============================================================="
display as result "MODEL 2: 축약모형 A"
display as result "=============================================================="

logistic fatal ib1.ship_type_n c.ln_gt ib0.multi_vessel c.year if sample_M2_full == 1, vce(cluster case_id)

assert e(N) == `N_M2'

estimates store M2_core

testparm i.ship_type_n

* 기존 결과 참고값:
* 부선 OR 약 3.442, p 약 0.011
* 전체 Wald p 약 0.061


*------------------------------------------------------------------------------
* 13.2 Model 2 축약모형 B
*------------------------------------------------------------------------------

display as result "=============================================================="
display as result "MODEL 2: 축약모형 B"
display as result "=============================================================="

logistic fatal ib1.ship_type_n c.ln_gt ib0.multi_vessel c.year i.time_0408 if sample_M2_full == 1, vce(cluster case_id)

assert e(N) == `N_M2'

estimates store M2_core_time

testparm i.ship_type_n

* 기존 결과 참고값:
* 부선 OR 약 3.383, p 약 0.014
* 전체 Wald p 약 0.055
*
* 부선의 추정 방향과 크기가 유지되지만
* 전체 Wald 검정은 5% 수준에서 유의하지 않다.
* 탐색적 결과로 해석한다.


*==============================================================================
* 14. Model 1-S 축약모형
*==============================================================================
*
* 논문 4.6절 관련
*
* 안전사고 제외 후 인명피해 관측치는 56건이다.
* 전체모형은 17개 기울기 계수를 추정한다.
*
* 축약모형을 통해 다음을 확인한다.
*
* 1. 부선의 양(+)의 관련성 유지 여부
* 2. ln(GT)의 음(-)의 관련성 유지 여부
* 3. 다선박 사고의 비유의성 유지 여부
*
* 사건 수가 적기 때문에 축약모형에서도
* 추정 불확실성이 완전히 제거되지는 않는다.
*==============================================================================


*------------------------------------------------------------------------------
* 14.1 Model 1-S 축약모형 A
*------------------------------------------------------------------------------

display as result "=============================================================="
display as result "MODEL 1-S: 축약모형 A"
display as result "=============================================================="

logistic casualty_any ib1.ship_type_n c.ln_gt ib0.multi_vessel c.year if sample_M1S_full == 1, vce(cluster case_id)

assert e(N) == `N_M1S'

estimates store M1S_core

testparm i.ship_type_n

* 기존 결과 참고값:
* 부선 OR 약 2.715
* ln(GT) OR 약 0.803
* 다선박 OR 약 0.957
* 전체 Wald p 약 0.002


*------------------------------------------------------------------------------
* 14.2 Model 1-S 축약모형 B
*------------------------------------------------------------------------------

display as result "=============================================================="
display as result "MODEL 1-S: 축약모형 B"
display as result "=============================================================="

logistic casualty_any ib1.ship_type_n c.ln_gt ib0.multi_vessel c.year i.time_0408 if sample_M1S_full == 1, vce(cluster case_id)

assert e(N) == `N_M1S'

estimates store M1S_core_time

testparm i.ship_type_n

* 기존 결과 참고값:
* 부선 OR 약 2.737
* ln(GT) OR 약 0.803
* 다선박 OR 약 0.971
* 04~08시 OR 약 0.364, p 약 0.054
*
* 04~08시 효과는 5% 수준에서 유의하지 않다.


*------------------------------------------------------------------------------
* 14.3 참고모형: 연도 제외
*------------------------------------------------------------------------------
*
* 선종 + ln(GT) + 다선박 여부 + 04~08시
*
* 논문 4.6절의 주된 비교모형에는 포함하지 않고
* 추가 참고 분석으로 보존한다.
*------------------------------------------------------------------------------

logistic casualty_any ib1.ship_type_n c.ln_gt ib0.multi_vessel i.time_0408 if sample_M1S_full == 1, vce(cluster case_id)

assert e(N) == `N_M1S'

estimates store M1S_no_year


*==============================================================================
* 15. 안전사고 제외 PPO 분석 관련 주의사항
*==============================================================================
*
* 안전사고 계열을 제외하면 결과 사건 수가 크게 감소한다.
*
* 복잡한 PPO 모형에서 표준오차 추정 실패나
* 분산-공분산행렬 특이성이 발생할 수 있으므로
* 기본 분석에서는 실행하지 않는다.
*
* 아래 명령은 진단 목적으로만 보존한다.
*==============================================================================

* gologit2 severity ib1.ship_type_n c.ln_gt ib0.multi_vessel ib3.time_n ib1.season_n ib1.area_n c.year if safety_accident == 0, autofit cluster(case_id) or


*==============================================================================
* 16. 회귀분석 결과 비교
*==============================================================================
*
* estimates table의 기본 계수는 log-odds이다.
* OR로 변환된 값이 아니므로 논문 표에 그대로 사용하지 않는다.
*
* 논문 표 작성 시에는 각 logistic 출력에서
* OR, p값, 95% 신뢰구간, Wald 검정 결과를 확인한다.
*==============================================================================

display as result "=============================================================="
display as result "MODEL 1 계열 비교"
display as result "=============================================================="

estimates table M1 M1_age M1_age_sample_noage M1S, b(%9.4f) se(%9.4f) stats(N)


display as result "=============================================================="
display as result "MODEL 2: 전체모형 및 축약모형 비교"
display as result "=============================================================="

estimates table M2 M2_core M2_core_time, b(%9.4f) se(%9.4f) stats(N)


display as result "=============================================================="
display as result "MODEL 1-S: 전체모형 및 축약모형 비교"
display as result "=============================================================="

estimates table M1S M1S_core M1S_core_time M1S_no_year, b(%9.4f) se(%9.4f) stats(N)

estimates dir


*==============================================================================
* 17. 분석자료 및 결과 저장
*==============================================================================
*
* 결과 파일:
*
* 1. coastal_casualty_integrated.log
* 2. accident_type_severity_full.csv
* 3. accident_type_severity_compact.csv
* 4. coastal_casualty_analysis_final.dta
*
* 저장 위치: ROOT 폴더 아래 output 폴더
*==============================================================================

save "$OUT/coastal_casualty_analysis_final.dta", replace

display as result "=============================================================="
display as result "통합 분석 완료"
display as result "=============================================================="

display as result "결과 저장 폴더: $OUT"

display as result "전체 분석 로그: coastal_casualty_integrated.log"
display as result "전체 사고유형 교차표: accident_type_severity_full.csv"
display as result "논문용 압축 교차표: accident_type_severity_compact.csv"
display as result "분석용 Stata 자료: coastal_casualty_analysis_final.dta"

log close

*******************************************************************************
* 통합 분석 종료
*******************************************************************************
