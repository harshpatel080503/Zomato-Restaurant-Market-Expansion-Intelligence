# Zomato — Restaurant Market Expansion Intelligence

> **End-to-end Business Analysis, Data Analytics, Cloud Data Warehousing, Statistical Analysis & Power BI Business Intelligence Project**

## Project Overview

**Zomato — Restaurant Market Expansion Intelligence** is an end-to-end analytics project designed to answer a core business question:

> **Where should Zomato prioritize restaurant-market expansion, and what market characteristics explain that opportunity?**

The project was built from scratch across the full analytics lifecycle — from business requirements and stakeholder analysis to data cleaning, dimensional modeling, cloud SQL warehousing, SQL analytics, EDA, feature engineering, statistical testing, and an executive Power BI decision-support dashboard.

---

## Business Objective

Restaurant-market expansion requires understanding both **market attractiveness** and **competitive intensity**.

This project evaluates markets using signals such as:

- Restaurant coverage
- Restaurant quality
- Customer engagement
- Delivery quality
- Fulfillment
- Cuisine diversity and concentration
- Cuisine gaps
- Pricing structure and pricing gaps
- Market saturation
- Evidence strength
- Expansion opportunity

The output is a **market prioritization framework** that helps identify higher-, moderate-, and lower-priority localities for further expansion consideration.

> **Important analytical limitation:** the source dataset is a point-in-time snapshot and does not contain actual order volume, revenue, market share, customer acquisition cost, impressions, or confirmed expansion outcomes. Therefore, the expansion score is a **decision-support opportunity score based on available market proxies**, not a prediction of actual Zomato expansion success.

---

# Project Architecture

```text
                         BUSINESS LAYER
                              │
       ┌──────────────────────┼──────────────────────┐
       │                      │                      │
 Problem Statement        Stakeholders            KPI Tree
 BRD / FRD                User Stories            RACI
 Process Maps             Gap Analysis
                              │
                              ▼
                         DATA LAYER
                              │
                    Raw Zomato Dataset
                              │
                              ▼
                        Data Cleaning
                              │
                              ▼
                       Data Dictionary
                              │
                              ▼
                        Data Modeling
                              │
                              ▼
                    DATABRICKS WAREHOUSE
                              │
             ┌────────────────┼────────────────┐
             │                │                │
           Bronze           Silver            Gold
             │                │                │
          Staging        Star Schema        BI Layer
                              │
                              ▼
                        SQL ANALYTICS
                              │
                              ▼
                    ADVANCED DATA ANALYSIS
                              │
                 ┌────────────┼─────────────┐
                 │            │             │
                EDA     Feature Engineering  Statistical
                                              Testing
                              │
                              ▼
                      POWER BI SEMANTIC MODEL
                              │
                              ▼
                       POWER BI DASHBOARD
                              │
                              ▼
                     MARKET EXPANSION
                       DECISION SUPPORT
```

---

# Business Analysis Layer

The project began with a complete Business Analyst layer.

### Deliverables

- Problem Statement
- Stakeholder Analysis
- KPI Tree
- Business Requirements Document (BRD)
- Functional Requirements Document (FRD)
- User Stories
- RACI Matrix
- Process Maps
- Gap Analysis

### Business questions

The analysis was designed to answer:

1. Which cities have stronger expansion potential?
2. Which localities are comparatively underpenetrated?
3. Which localities are highly saturated?
4. Which cuisines are underrepresented?
5. Which pricing segments present potential gaps?
6. Which markets have stronger quality and engagement?
7. Which markets appear more operationally ready?
8. Which localities should receive higher expansion priority?
9. How strong is the evidence behind each market ranking?

---

# Dataset

## Source

Kaggle — Zomato Restaurants Dataset

The dataset contains restaurant and menu-item level information covering restaurant identity, location, cuisine, ratings, votes, pricing, delivery/table-booking related attributes, and menu-item information.

## Project data grain

The source behaves primarily as:

```text
Restaurant × Menu Item
```

This is important because restaurant-level information repeats across menu-item rows.

The warehouse therefore separates:

```text
Restaurant Grain
```

from:

```text
Restaurant × Menu Item Grain
```

to avoid double counting.

---

# Data Layer

## Data Cleaning

The cleaned dataset was prepared before loading into the cloud warehouse.

The cleaning process addressed:

- Missing-value treatment
- Data-type consistency
- Duplicate handling
- Text normalization
- City/locality validation
- Rating validation
- Price validation
- Vote validation
- Business-derived fields
- Missingness indicators

## Data Dictionary

A structured data dictionary was created to document:

