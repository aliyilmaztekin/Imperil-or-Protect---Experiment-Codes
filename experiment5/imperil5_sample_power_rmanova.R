###############################
### POWER SIMULATION FOR WM REINSTATEMENT EXPERIMENT (RM-ANOVA)
###############################

library(tidyverse)
library(car)  # For Type III ANOVA

### -----------------------------
### PARAMETERS
### -----------------------------

# Trial structure
n_seq_per_cell <- 8        # sequences per condition
n_trials_per_seq <- 6      # trials per sequence

# Noise parameters (ms)
sd_within <- 120           # trial-level SD
sd_subject <- 80           # between-subject SD

# Effect sizes (ms)
rep1_mean <- 420
rep5_mean <- 330
bump_size <- 25            # effect in Repeated × Rep5 × Change

# Simulation settings
nsim <- 1000
sample_sizes <- seq(20, 40, by = 2)

# Storage
power_results <- data.frame(N = sample_sizes, Power = NA)


### -----------------------------
### SIMULATION FUNCTION
### -----------------------------

simulate_dataset_rm <- function(N) {
  
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
  
  # Random intercepts for subjects
  subj_intercepts <- rnorm(N, 0, sd_subject)
  
  # Mean dwell times
  dat <- dat %>%
    mutate(
      mu = case_when(
        BlockType == "Repeated" & Repetition == "Rep1" ~ rep1_mean,
        BlockType == "Repeated" & Repetition == "Rep5" ~ rep5_mean,
        BlockType == "Novel" & Repetition == "Rep1" ~ rep1_mean,
        BlockType == "Novel" & Repetition == "Rep5" ~ rep1_mean - 5,
        TRUE ~ rep1_mean
      ),
      mu = mu + ifelse(BlockType=="Repeated" & Repetition=="Rep5" & Context=="Change", bump_size, 0),
      mu = mu + subj_intercepts[as.numeric(Subject)]
    )
  
  # Generate dwell times
  dat$Dwell <- rnorm(nrow(dat), mean = dat$mu, sd = sd_within)
  
  # Average over trials & sequences for each subject × condition
  dat_avg <- dat %>%
    group_by(Subject, BlockType, Repetition, Context) %>%
    summarize(Dwell = mean(Dwell), .groups = "drop")
  
  return(dat_avg)
}


### -----------------------------
### RUN POWER ANALYSIS
### -----------------------------

for (i in seq_along(sample_sizes)) {
  
  N <- sample_sizes[i]
  cat("Simulating N =", N, "...\n")
  
  sig_count <- 0
  
  for (s in 1:nsim) {
    
    dat <- simulate_dataset_rm(N)
    
    # Fit repeated-measures ANOVA
    # Make factors
    dat$BlockType <- factor(dat$BlockType)
    dat$Repetition <- factor(dat$Repetition)
    dat$Context <- factor(dat$Context)
    
    # Wide format for aov with Error(Subject/...)
    # Or just use aov with Error(Subject/(BlockType*Repetition*Context))
    m <- aov(Dwell ~ BlockType*Repetition*Context + 
               Error(Subject/(BlockType*Repetition*Context)), data = dat)
    
    # Extract p-value for 3-way interaction
    # Using summary
    summ <- summary(m)
    
    # Navigate nested list to get BlockType:Repetition:Context
    # It's usually in summ[[2]][[1]] (check structure if needed)
    # We'll use a simple heuristic
    pval <- summ[[2]][[1]][["Pr(>F)"]]["BlockType:Repetition:Context"]
    
    if (!is.na(pval) && pval < 0.05) {
      sig_count <- sig_count + 1
    }
    
  }
  
  power_results$Power[i] <- sig_count / nsim
}

print(power_results)

# Plot power curve
ggplot(power_results, aes(x = N, y = Power)) +
  geom_line(size = 1.2) +
  geom_point(size = 2.2) +
  ylim(0, 1) +
  labs(
    title = "Power curve for WM reinstatement bump (RM-ANOVA)",
    subtitle = paste("Effect size =", bump_size, "ms, SD within =", sd_within, "ms"),
    x = "Sample size",
    y = "Power"
  ) +
  theme_minimal(base_size = 14)
