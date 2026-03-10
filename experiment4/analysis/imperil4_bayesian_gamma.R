# Imperil or Protect – Experiment 4
# Robust Bayesian sequential model comparison (Gamma GLMM) + sequential Bayes-factor trajectory
# Includes ANOVA preprocessing (RT exception, factor relabeling, subject-level outlier removal)
# Goal: track how BF for the INTERACTION model (vs Additive) evolves as subjects accrue
# Coded by A.Y.

### 0) SETUP ----
library(dplyr)
library(R.matlab)         # Data extraction
library(brms)             # Bayesian modeling (Stan backend)
library(bridgesampling)   # Bayes factors via bridge sampling
library(ggplot2)
library(loo)

options(scipen = 999)

### 1) LOAD MATLAB FILES ----
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

### 2) PREPROCESSING
dependent_variable    <- "angle1"                 
independent_variables <- c("repetition", "context")

combinedData_sub <- combinedData %>%
  mutate(
    DV = if (dependent_variable %in% c("rt1", "rt2")) {
      .data[[dependent_variable]]
    } else {
      abs(.data[[dependent_variable]])
    },
    subject = factor(subject),
    across(all_of(independent_variables), factor)
  ) %>%
  filter(is.finite(DV)) %>%
  filter(
    repetition %in% c(1, 5),
    context %in% c(0, 1)
  )

combinedData_sub <- combinedData_sub %>%
  mutate(
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context    = factor(context,    levels = c(0, 1), labels = c("No Change", "Change"))
  ) %>%
  droplevels()

# Subject-level outlier rejection (based on subject mean DV across included conditions)
subject_means <- combinedData_sub %>%
  group_by(subject) %>%
  summarize(mean_DV = mean(DV, na.rm = TRUE), .groups = "drop")

grand_mean <- mean(subject_means$mean_DV, na.rm = TRUE)
grand_sd   <- sd(subject_means$mean_DV, na.rm = TRUE)

if (is.na(grand_sd) || grand_sd == 0) {
  bad_subjects <- subject_means[0, ]
} else {
  bad_subjects <- subject_means %>%
    filter(!is.na(mean_DV)) %>%
    filter(abs(mean_DV - grand_mean) > 2.5 * grand_sd)
}

message("Subjects removed as outliers (subject-level mean DV > 2.5 SD from group mean):")
print(bad_subjects)

combinedData_sub <- combinedData_sub %>%
  filter(!(subject %in% bad_subjects$subject)) %>%
  droplevels()

# Gamma requires strictly positive outcomes.
# If you have exact zeros (common for abs(error)), you can:
#   A) drop them (filter(DV > 0)), or
#   B) add a tiny constant to keep them.
# Here we keep them by adding a tiny epsilon (safer for sequential analysis stability).
eps <- 1e-6
combinedData_sub <- combinedData_sub %>%
  mutate(DV = ifelse(DV <= 0, eps, DV)) %>%
  filter(is.finite(DV)) %>%
  droplevels()

stopifnot(all(combinedData_sub$DV > 0))

### 3) MODEL FORMS (compare Int vs ADDITIVE) ----
fR   <- brms::bf(DV ~ repetition + (1|subject))
fRC  <- brms::bf(DV ~ repetition + context + (1|subject))   # NEW
fInt <- brms::bf(DV ~ repetition * context + (1|subject))


### 4) PRIORS (Gamma) ----
priors_R <- c(
  prior(normal(0, 1), class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1), class = "sd"),
  prior(exponential(1), class = "shape")
)

priors_Int <- priors_R  # same structure of priors; Int model just has more b's

### 5) FIT SETTINGS (ROBUST / SLOW / FINAL) ----
ctrl <- list(adapt_delta = 0.95, max_treedepth = 12)

# save_pars(all=TRUE) is REQUIRED for bridge sampling Bayes factors.
common_args <- list(
  family     = Gamma(link = "log"),
  chains     = 4,
  cores      = 4,
  iter       = 4000,
  control    = ctrl,
  save_pars  = save_pars(all = TRUE),
  file_refit = "on_change",
  seed       = 123
)

### 6) FIT FULL-DATA MODELS ONCE ----
fitR_full <- do.call(
  brm,
  c(list(formula = fR, prior = priors_R, data = combinedData_sub), common_args)
)

fitRC_full <- do.call(
  brm,
  c(list(formula = fRC, prior = priors_R, data = combinedData_sub), common_args)
)

fitInt_full <- do.call(
  brm,
  c(list(formula = fInt, prior = priors_Int, data = combinedData_sub), common_args)
)

cat("\n===== FULL DATA: INTERACTION MODEL SUMMARY =====\n")
print(summary(fitInt_full))
cat("\n===== FULL DATA: BF(Int vs Additive) =====\n")
print(bayes_factor(fitInt_full, fitRC_full))
cat("\n===== FULL DATA: BF(Additive vs Repetition-only) [context main effect] =====\n")
print(bayes_factor(fitRC_full, fitR_full))