- Field name
- Data type
- Business meaning
- Grain
- Source
- Transformation
- Null behavior
- Intended analytical usage

---

# Data Modeling

The analytical warehouse follows a dimensional model.

## Dimensions

```text
dim_city
dim_locality
dim_restaurant
dim_cuisine
dim_menu_item
dim_price_band
```

## Bridge

```text
bridge_restaurant_cuisine
```

## Facts

```text
fact_restaurant
fact_menu_item
```

The restaurant-cuisine relationship is handled separately because a restaurant can be associated with multiple cuisines.

---

# Cloud SQL Warehouse

## Technology

```text
Databricks Free Edition
Unity Catalog
Databricks SQL Warehouse
Delta Lake
SQL
```

## Medallion architecture

```text
BRONZE
└── stg_zomato_restaurant_items

SILVER
├── dim_city
├── dim_locality
├── dim_restaurant
├── dim_cuisine
├── dim_menu_item
├── dim_price_band
├── bridge_restaurant_cuisine
├── fact_restaurant
└── fact_menu_item

GOLD / BI
├── dimension tables
├── fact tables
└── market intelligence views/features
```

---

# SQL Analytics Layer

The SQL analytics layer translates business requirements into analytical queries.

## Analysis domains

### Executive KPIs

- Total restaurants
- Total cities
- Total localities
- Total cuisines
- Average dining rating
- Average delivery rating
- Total votes
- Average fulfillment
- Average saturation
- Average expansion opportunity

### City Analysis

- Restaurant coverage by city
- Rating comparison
- Engagement comparison
- Saturation comparison
- Expansion ranking

### Locality Analysis

- Restaurant coverage
- Quality
- Engagement
- Saturation
- Expansion opportunity

### Cuisine Analysis

- Cuisine coverage
- Cuisine concentration
- Cuisine diversity
- Cuisine gaps
- Cuisine by city/locality

### Pricing Analysis

- Price distribution
- Price bands
- City pricing mix
- Cuisine pricing
- Pricing gaps

### Quality & Engagement

- Dining rating
- Delivery rating
- Vote volume
- Quality/engagement relationships

### Saturation

- Restaurant coverage
- Same-cuisine competition
- Cuisine concentration
- Saturation scoring

### Expansion Analysis

- Market opportunity ranking
- High / moderate / low priority markets
- Expansion score
- Evidence strength

---

# Advanced Data Analysis

## EDA

The EDA phase examined:

### Data Quality

- Missing values
- Duplicate structure
- Data types
- Invalid ranges
- City/locality quality

### Univariate Analysis

- Dining rating distribution
- Delivery rating distribution
- Item price distribution
- Item vote distribution
- Price outliers

### Categorical Analysis

- Top cities
- Top localities
- Top cuisines
- Bestseller categories
- Price bands
- Rating bands

### Relationship Analysis

- Rating vs votes
- Price vs votes
- Rating vs expansion opportunity
- Saturation vs expansion opportunity
- City-wise rating distributions
- Cuisine-wise price distributions

### Market Analysis

- City ranking
- Locality opportunity ranking
- Cuisine concentration by city
- Price-band mix by city
- Saturation heatmaps

---

# Feature Engineering

Features were engineered directly from the business questions, warehouse schema, and EDA findings.

## Restaurant Features

- Dining quality normalization
- Delivery quality normalization
- Fulfillment normalization
- Quality score
- Rating completeness
- Log-transformed engagement
- Engagement score
- Restaurant performance segment
- Relative pricing position

## Menu Features

- Log item votes
- Item popularity score
- Item price log
- Item value efficiency
- Relative price position

## Cuisine Features

- Cuisine diversity
- Cuisine concentration / HHI
- Cuisine gap score
- Meaningful cuisine gap counts

## Pricing Features

- Average item price
- Median item price
- Price-band diversity
- Pricing gap score

## Locality Features

- Restaurant coverage
- Locality quality score
- Locality engagement score
- Cuisine diversity
- Cuisine HHI
- Saturation index
- Cuisine opportunity
- Pricing opportunity

## Market Expansion Features

- Quality component
- Engagement component
- Coverage opportunity component
- Cuisine component
- Pricing component
- Engineered expansion score
- Expansion priority
- Market evidence score

---

# Expansion Opportunity Framework

The project-defined expansion framework combines five dimensions:

```text
Expansion Opportunity
=
25% Quality
+
20% Engagement
+
25% Coverage Opportunity
+
15% Cuisine Opportunity
+
15% Pricing Opportunity
```

This is a **project-defined prioritization framework**, not an official Zomato scoring methodology.

