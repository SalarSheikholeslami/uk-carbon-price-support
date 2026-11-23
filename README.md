# The UK Carbon Price Support and the Electricity Generation Mix

**Synthetic Control Evidence on the Coal and Gas Share of Electricity Generation**

**Author:** Salar Sheikholeslami  
**Institution:** Johannes Kepler University Linz (JKU), Austria  
**Project:** Seminar Research Project | Winter 2025/26  

## Overview

This independent seminar research project evaluates whether the **UK Carbon Price Support (CPS)**, introduced in 2013 alongside the EU Emissions Trading System (EU ETS), was associated with changes in the composition of electricity generation in the United Kingdom.

The central outcome is the **combined coal-and-gas share of total electricity generation**. Using the **Synthetic Control Method (SCM)**, I construct a counterfactual *synthetic UK* from countries without a comparable national power-sector carbon price floor and compare its post-2013 trajectory with the observed UK outcome.

The analysis also examines fuel-specific patterns, placebo-based inference, and the sensitivity of the findings to alternative specifications and donor-pool choices.

## Research Design

- **Treated unit:** United Kingdom.
- **Policy intervention:** Introduction of the Carbon Price Support in **2013**.
- **Sample:** Annual country-level data, **2001–2019**.
- **Pre-treatment period:** 2001–2012.
- **Post-treatment period:** 2013–2019.
- **Comparison group:** Donor pool of **20 countries**.
- **Outcome:** Combined share of coal- and gas-fired electricity generation.
- **Predictors:** Pre-treatment blocks of the outcome, GDP per capita, electricity consumption per capita, and manufacturing value added as a share of GDP.

SCM constructs a weighted combination of comparison countries that approximates the UK's pre-policy electricity mix and observed predictors. The post-treatment UK–synthetic difference is the main quantity of interest.

## Main Findings

- The synthetic UK closely tracks the observed UK outcome before 2013, followed by a substantial and persistent **negative UK–synthetic gap**.
- The UK's combined coal-and-gas share falls markedly after the CPS introduction. Descriptive fuel-specific comparisons indicate a **sharp decline in coal generation**, accompanied by changes in gas and renewable shares.
- **In-space placebo tests** and post-/pre-treatment RMSPE comparisons show that the UK gap is unusually large relative to the comparison countries. The seminar paper reports a permutation-based **p-value of 1/21 ≈ 0.0476**.
- Results remain qualitatively similar across **treatment backdating**, **leave-one-predictor-out**, **leave-one-donor-out**, and **donor-pool sensitivity** checks, including exclusions involving Greece and Germany.

**Interpretation:** This is an observational policy evaluation. The synthetic-control results support a policy-related shift in the electricity mix, but concurrent changes in the UK power sector and the assumptions underlying the counterfactual remain relevant. Fuel-specific mechanism plots are descriptive comparisons rather than separately identified causal effects.

## Analyses and Code

All scripts are written in **Stata** and organised by their role in the seminar paper.

| Folder | Contents |
|---|---|
| [`code/main/`](code/main/) | Baseline SCM estimation, observed versus synthetic UK, and gap plot (Figure 1). |
| [`code/mechanisms/`](code/mechanisms/) | Coal, gas, and renewable shares (Figure 2); coal-related CO₂ and carbon intensity (Figure A2). |
| [`code/placebo-tests/`](code/placebo-tests/) | In-space placebo tests (Figure 3), RMSPE distribution (Figure 4 and Table B4), and UK–Greece placebo comparison (Figure A3). |
| [`code/robustness/`](code/robustness/) | Backdating to 2009 and 2011; predictor and donor leave-one-out checks; Greece/Germany sensitivity (Figures A4–A7). |
| [`code/tables/`](code/tables/) | Pre-intervention predictor balance (Table 1) and donor weights (Table B3). |

The scripts in this repository are derived from my seminar-project analysis. File paths have been adapted for a repository-based folder structure; **the scripts have not yet been retested end-to-end against a complete set of input data in this layout**.

## Seminar Paper

A public version of the completed seminar paper is available as **[Seminar paper (PDF)](paper/seminar-paper.pdf)**. The publicly shared copy omits the university matriculation number. This is a **student seminar paper**, not a peer-reviewed journal publication.

## Data Sources

The analysis combines publicly accessible statistical series, obtained for the project through **Our World in Data**, including electricity-generation data based on **Ember / the Energy Institute**, macroeconomic indicators based on the **World Bank and national accounts**, and emissions series based on the **Global Carbon Budget**.

Six original CSV input files are expected in the [`data/`](data/) directory:

| Required file | Purpose |
|---|---|
| `share-electricity-source-facet3.csv` | Main generation-share outcome; fuel-mix mechanisms. |
| `GDP per capita.csv` | Economic predictor. |
| `electric consumption per capita.csv` | Electricity-demand predictor. |
| `manufacturing-value-added-to-gdp.csv` | Economic-structure predictor. |
| `carbon-intensity-electricity.csv` | Carbon-intensity mechanism plot. |
| `annual-co2-coal.csv` | Coal-related emissions mechanism plot. |

**Source datasets are not included in this repository.** See [`data/README.md`](data/README.md) for the expected filenames and data preparation caveats. Some `.dta` files referenced by the scripts are **intermediate outputs generated by other scripts**, not separate source datasets.

## Requirements and Running the Code

- **Stata**, including the user-written `synth` command for synthetic control estimation. Some scripts install `synth` from SSC if it is missing.
- The six CSV inputs, placed under `data/` using the names above.
- A working directory set to the **repository root** before running a script; relative paths are resolved from this location.

For example, from Stata after setting the working directory to the project folder:

```stata
do "code/main/01-main-synthetic-control.do"
```

Other scripts may require intermediate datasets such as `data/panel_ready.dta` or `data/base_panel.dta`, generated during the corresponding data-preparation and estimation scripts. In particular, the predictor and donor leave-one-out analyses depend on `panel_ready.dta`, produced by the backdating scripts.

**Reproducibility status:** This is a research-code portfolio, **not yet a verified one-command replication package**. The source datasets are not bundled, and the full sequence requires a Stata run and verification of graph/table outputs. Changes to the formats of downloaded datasets may require additional adaptation.

## Academic Context and Attribution

This work was completed as an independent seminar project at Johannes Kepler University Linz during Winter Semester 2025/26, under the instruction of Prof. Karin Mayr-Dorn and Prof. Daniel Schäfer.

The analysis applies the Synthetic Control Method developed in the academic literature, notably:

- Abadie, A., Diamond, A., and Hainmueller, J. (2010). *Synthetic Control Methods for Comparative Case Studies: Estimating the Effect of California's Tobacco Control Program*. Journal of the American Statistical Association, 105(490), 493–505.

The underlying data remain attributable to their original statistical providers and are subject to the respective source terms.

## Usage and Rights

© 2026 Salar Sheikholeslami. All rights reserved for original materials, subject to applicable law and third-party rights.

No open-source licence is assigned to this repository. Public access does not grant unrestricted rights to reuse, redistribute, or republish the original code or research materials. This does not restrict uses otherwise allowed by law or GitHub's terms of service.
