# Imperil or Protect – Experiment 4
# Linear Mixed-Effects Analysis
# Coded by A.Y.

### 0) SETUP
library(dplyr) 
library(R.matlab) # Data extraction
library(lme4) # Linear Mixed Modelling
library(lmerTest) # LMM effect sizes
library(emmeans) # EMMs
library(ggplot2) # Plotting
library(moments) # Skewness values
library(stringr)
options(scipen = 999)  # Avoid scientific notation
library(writexl)
library(tidyr)
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

### Enter DV of interest
DV <- "angle1"

### 1) PREPROCESSING

# Extract only the data you wish to analyze
combinedData_sub <- combinedData %>% 
  mutate(
    subject    = (subject),
    repetition = (repetition),
    context    = (context),
    # Take the absolute form of your outcome measures
    outcome = abs(!!sym(DV)), 
  ) %>%
  filter(
    # Filter the data set down to the critical trials
    repetition %in% c("1", "5"),
    context %in% c("0", "1")
  ) %>%
  # Filter out missed probes
  filter(!is.na(outcome)) %>%
  droplevels()

cleanedData <- combinedData_sub

cleanedData <- cleanedData %>%
  mutate(
    rep1c0 = if_else(repetition == 1 & context == 0, outcome, NA_real_),
    rep1c1 = if_else(repetition == 1 & context == 1, outcome, NA_real_),
    rep5c0 = if_else(repetition == 5 & context == 0, outcome, NA_real_),
    rep5c1 = if_else(repetition == 5 & context == 1, outcome, NA_real_)
  )


cleanedData_wide <- cleanedData %>%
  mutate(rep_context = paste0("rep", repetition, "c", context)) %>%  # label columns
  select(subject, rep_context, outcome) %>%                          # keep only relevant info
  pivot_wider(
    names_from = rep_context,
    values_from = outcome
  )

write_xlsx(cleanedData_wide, "/Users/ali/Desktop/cleanedDataWide_exp4.xlsx")

### Log transform the data? 
log_me <- FALSE

# Log-transform if log_me is TRUE
cleanedData <- cleanedData %>%
  mutate(
    outcome = if (log_me) log1p(outcome) else outcome
  )

### 2) DESCRIPTIVE STATISTICS
# Reverse the log transformation if done 
cleanedData_desc <- cleanedData %>%
  mutate(
    outcome = if (log_me) exp(outcome) - 1 else outcome
  )

# Compute descriptive parameters
descriptives <- cleanedData_desc %>%
  group_by(repetition, context) %>%
  summarize(
    mean = mean(outcome, na.rm = TRUE),
    sd   = sd(outcome, na.rm = TRUE),
    n        = n(),
    .groups = "drop"
  )

### 3) INFERENTIAL STATISTICS
# Do the test by building the formula  
test <- lmer(
  outcome ~ repetition * context + (1 | subject),
  data = cleanedData
)

# QQ plot log1p residuals
qqnorm(resid(test))
qqline(resid(test), col = "blue", lwd = 2)

lmer_results <- summary(test)

### 4) INTERPRETTING THE TEST RESULTS 

# Estimate the marginal means for the highest-level effect that's significant
# If any lower-level effect that is not a part of a higher-level effect exists, do it too.  
# Lastly, visualize the relevant results.

# Identify the significant effects
sig_effects <- lmer_results$coefficients[, "Pr(>|t|)"]
sig_df <- data.frame(
  effect = names(sig_effects),
  p_value = sig_effects
) %>%
  filter(p_value < 0.05)

# Clean the table of irrelevant information
sig_df <- sig_df %>%
  filter(effect != "(Intercept)")

# Separate main effects and interactions
interaction_effects <- sig_df$effect[str_detect(sig_df$effect, ":")]
main_effects        <- sig_df$effect[!str_detect(sig_df$effect, ":")]

# Helper function that strips numeric level suffixes
strip_levels <- function(x) {
  str_replace_all(x, "[0-9]+$", "")
}

# A further cleaning of effect names
interaction_factors <- interaction_effects %>%
  str_split(":", simplify = FALSE) %>%
  lapply(strip_levels) %>%
  lapply(unique) %>%
  lapply(sort)

main_factors <- strip_levels(main_effects)

# Store plots that need to be shown in here
plots <- list()

# Dynamically determine the y-label depending on the analyzed DV
y_label <- y_label <- ifelse(
  DV %in% c("angle1", "angle2"),
  "Angular Error",
  "Reaction Time"
)

if (length(interaction_factors) > 0) {
  if (length(interaction_factors) > 0) {
    for (factors in interaction_factors) {
      
      emm_formula <- as.formula(paste("~", paste(factors, collapse = "*")))
      emm_int <- emmeans(test, emm_formula)
      
      emm_df <- as.data.frame(summary(emm_int))
      
      alpha <- 0.05
      z <- qnorm(1 - alpha/2)
      emm_df$lower.CL <- emm_df$emmean - z * emm_df$SE
      emm_df$upper.CL <- emm_df$emmean + z * emm_df$SE
      
      p <- ggplot(
        emm_df,
        aes_string(
          x     = factors[2],
          y     = "emmean",
          color = factors[1],
          group = factors[1]
        )
      ) +
        geom_point(size = 3) +
        geom_line(linewidth = 1) +
        geom_errorbar(
          aes(ymin = lower.CL, ymax = upper.CL),
          width = 0.15
        ) +
        labs(y = y_label) +
        theme_classic(base_size = 15)
      
      plots[[paste(factors, collapse = ":")]] <- p
    }
  }
}

interaction_terms <- unique(unlist(interaction_factors))

main_effects_to_plot <- main_factors[
  !main_factors %in% interaction_terms
]

for (factor_name in main_effects_to_plot) {
  
  emm_main <- emmeans(test, as.formula(paste("~", factor_name)))
  emm_df <- as.data.frame(summary(emm_main))
  
  alpha <- 0.05
  z <- qnorm(1 - alpha/2)
  emm_df$lower.CL <- emm_df$emmean - z * emm_df$SE
  emm_df$upper.CL <- emm_df$emmean + z * emm_df$SE
  
  p <- ggplot(
    emm_df,
    aes_string(x = factor_name, y = "emmean", group = 1)
  ) +
    geom_point(size = 3) +
    geom_line(linewidth = 1) +
    geom_errorbar(
      aes(ymin = lower.CL, ymax = upper.CL),
      width = 0.15
    ) +
    labs(y = y_label) +
    theme_classic(base_size = 15)
  
  plots[[factor_name]] <- p
}


# These values should be reported in the Results section as a leisurely exploration into your data
# Then should be followed by ANOVA results 
print(descriptives)

# Print the results
lmer_results
anova(test)

# Print out the plots
for (p in plots) print(p)

emm_df <- emm_df %>%
  mutate(
    emmean_bt   = exp(emmean) - 1,
    lower.CL_bt = exp(lower.CL) - 1,
    upper.CL_bt = exp(upper.CL) - 1
  )

print(emm_df)

