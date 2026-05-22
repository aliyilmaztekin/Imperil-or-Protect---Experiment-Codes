# Imperil or Protect - Experiment 4 - Gamma GLMM Sample Size Simulation
# Coded by A.Y.

### SETUP/PARAMETERS ----

library(R.matlab)
library(dplyr)
library(ggplot2)
library(rlang)
library(lme4)
library(purrr)
library(future)
library(furrr)

options(scipen = 999)

base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4/"

# =========================
# Parallel settings
# =========================

plan(multisession, workers = min(7, parallel::detectCores() - 1))

# =========================
# Load data
# =========================

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

# =========================
# Preprocessing
# =========================

dependent_variable <- "angle1"
dv <- sym(dependent_variable)

bad_subjects <- combinedData %>%
  mutate(
    subject = factor(subject),
    angle1_num = as.numeric(as.character(angle1)),
    angle1_abs = abs(((angle1_num + 180) %% 360) - 180)
  ) %>%
  filter(is.finite(angle1_abs), is.finite(rt1), rt1 >= 0.3) %>%
  group_by(subject) %>%
  summarize(mean_abs_angle1 = mean(angle1_abs, na.rm = TRUE), .groups = "drop") %>%
  filter(mean_abs_angle1 > 45)

message("Excluded subjects (mean abs circular error > 45°):")
print(bad_subjects)

combinedData_sub <- combinedData %>%
  mutate(subject = factor(subject)) %>%
  filter(!(subject %in% bad_subjects$subject))

combinedData_sub <- combinedData_sub %>%
  dplyr::mutate(
    raw_outcome = as.numeric(as.character(.data[[dependent_variable]])),
    
    outcome = if (dependent_variable %in% c("rt1", "rt2")) {
      raw_outcome
    } else {
      abs(((raw_outcome + 180) %% 360) - 180)
    },
    
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change"))
  ) %>%
  dplyr::filter(
    is.finite(outcome),
    outcome > 0,
    is.finite(rt1),
    rt1 >= 0.3,
    repetition %in% c("1", "5"),
    context %in% c("No Change", "Change")
  )
# =========================
# Select pilot data
# =========================

pilot_subjects <- levels(combinedData_sub$subject)

model_data <- combinedData_sub %>%
  filter(subject %in% pilot_subjects) %>%
  mutate(subject = droplevels(subject))

# =========================
# Fit pilot model
# =========================

pilot_mod <- glmer(
  outcome ~ repetition * context + (1 | subject),
  family = Gamma(link = "log"),
  data = model_data,
  control = glmerControl(optimizer = "bobyqa")
)

summary(pilot_mod)

# =========================
# Set assumed effect size
# =========================
# This is the assumed repetition × context interaction
# on the Gamma log-link scale.
#
# beta = 0.09 means exp(0.09) = 1.094,
# i.e., about a 9.4% multiplicative interaction effect.

# small  ≈ 1.4° → β = 0.066
# medium ≈ 2.0° → β ≈ 0.092
# large  ≈ 3.0° → β ≈ 0.134

# =========================
# Set assumed effect size
# =========================

assumed_interaction_beta <- 0.136

sim_beta <- fixef(pilot_mod)
sim_beta["repetition5:contextChange"] <- assumed_interaction_beta

message("Assumed interaction beta:")
print(sim_beta["repetition5:contextChange"])

message("Assumed multiplicative ratio:")
print(exp(sim_beta["repetition5:contextChange"]))

# =========================
# Subject sample-size simulation
# =========================

simulate_subject_power <- function(N, nsim = 200, alpha = .05) {
  
  p_vals <- map_dbl(
    seq_len(nsim),
    function(i) {
      
      pilot_ids <- unique(model_data$subject)
      sampled_subjects <- sample(pilot_ids, N, replace = TRUE)
      
      sim_data <- map2_dfr(
        sampled_subjects,
        seq_along(sampled_subjects),
        function(subj_id, new_id) {
          
          model_data %>%
            filter(subject == subj_id) %>%
            mutate(subject = factor(paste0("simSub_", new_id)))
        }
      )
      
      sim_data$sim_y <- simulate(
        pilot_mod,
        newdata = sim_data,
        newparams = list(beta = sim_beta),
        allow.new.levels = TRUE
      )[[1]]
      
      fit_i <- try(
        glmer(
          sim_y ~ repetition * context + (1 | subject),
          family = Gamma(link = "log"),
          data = sim_data,
          control = glmerControl(optimizer = "bobyqa")
        ),
        silent = TRUE
      )
      
      if (inherits(fit_i, "try-error")) {
        return(NA_real_)
      }
      
      coef_tab <- summary(fit_i)$coefficients
      
      if ("repetition5:contextChange" %in% rownames(coef_tab)) {
        coef_tab["repetition5:contextChange", "Pr(>|z|)"]
      } else {
        NA_real_
      }
    }
  )
  
  mean(p_vals < alpha, na.rm = TRUE)
}

# =========================
# Run sample-size simulation
# =========================

Ns <- c(30, 40, 50, 60, 70, 80, 90, 100, 110, 120)


power_vals <- future_map_dbl(
  Ns,
  function(N) {
    simulate_subject_power(N, nsim = 1000)
  },
  .options = furrr_options(seed = TRUE)
)

sample_size_power_df <- data.frame(
  N = Ns,
  power = power_vals
)

print(sample_size_power_df)

# =========================
# Find required sample size
# =========================

target_power <- 0.80

required_N <- sample_size_power_df %>%
  filter(power >= target_power) %>%
  slice(1)

message("Estimated required sample size for 80% power:")
print(required_N)

# =========================
# Plot sample-size power curve
# =========================

ggplot(sample_size_power_df, aes(x = N, y = power)) +
  geom_line() +
  geom_point(size = 3) +
  geom_hline(yintercept = target_power, linetype = "dashed") +
  scale_y_continuous(limits = c(0, 1)) +
  labs(
    x = "Number of subjects",
    y = "Power",
    title = "Gamma GLMM Sample Size Simulation"
  ) +
  theme_classic(base_size = 16)

# =========================
# Turn off parallel processing
# =========================

plan(sequential)