# Imperil or Protect - Experiment 4 - Alpha/Beta Analysis
# Cleaned pipeline: RM-ANOVA as primary, Gamma GLMM as robustness check

### SETUP ----
library(R.matlab)
library(dplyr)
library(ggplot2)
library(emmeans)
library(stringr)
library(afex)
library(glmmTMB)
library(patchwork)
library(writexl)
library(tidyr)

options(scipen = 999)

base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4/"

files <- list.files(base_dir, pattern = "\\.mat$", full.names = TRUE)

dfs <- lapply(files, function(f) {
  mat <- R.matlab::readMat(f)
  as.data.frame(mat$outputMatrix)
})

combinedData <- bind_rows(dfs)
colnames(combinedData) <- c(
  "subject", "conditionUsed", "block", "trial", "repetition",
  "context", "contextCode", "primaryColor", "secondaryColor",
  "angle1", "initiation_time1", "movement_time1", "rt1",
  "angle2", "initiation_time2", "movement_time2", "rt2",
  "breakTaken", "conditions"
)

### PREPROCESSING
dependent_variable <- "angle1"
rt_vars <- c("rt1", "rt2")

combinedData_sub <- combinedData %>%
  mutate(
    DV = abs(.data[[dependent_variable]]),
    subject = factor(subject),
    repetition = factor(repetition, levels = c(1,5), labels = c("1","5")),
    context = factor(context, levels = c(0,1), labels = c("No Change","Change"))
  ) %>%
  # Filter out timed-out trials
  filter(is.finite(DV)) %>%
  # Filter out too rapid responses
  filter(rt1 >= .3) %>%
  # Filter down to critical repetitions
  filter(repetition %in% c("1","5"),
         context %in% c("No Change","Change"))

# Subject means BEFORE exclusion
subject_means_before <- combinedData_sub %>%
  group_by(subject) %>%
  summarize(mean_DV = mean(DV, na.rm = TRUE), .groups = "drop")

# Filter out people with too high an overall mean
bad_subjects <- subject_means_before %>%
  filter(mean_DV > 45)
combinedData_sub <- combinedData_sub %>%
  filter(!(subject %in% bad_subjects$subject))

# Subject means AFTER exclusion
subject_means_after <- combinedData_sub %>%
  group_by(subject) %>%
  summarize(mean_DV = mean(DV, na.rm = TRUE), .groups = "drop")


library(lme4)
library(performance)
library(moments)

### TRIAL-LEVEL GAUSSIAN LMM (for diagnostics only)
lmm_trial <- lmer(
  DV ~ repetition * context + (1 | subject),
  data = combinedData_sub,
  REML = TRUE
)

res_trial <- residuals(lmm_trial)

cat("\n=== Trial-level residual diagnostics ===\n")
cat("Skewness:", round(skewness(res_trial), 3), "\n")
cat("Kurtosis:", round(kurtosis(res_trial), 3), "\n")

# Proportion of large residuals
std_res_trial <- scale(res_trial)
cat("Prop |z| > 2:", mean(abs(std_res_trial) > 2), "\n")
cat("Prop |z| > 3:", mean(abs(std_res_trial) > 3), "\n")

# Plots
par(mfrow = c(1,2))
hist(res_trial, breaks = 40, main = "Trial-level residuals", xlab = "Residual")
qqnorm(res_trial); qqline(res_trial)
par(mfrow = c(1,1))


### SUBJECT-LEVEL CELL MEANS
anova_dat_check <- combinedData_sub %>%
  group_by(subject, repetition, context) %>%
  summarize(DV = mean(DV, na.rm = TRUE), .groups = "drop")

lmm_means <- lmer(
  DV ~ repetition * context + (1 | subject),
  data = anova_dat_check,
  REML = TRUE
)

res_means <- residuals(lmm_means)

cat("\n=== Subject-mean residual diagnostics ===\n")
cat("Skewness:", round(skewness(res_means), 3), "\n")
cat("Kurtosis:", round(kurtosis(res_means), 3), "\n")

par(mfrow = c(1,2))
hist(res_means, breaks = 20, main = "Mean-level residuals", xlab = "Residual")
qqnorm(res_means); qqline(res_means)
par(mfrow = c(1,1))

### RM-ANOVA (subject-level means) ----

library(afex)
library(emmeans)

anova_dat <- combinedData_sub %>%
  group_by(subject, repetition, context) %>%
  summarize(DV = mean(DV, na.rm = TRUE), .groups = "drop")

aov_mod <- aov_ez(
  id = "subject",
  dv = "DV",
  data = anova_dat,
  within = c("repetition", "context"),
  type = 3
)

anova_tbl <- anova(aov_mod)
print(anova_tbl)


### Trial-level LMM ----

library(lmerTest)

lmm_trial_full <- lmer(
  DV ~ repetition * context + (1 | subject),
  data = combinedData_sub,
  REML = TRUE
)

