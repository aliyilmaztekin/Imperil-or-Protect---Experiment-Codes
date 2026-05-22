# Imperil or Protect - Experiment 4 - Gamma GLMM Sample Size Simulation
# Coded by A.Y. 

### SETUP/PARAMETERS ----

library(R.matlab)
library(dplyr)
library(ggplot2)
library(ggplot2)
library(rlang)
library(simr)
library(lme4)

options(scipen = 999)  # Avoid scientific notation

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

### PREPROCESSING ----

dependent_variable <- "angle1"
independent_variables <- c("repetition", "context")

# 1) Subject exclusions based on ANGLE1
bad_subjects <- combinedData %>%
  dplyr::mutate(
    subject = factor(subject),
    angle1_num = as.numeric(as.character(angle1)),
    angle1_abs = abs(((angle1_num + 180) %% 360) - 180)
  ) %>%
  dplyr::filter(is.finite(angle1_abs), is.finite(rt1), rt1 >= 0.3) %>% 
  dplyr::group_by(subject) %>%
  dplyr::summarise(
    mean_abs_angle1 = mean(angle1_abs, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  dplyr::filter(mean_abs_angle1 > 45)

message("Excluded subjects (mean abs circular error > 45°):")
print(bad_subjects)

# 2) Apply exclusion to the raw data
combinedData_sub <- combinedData %>%
  dplyr::mutate(subject = factor(subject)) %>%
  dplyr::filter(!(subject %in% bad_subjects$subject))

# 3) DV-specific pre-processing
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
  dplyr::filter(is.finite(outcome), is.finite(rt1), rt1 >= 0.3) %>%
  dplyr::filter(
    repetition %in% c("1", "5"),
    context %in% c("No Change", "Change")
  )

combinedData_sub <- combinedData_sub %>%
  filter(is.finite(outcome), outcome > 0)


library(dplyr)
library(lme4)
library(purrr)

# Make sure contrasts produce coefficient names like repetition5:contextChange

# Fit model to full previous dataset or pilot subset
base_mod <- glmer(
  outcome ~ repetition * context + (1 | subject),
  family = Gamma(link = "log"),
  data = combinedData_sub
)

# Optional: set the interaction effect manually
sim_mod <- base_mod
fixef(sim_mod)["repetition5:contextChange"] <- 0.09


simulate_trial_power <- function(data, model, k, nsim = 200, alpha = .05) {
  
  p_vals <- numeric(nsim)
  
  for (i in seq_len(nsim)) {
    
    # 1. sample k trials per subject x condition
    design_k <- data %>%
      group_by(subject, repetition, context) %>%
      slice_sample(n = k, replace = TRUE) %>%
      ungroup()
    
    # 2. simulate new outcome from Gamma GLMM
    design_k$sim_y <- simulate(model, newdata = design_k, allow.new.levels = TRUE)[[1]]
    
    # 3. refit model
    fit_i <- try(
      glmer(
        sim_y ~ repetition * context + (1 | subject),
        family = Gamma(link = "log"),
        data = design_k
      ),
      silent = TRUE
    )
    
    if (inherits(fit_i, "try-error")) {
      p_vals[i] <- NA
    } else {
      coef_tab <- summary(fit_i)$coefficients
      
      if ("repetition5:contextChange" %in% rownames(coef_tab)) {
        p_vals[i] <- coef_tab["repetition5:contextChange", "Pr(>|z|)"]
      } else {
        p_vals[i] <- NA
      }
    }
  }
  
  mean(p_vals < alpha, na.rm = TRUE)
}

k_vals <- c(10, 20, 30, 40, 50, 60, 80)

trial_power <- sapply(
  k_vals,
  function(k) simulate_trial_power(
    data = combinedData_sub,
    model = sim_mod,
    k = k,
    nsim = 200
  )
)

trial_power_df <- data.frame(
  trials_per_condition = k_vals,
  power = trial_power
)

print(trial_power_df)

plot(
  trial_power_df$trials_per_condition,
  trial_power_df$power,
  type = "b",
  ylim = c(0, 1),
  xlab = "Trials per subject × condition",
  ylab = "Power"
)

abline(h = .80, col = "red")





# Data subset to feed into the simulation
pilot_subjects <- levels(combinedData_sub$subject)

simFeed <- combinedData_sub %>%
  filter(subject %in% pilot_subjects)

simFeed$subject <- droplevels(simFeed$subject)

pilot_mod <- glmer(
  outcome ~ repetition * context + (1 | subject),
  family = Gamma(link = "log"),
  data = simFeed
)

# model_extended <- extend(model_lme4, along = "subject", n = 100)
# 
# powerSim(
#   model_extended,
#   test = fixed("repetition5:contextChange", method = "z"),
#   nsim = 500
# )

small_mod <- pilot_mod
fixef(small_mod)["repetition5:contextChange"] <- 0.05

mid_mod <- pilot_mod
fixef(mid_mod)["repetition5:contextChange"] <- 0.068

large_mod <- pilot_mod
fixef(large_mod)["repetition5:contextChange"] <- 0.11

Ns <- c(30, 40, 50, 60, 70, 80, 90, 100, 110, 120)

# small_mod_ext <- extend(small_mod, along = "subject", n = max(Ns))
mid_mod_ext   <- extend(mid_mod,   along = "subject", n = max(Ns))
# large_mod_ext <- extend(large_mod, along = "subject", n = max(Ns))

# pc_small <- powerCurve(
#   small_mod_ext,
#   along = "subject",
#   breaks = Ns,
#   test = fixed("repetition5:contextChange", method = "z"),
#   nsim = 100
# )
# 
# pc_small
# 
pc_mid <- powerCurve(
  mid_mod_ext,
  along = "subject",
  breaks = Ns,
  test = fixed("repetition5:contextChange", method = "z"),
  nsim = 500
)
pc_mid

# pc_large <- powerCurve(
#   large_mod_ext,
#   along = "subject",
#   breaks = Ns,
#   test = fixed("repetition5:contextChange", method = "z"),
#   nsim = 500
# )
# 
# pc_large