### Priority bands

```text
Priority 1 — High Opportunity
Priority 2 — Moderate Opportunity
Priority 3 — Low Opportunity
```

An evidence score is also retained so that high opportunity with weak evidence can be differentiated from high opportunity with strong market evidence.

---

# Statistical / Analytical Testing

The final analytical stage tested whether the observed patterns were statistically defensible.

## Tests included

- Spearman correlation analysis
- Multiple-hypothesis/FDR correction
- Kruskal-Wallis group comparison
- Dunn post-hoc testing
- Chi-square tests
- Cramér's V effect size
- Regression analysis
- Robust regression standard errors
- Multicollinearity / VIF
- Feature correlation audit
- Weight sensitivity analysis
- Scenario ranking comparison
- Top-N overlap analysis
- Bootstrap ranking stability
- Bootstrap confidence intervals
- Leave-one-component-out analysis

## Statistical discipline

The project distinguishes:

```text
Association ≠ Causation
```

Because the dataset is observational, the analysis does not claim that rating, saturation, cuisine, or price **causes** expansion success.

---

# Power BI Business Intelligence

## BI Architecture

Power BI connects to the curated Databricks `gold_bi` layer.

```text
Databricks
     ↓
gold_bi
     ↓
Power BI Import
     ↓
Semantic Model
     ↓
DAX Measures
     ↓
Dashboards
```

## Semantic Model

### Dimensions

```text
City
Locality
Restaurant
Cuisine
Menu Item
Price Band
```

### Facts

```text
Restaurants
Menu Items
Market Expansion
```

### Power BI model grain

```text
Restaurants
= 1 row per restaurant

Menu Items
= 1 row per restaurant × menu item

Market Expansion
= 1 row per city × locality
```

---

# Dashboard Pages

## 01 — Executive Command Center

Answers:

> **What is the overall market opportunity and where should leadership look first?**

Key KPIs:

- Total Restaurants
- Total Cities
- Total Localities
- Average Dining Rating
- Average Expansion Score
- High Opportunity Markets

Visuals:

- Top localities by expansion score
- Expansion priority distribution
- Saturation vs opportunity scatter plot
- Market quality vs engagement
- City performance ranking
- Executive insights

---

## 02 — Market Expansion

Answers:

> **Which localities should be prioritized?**

Includes:

- Locality ranking
- Opportunity score
- Saturation
- Quality
- Engagement
- Cuisine gap
- Pricing gap
- Evidence score

---

## 03 — City Intelligence

Answers:

> **Which cities are strongest and why?**

Includes:

- City ranking
- Restaurant coverage
- Dining quality
- Delivery quality
- Engagement
- Saturation
- Expansion opportunity

---

## 04 — Locality Intelligence

Answers:

> **Which localities within a selected city should be targeted?**

Includes:

- Locality-level opportunity
- Restaurant supply
- Quality
- Engagement
- Cuisine diversity
- Cuisine concentration
- Pricing
- Saturation

---

## 05 — Cuisine Intelligence

Answers:

> **Which cuisines are overrepresented or potentially underserved?**

Includes:

- Cuisine distribution
- Cuisine share
- Cuisine concentration
- Cuisine diversity
- Cuisine gaps
- City × cuisine analysis

---

## 06 — Pricing Intelligence

Answers:

> **Where are the pricing opportunities?**

Includes:

- Price band distribution
- City × price band
- Cuisine pricing
- Average prices
- Pricing gaps
- Price-band diversity

---

## 07 — Restaurant Intelligence

Answers:

> **Which restaurants are strong, weak, highly engaged, or differently positioned?**

Includes:

- Restaurant quality
- Engagement
- Ratings
- Votes
- Menu size
- Average price
- Bestseller rate
- Relative price position
- Performance segment

---

## 08 — Expansion Prioritization

Answers:

> **What should the business prioritize?**

Includes:

- City
- Locality
- Restaurant count
- Quality
- Engagement
- Saturation
- Cuisine opportunity
- Pricing opportunity
- Expansion score
- Evidence score
- Priority band

---

## 09 — Methodology & Definitions

Documents:

- Dataset scope
- Business definitions
- KPI definitions
- Expansion score methodology
- Feature definitions
- Statistical testing
- Data limitations
- Technology stack

---

# Key Business Outcomes

The dashboard converts a large restaurant/menu dataset into an executive decision-support system:

```text
WHERE?
  ↓
City
  ↓
Locality
  ↓
Restaurant market

WHY?
  ↓
Quality
Engagement
Coverage
Cuisine gap
Pricing gap
Saturation

WHAT PRIORITY?
  ↓
Expansion Opportunity Score
  ↓
Priority Band
  ↓
Evidence Strength
```

