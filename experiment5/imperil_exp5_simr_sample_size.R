library(lme4)
library(simr)
library(readr)
library(dplyr)

dwell_data <- read_csv("Desktop/Imperil-or-Protect---Experiment-Codes/experiment5/pilot_data/dwell_data_S01.csv")
dwell_data$condition <- factor(dwell_data$condition)


dwell_data$log_dwell <- log(dwell_data$dwell)

dwell_data$repetition <- factor(
  ifelse(grepl("Rep1", dwell_data$condition), "Rep1", "Rep5")
)

dwell_data$change <- factor(
  ifelse(grepl("NoChange", dwell_data$condition), "NoChange", "Change")
)


dwell_data$repetition <- relevel(dwell_data$repetition, ref = "Rep1")
dwell_data$change     <- relevel(dwell_data$change, ref = "NoChange")

dwell_data <- dwell_data %>%
  mutate(
    log_dwell = ifelse(
      is.finite(dwell) & dwell > 0,
      log(dwell),
      NA_real_
    )
  )
model <- lm(
  log_dwell ~ repetition * change,
  data = dwell_data
)

summary(model)

## ===============================
## SIMR SAMPLE SIZE SCAFFOLD
## ===============================

set.seed(123)

## 1) Create fake subject factor (SIMR-only)
n_fake_subjects <- 20
dwell_data$subject_sim <- factor(
  paste0("S", rep(1:n_fake_subjects, length.out = nrow(dwell_data)))
)

## 2) Fit template mixed model
template_model <- lmer(
  log_dwell ~ repetition * change + (1 | subject_sim),
  data = dwell_data,
  REML = FALSE
)

## 3) Manually set conservative variance assumptions
vc <- VarCorr(template_model)
attr(vc$subject_sim, "stddev") <- 0.5   # try 0.3 / 0.5 / 0.8
VarCorr(template_model) <- vc

## 4) Shrink pilot effect sizes (important)
fixef(template_model)["repetitionRep5"] <- 0.08
fixef(template_model)["changeChange"] <- -0.03
fixef(template_model)["repetitionRep5:changeChange"] <- 0.02

## 5) Power curve for interaction (subjects)
powerCurve(
  template_model,
  fixed("repetitionRep5:changeChange", "t"),
  along = "subject_sim",
  nsim = 50
)

## 6) Example: power at N = 40
extended_model <- extend(
  template_model,
  along = "subject_sim",
  n = 40
)

powerSim(
  extended_model,
  fixed("repetitionRep5:changeChange", "t"),
  nsim = 200
)