# Optional predictive check (should look better than Gaussian)
print(pp_check(fitInt_full, type = "dens_overlay"))

### 7) SEQUENTIAL BAYES FACTOR TRAJECTORY (Int vs Additive) ----
# We accumulate subjects in a fixed order and recompute BF at checkpoints.
# IMPORTANT: this is *order-dependent*. A common convention is ascending subject ID.
subjects_all <- sort(unique(combinedData_sub$subject))
N <- length(subjects_all)

# Choose how often to evaluate BF (every k subjects).
# Setting this to 1 is most granular but *very* slow.
k_step <- 2
checkpoints <- unique(c(seq(4, N, by = k_step), N))  # start at 4 subjects to avoid silly tiny-sample instability

traj <- data.frame(
  n_subjects = integer(0),
  bf_int_vs_add = numeric(0),
  log_bf = numeric(0)
)

fitRC_k <- NULL
fitInt_k <- NULL

for (m in checkpoints) {
  subj_m <- subjects_all[1:m]
  dat_m <- combinedData_sub %>% filter(subject %in% subj_m) %>% droplevels()
  
  cat("\n--- Sequential BF step:", m, "subjects ---\n")
  
  if (is.null(fitRC_k)) {
    fitRC_k <- do.call(
      brm,
      c(list(formula = fRC, prior = priors_R, data = dat_m), common_args)
    )
    fitInt_k <- do.call(
      brm,
      c(list(formula = fInt, prior = priors_Int, data = dat_m), common_args)
    )
  } else {
    fitRC_k   <- update(fitRC_k,  newdata = dat_m, recompile = FALSE, refresh = 0)
    fitInt_k  <- update(fitInt_k, newdata = dat_m, recompile = FALSE, refresh = 0)
  }
  
  # BF via bridge sampling
  bf_obj <- bayes_factor(fitInt_k, fitRC_k)  # Int vs ADDITIVE
  bf_val <- as.numeric(bf_obj$bf)
  
  traj <- rbind(
    traj,
    data.frame(
      n_subjects = m,
      bf_int_vs_add = bf_val,
      log_bf = log(bf_val)
    )
  )
  
  cat("BF(Int vs Additive) =", bf_val, " | log(BF) =", log(bf_val), "\n")
}

# Print the trajectory table
cat("\n===== SEQUENTIAL BF TRAJECTORY (Int vs Additive) =====\n")

print(traj)

# Plot trajectory (BF on log scale is easier to read)
p1 <- ggplot(traj, aes(x = n_subjects, y = log_bf)) +
  geom_line() +
  geom_point() +
  geom_hline(yintercept = log(1), linetype = "dashed") +
  labs(
    title = "Sequential evidence for Interaction (vs Additive)",
    subtitle = "log(BF) > 0 favors Interaction; log(BF) < 0 favors Additive",
    x = "Number of subjects included",
    y = "log Bayes Factor: Int vs Add"
  )

print(p1)

# Optional: also plot raw BF with a log y-axis
p2 <- ggplot(traj, aes(x = n_subjects, y = bf_int_vs_r)) +
  geom_line() +
  geom_point() +
  scale_y_log10() +
  geom_hline(yintercept = 1, linetype = "dashed") +
  labs(
    title = "Sequential Bayes Factor (log10 y-axis)",
    x = "Number of subjects included",
    y = "BF(Int vs Additive)"
  )

print(p2)

### 8) SIMPLE DECISION-AID PRINTS ----
# These are conventions, not laws, but useful:
# BF ~ 1: no evidence
# BF 3–10: moderate evidence
# BF > 10: strong evidence
# BF < 1/3 or < 1/10: evidence *against* interaction
traj_last <- traj[nrow(traj), ]
cat("\n===== FINAL CHECKPOINT =====\n")
cat("N subjects:", traj_last$n_subjects, "\n")
cat("BF(Int vs Additive):", traj_last$bf_int_vs_add, "\n")

if (traj_last$bf_int_vs_r >= 10) {
  cat("Interpretation: strong evidence FOR the interaction.\n")
} else if (traj_last$bf_int_vs_r >= 3) {
  cat("Interpretation: moderate evidence FOR the interaction.\n")
} else if (traj_last$bf_int_vs_r > 1/3 && traj_last$bf_int_vs_r < 3) {
  cat("Interpretation: weak/ambiguous evidence (near 1).\n")
} else if (traj_last$bf_int_vs_r <= 1/10) {
  cat("Interpretation: strong evidence AGAINST the interaction.\n")
} else if (traj_last$bf_int_vs_r <= 1/3) {
  cat("Interpretation: moderate evidence AGAINST the interaction.\n")
}

### Notes / knobs you can safely change:
# - k_step: 1 = every subject (slowest); 2–5 is usually a good compromise.
# - checkpoints: you can specify a custom vector if you want.
# - eps: if you dislike adding eps, replace with filter(DV > 0) instead.
# - For even more robustness, consider adding random slopes later, but that can explode runtime.