---

# Technology Stack

## Business Analysis

- Business Requirements
- BRD / FRD
- KPI Trees
- User Stories
- RACI
- Process Mapping
- Gap Analysis

## Programming / Analysis

- Python
- Pandas
- NumPy
- Matplotlib
- SciPy
- Statsmodels

## Database / Cloud

- Databricks
- Databricks SQL Warehouse
- Unity Catalog
- Delta Lake
- SQL

## BI

- Power BI
- DAX
- Power BI Semantic Modeling
- Data Visualization

## Version Control

- Git
- GitHub

---

# Repository Structure

```text
zomato-market-expansion-intelligence/
│
├── README.md
│
├── business/
│   ├── problem_statement.md
│   ├── stakeholders.md
│   ├── kpi_tree.md
│   ├── brd.pdf
│   ├── frd.pdf
│   ├── user_stories.md
│   ├── raci.md
│   ├── process_maps.md
│   └── gap_analysis.pdf
│
├── data/
│   ├── data_dictionary.xlsx
│   ├── cleaning_rules.md
│   └── data_quality_report.md
│
├── warehouse/
│   ├── 01_catalog_schema.sql
│   ├── 02_bronze.sql
│   ├── 03_dimensions.sql
│   ├── 04_bridge.sql
│   ├── 05_facts.sql
│   ├── 06_gold_views.sql
│   ├── 07_feature_engineering.sql
│   └── 08_validation.sql
│
├── sql/
│   ├── 01_validation.sql
│   ├── 02_executive_kpis.sql
│   ├── 03_city_analysis.sql
│   ├── 04_locality_analysis.sql
│   ├── 05_cuisine_analysis.sql
│   ├── 06_pricing_analysis.sql
│   ├── 07_quality_engagement.sql
│   ├── 08_saturation_analysis.sql
│   ├── 09_menu_analysis.sql
│   └── 10_expansion_analysis.sql
│
├── python/
│   ├── 07_eda.ipynb
│   └── 08_statistical_testing.ipynb
│
├── powerbi/
│   ├── Zomato_Market_Expansion_Intelligence.pbix
│   └── screenshots/
│
└── docs/
    ├── warehouse_architecture.png
    ├── semantic_model.png
    ├── data_lineage.png
    └── dashboard_preview.png
```

---

# Project Lifecycle

```text
01. Business Problem
        ↓
02. Stakeholder & Requirement Analysis
        ↓
03. Data Cleaning & Dictionary
        ↓
04. Data Modeling
        ↓
05. Cloud SQL Warehouse
        ↓
06. SQL Analytics
        ↓
07. EDA
        ↓
08. Feature Engineering
        ↓
09. Statistical Testing
        ↓
10. BI Semantic Model
        ↓
11. Power BI Dashboard
        ↓
12. Market Expansion Decision Support
```

---

# Key Design Decisions

### Why Databricks?

To demonstrate a cloud-native warehouse / analytics environment rather than relying only on local files or a desktop database.

### Why dimensional modeling?

Because restaurant-level and menu-level information coexist in the source and must be analyzed at different grains.

### Why Import mode in Power BI?

The project uses a relatively small, static point-in-time analytical dataset, so Import mode provides an efficient report experience without requiring real-time querying.

### Why no ML model?

The available dataset does not provide a validated target such as actual future expansion success, revenue, orders, or market share. A forced predictive model would therefore create a misleading sense of predictive validity.

---

# Limitations

This project should not be interpreted as a live Zomato market study.

Key limitations include:

- Point-in-time dataset
- No actual order/revenue data
- No customer-level transactions
- No actual market-share information
- No confirmed expansion outcome label
- No reliable geographic area measurement for true restaurants/km² density
- Engagement and demand measures are proxies
- Expansion score is project-defined
- Weight selection requires sensitivity testing

These limitations are explicitly considered in the analytical interpretation.

---

# Final Outcome

The project delivers a complete **Restaurant Market Expansion Intelligence** solution:

```text
Business Requirements
        ↓
Cloud Data Warehouse
        ↓
SQL Analytics
        ↓
Statistical Analysis
        ↓
Feature Engineering
        ↓
Power BI Semantic Model
        ↓
Executive Dashboard
        ↓
Market Prioritization
```

The final dashboard enables decision-makers to move from:

> **“What does the restaurant market look like?”**

to:

> **“Which markets appear more attractive, why, and what evidence supports that prioritization?”**