summary(lmm_trial_full)
anova(lmm_trial_full, type = 3)


library(dplyr)
library(lme4)
library(glmmTMB)
library(ggplot2)

set.seed(1)

# --- Choose model family: "gaussian" or "gamma" ---
family_choice <- "gaussian"   # <- change to "gaussian" if you want LMM instead

# --- Use the already-preprocessed combinedData_sub from your current pipeline ---
# Make sure DV exists and subject/repetition/context are factors.

dat0 <- combinedData_sub %>%
  filter(repetition %in% c("1","5"),
         context %in% c("No Change","Change"))

if (family_choice == "gamma") {
  dat0 <- dat0 %>% filter(DV > 0)
}

subjects <- sort(unique(dat0$subject))
N <- length(subjects)

step_size <- 2
start_k <- max(10, step_size)  # start with at least ~10 subjects for stability
ks <- seq(from = start_k, to = N, by = step_size)

fit_two_models <- function(dat, family_choice = "gamma") {
  if (family_choice == "gaussian") {
    m_add <- lmer(DV ~ repetition + context + (1|subject),
                  data = dat, REML = FALSE)
    m_int <- lmer(DV ~ repetition * context + (1|subject),
                  data = dat, REML = FALSE)
    lr <- anova(m_add, m_int)  # LRT
    out <- list(
      AIC_add = AIC(m_add),
      AIC_int = AIC(m_int),
      ll_add  = as.numeric(logLik(m_add)),
      ll_int  = as.numeric(logLik(m_int)),
      chisq   = lr$Chisq[2],
      df      = lr$`Chi Df`[2],
      p       = lr$`Pr(>Chisq)`[2]
    )
    return(out)
  }
  
  if (family_choice == "gamma") {
    m_add <- glmmTMB(DV ~ repetition + context + (1|subject),
                     data = dat, family = Gamma(link="log"))
    m_int <- glmmTMB(DV ~ repetition * context + (1|subject),
                     data = dat, family = Gamma(link="log"))
    lr <- anova(m_add, m_int)  # LRT
    out <- list(
      AIC_add = AIC(m_add),
      AIC_int = AIC(m_int),
      ll_add  = as.numeric(logLik(m_add)),
      ll_int  = as.numeric(logLik(m_int)),
      chisq   = lr$Chisq[2],
      df      = lr$Df[2],
      p       = lr$`Pr(>Chisq)`[2]
    )
    return(out)
  }
  
  stop("family_choice must be 'gaussian' or 'gamma'")
}

seq_res <- data.frame(
  n_subjects = integer(),
  dAIC = numeric(),
  chisq = numeric(),
  df = numeric(),
  p = numeric(),
  stringsAsFactors = FALSE
)

for (k in ks) {
  dat_k <- dat0 %>% filter(subject %in% subjects[1:k])
  
  # guard against incomplete cells per subject (optional but safer)
  # This keeps only subjects who have both repetitions and both contexts at this step
  expected_cells <- 4
  complete_subs <- dat_k %>%
    count(subject, repetition, context) %>%
    count(subject) %>%
    filter(n == expected_cells) %>%
    pull(subject)
  
  dat_k <- dat_k %>% filter(subject %in% complete_subs)
  
  if (length(unique(dat_k$subject)) < start_k) next
  
  fit <- fit_two_models(dat_k, family_choice)
  
  seq_res <- rbind(seq_res, data.frame(
    n_subjects = length(unique(dat_k$subject)),
    dAIC = fit$AIC_add - fit$AIC_int,   # positive favors interaction
    chisq = fit$chisq,
    df = fit$df,
    p = fit$p
  ))
  
  cat("k =", length(unique(dat_k$subject)),
      "| dAIC =", round(fit$AIC_add - fit$AIC_int, 2),
      "| p =", signif(fit$p, 3), "\n")
}

# --- Plot 1: dAIC trajectory ---
p1 <- ggplot(seq_res, aes(x = n_subjects, y = dAIC)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_line() + geom_point() +
  labs(
    title = paste0("Sequential evidence for interaction (", family_choice, " mixed model)"),
    subtitle = "dAIC = AIC(additive) − AIC(interaction). Positive favors interaction.",
    x = "Number of subjects included",
    y = "dAIC (positive = interaction better)"
  ) +
  theme_minimal(base_size = 12)

print(p1)

# --- Plot 2: -log10(p) trajectory (optional) ---
p2 <- ggplot(seq_res, aes(x = n_subjects, y = -log10(p))) +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed") +
  geom_line() + geom_point() +
  labs(
    title = "Sequential LRT significance for interaction",
    subtitle = "Dashed line corresponds to p = .05",
    x = "Number of subjects included",
    y = "-log10(p)"
  ) +
  theme_minimal(base_size = 12)

print(p2)

seq_res




