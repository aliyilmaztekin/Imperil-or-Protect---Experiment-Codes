# Imperil or Protect – Experiment 4
# Bayesian Sequential RMAnova
# Coded by A.Y.

### 0) SETUP
library(dplyr) 
library(R.matlab) # Data extraction
library(brms)
library(BayesFactor)
library(ggplot2) # Plotting

options(scipen = 999)  # Avoid scientific notation

# Pull the data and store in a data frame
base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4/"
files <- list.files(base_dir, pattern = "\\.mat$", full.names = TRUE)
dfs <- lapply(files, function(f) {
  mat <- R.matlab::readMat(f)
  as.data.frame(mat$outputMatrix)
})
combinedData <- bind_rows(dfs)

# Name the columns
colnames(combinedData) <- c(
  "subject", "conditionUsed", "block", "trial", "repetition",
  "context", "contextCode", "primaryColor", "secondaryColor",
  "angle1", "initiation_time1", "movement_time1", "rt1",
  "angle2", "initiation_time2", "movement_time2", "rt2",
  "breakTaken", "conditions"
)

# Enter dependent variable to analyze
DV <- "angle1"

# Extract only the data you wish to analyze
combinedData_sub <- combinedData %>% 
  mutate(
    subject    = factor(subject),
    repetition = factor(repetition),
    context    = factor(context),
    # Take the absolute form of your outcome measures
    outcome = abs(!!sym(DV))
  ) %>%
  filter(
    # Filter the data set down to the critical trials
    repetition %in% c("1", "5"),
    context %in% c("0", "1")
  ) %>%
  # Filter out missed probes
  filter(!is.na(outcome)) %>%
  droplevels()

### 1) Fixed-N Bayesian RM ANOVA (for reference)

bf_full <- anovaBF(
  outcome ~ repetition * context + subject,
  data        = combinedData_sub,
  whichRandom = "subject",
  iterations = 10000
)
print(bf_full)


### 2) Sequential Bayes factor for the repetition × context interaction

# All subjects, in sorted order
subjects_all <- combinedData_sub %>%
  dplyr::pull(subject) %>%
  unique() %>%
  sort()

# Helper to compute BF for the interaction (full vs additive model)
compute_bf_interaction <- function(data, subjects) {
  d <- data %>%
    dplyr::filter(subject %in% subjects) %>%
    droplevels()

  # Need at least 2 subjects and 2 levels in each within factor
  if (length(unique(d$subject)) < 2 ||
      nlevels(d$repetition) < 2 ||
      nlevels(d$context) < 2) {
    return(NA_real_)
  }

  # Fit all candidate models once
  bf_all <- anovaBF(
    outcome ~ repetition * context + subject,
    data        = d,
    whichRandom = "subject"
  )

  # You observed that bf_all prints as:
  # [1] repetition + subject
  # [2] context + subject
  # [3] repetition + context + subject
  # [4] repetition + context + repetition:context + subject
  #
  # So we can directly take index 4 as the full (interaction) model
  # and index 3 as the additive (no-interaction) model.
  if (length(bf_all) < 4) {
    return(NA_real_)
  }

  # With onlybf = TRUE this is already a numeric vector
  bf_vals <- extractBF(bf_all, onlybf = TRUE)

  # BF for interaction = BF(full) / BF(additive)
  as.numeric(bf_vals[4] / bf_vals[3])
}

# Sequential BF trajectory parameters
min_N            <- 10      # first sample size at which to start tracking
step_size        <- 2       # step size in number of subjects
bf_threshold_H1  <- 10      # reference threshold for H1 (interaction present)
bf_threshold_H0  <- 1 / 10  # reference threshold for H0 (no interaction)

seq_results <- data.frame(
  n_subjects = integer(),
  BF10       = numeric(),
  stringsAsFactors = FALSE
)

# Track BF10 for every k from min_N up to the full sample in steps of `step_size`
for (k in seq(from = min_N, to = length(subjects_all), by = step_size)) {
  current_subjects <- subjects_all[1:k]
  bf_k <- compute_bf_interaction(combinedData_sub, current_subjects)

  seq_results <- rbind(
    seq_results,
    data.frame(
      n_subjects = k,
      BF10       = bf_k,
      stringsAsFactors = FALSE
    )
  )
}

print(seq_results)

# Determine the smallest sample size giving strong evidence for H1 or H0
sample_size_H1 <- if (any(seq_results$BF10 >= bf_threshold_H1, na.rm = TRUE)) {
  min(seq_results$n_subjects[seq_results$BF10 >= bf_threshold_H1], na.rm = TRUE)
} else {
  NA_integer_
}

sample_size_H0 <- if (any(seq_results$BF10 <= bf_threshold_H0, na.rm = TRUE)) {
  min(seq_results$n_subjects[seq_results$BF10 <= bf_threshold_H0], na.rm = TRUE)
} else {
  NA_integer_
}

cat("\nEstimated sample size for strong evidence in favor of interaction (BF10 >=", 
    bf_threshold_H1, "):", sample_size_H1, "subjects\n")
cat("Estimated sample size for strong evidence for no interaction (BF10 <=", 
    bf_threshold_H0, "):", sample_size_H0, "subjects\n\n")

# Simple plot of BF trajectory across subjects
ggplot(seq_results, aes(x = n_subjects, y = BF10)) +
  geom_line() +
  geom_point() +
  geom_hline(yintercept = bf_threshold_H1, linetype = "dashed", color = "darkgreen") +
  geom_hline(yintercept = bf_threshold_H0, linetype = "dashed", color = "red") +
  scale_y_log10(
    breaks = c(0.1, 0.2, 0.5, 1, 2, 5, 10),
    labels = c("0.1", "0.2", "0.5", "1", "2", "5", "10")
  ) +
  labs(
    x = "Number of subjects",
    y = "Bayes factor BF10 (interaction vs additive)",
    title = "Sequential Bayes factor for repetition × context interaction"
  ) +
  theme_minimal()