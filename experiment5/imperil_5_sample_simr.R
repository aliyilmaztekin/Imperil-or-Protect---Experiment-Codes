###############################
### POWER SIMULATION FOR WM REINSTATEMENT EXPERIMENT
###############################

library(lme4)
library(lmerTest)
library(tidyverse)

### -----------------------------
### PARAMETERS YOU CAN EDIT
### -----------------------------

# Trial structure
n_seq_per_cell <- 8        # sequences per condition
n_trials_per_seq <- 6      # trials per sequence

# Noise parameters (ms)
sd_within <- 120            # realistic trial-level dwell SD
sd_subject <- 80           # between-subject variability

# Effect sizes (ms)
# Baseline dwell times (arbitrary but reasonable)
rep1_mean <- 420
rep5_mean <- 330

# Reinstatement bump: increase on Rep5 in Repeated+Change only
bump_size <- 25            # try 20, 30, 40 ms etc.

# Number of simulations per sample size
nsim <- 1000

# Sample sizes to test
sample_sizes <- seq(20, 40, by = 2)

# Storage
power_results <- data.frame(N = sample_sizes, Power = NA)


### -----------------------------
### SIMULATION FUNCTION
### -----------------------------

simulate_dataset <- function(N) {
  
  # Create design matrix for 8 cells
  design <- expand.grid(
    BlockType = c("Repeated", "Novel"),
    Repetition = c("Rep1", "Rep5"),
    Context = c("Change", "NoChange"),
    seq = 1:n_seq_per_cell,
    trial = 1:n_trials_per_seq
  )
  
  # Repeat for subjects
  dat <- design %>%
    crossing(Subject = factor(1:N))
  
  # Subject random intercepts
  subj_intercepts <- rnorm(N, 0, sd_subject)
  
  # Add linear predictor for mean dwell time
  dat <- dat %>%
    mutate(
      mu = case_when(
        # Repeated block baseline
        BlockType == "Repeated" & Repetition == "Rep1" ~ rep1_mean,
        BlockType == "Repeated" & Repetition == "Rep5" ~ rep5_mean,
        
        # Novel block: assume flat baseline (no repetition effect)
        BlockType == "Novel" & Repetition == "Rep1" ~ rep1_mean,
        BlockType == "Novel" & Repetition == "Rep5" ~ rep1_mean - 5,  # tiny drop, or set to rep1_mean
        
        TRUE ~ rep1_mean
      ),
      
      # Add reinstatement bump ONLY for Repeated × Rep5 × Change
      mu = mu + ifelse(BlockType=="Repeated" & Repetition=="Rep5" & Context=="Change", bump_size, 0),
      
      # Add random subject intercept
      mu = mu + subj_intercepts[as.numeric(Subject)]
    )
  
  # Generate dwell times
  dat$Dwell <- rnorm(nrow(dat), mean = dat$mu, sd = sd_within)
  
  return(dat)
}



### -----------------------------
### RUN POWER ANALYSIS
### -----------------------------

for (i in seq_along(sample_sizes)) {
  
  N <- sample_sizes[i]
  cat("Simulating N =", N, "...\n")
  
  sig_count <- 0
  
  for (s in 1:nsim) {
    
    dat <- simulate_dataset(N)
    
    # Fit mixed model with 3-way interaction
    m <- suppressMessages(
      lmer(Dwell ~ BlockType * Repetition * Context + (1|Subject), data = dat)
    )
    
    # Extract p-value for the 3-way interaction
    an <- anova(m)
    p_threeway <- an["BlockType:Repetition:Context", "Pr(>F)"]
    
    if (!is.na(p_threeway) && p_threeway < 0.05) {
      sig_count <- sig_count + 1
    }
  }
  
  power_results$Power[i] <- sig_count / nsim
}

print(power_results)

# Plot power curve
library(ggplot2)

ggplot(power_results, aes(x = N, y = Power)) +
  geom_line(size = 1.2) +
  geom_point(size = 2.2) +
  ylim(0, 1) +
  labs(
    title = "Power curve for WM reinstatement bump",
    subtitle = paste("Effect size =", bump_size, "ms, SD within =", sd_within, "ms"),
    x = "Sample size",
    y = "Power"
  ) +
  theme_minimal(base_size = 14)
