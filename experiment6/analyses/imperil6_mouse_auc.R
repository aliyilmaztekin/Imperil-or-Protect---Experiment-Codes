# Imperil or Protect - Experiment 4 - ANOVA/LMER analysis
# Coded by A.Y. 

### SETUP/PARAMETERS ----

library(afex)
afex_options(type = 3, check_contrasts = TRUE)
library(R.matlab)
library(dplyr)
library(ggplot2)
library(emmeans)
library(stringr)
library(lme4)
library(lmerTest)   # for Satterthwaite df + p-values
library(glmmTMB)
library(brms)
library(ggplot2)
library(rlang)

options(scipen = 999)  # Avoid scientific notation

mat <- readMat("/Users/ali/Desktop/visual imperil project/imperil4materials/pilot_data/mouse_auc_test2.mat")

aucOutput <- as.data.frame(mat$aucOutput)

colnames(aucOutput) <- c(
  "subject", "trial", "test", "condition",
  "repetition", "context", "auc"
)

aucOutput$subject <- factor(aucOutput$subject)
aucOutput$condition <- factor(aucOutput$condition)
aucOutput$repetition <- factor(aucOutput$repetition, levels = c(1,5), labels = c("1", "5"))
aucOutput$context <- factor(
  aucOutput$context,
  levels = c(0, 1),
  labels = c("No Change", "Change")
)


mod_auc <- lmer(
  auc ~ repetition * context + (1 | subject),
  data = aucOutput
)

summary(mod_auc)
anova(mod_auc)
