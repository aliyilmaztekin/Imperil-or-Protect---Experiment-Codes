# Imperil or Protect - Experiment 2 - Analysis
# Coded by A.Y. 

### SETUP/PARAMETERS

# Install/load libraries
library(R.matlab)
library(dplyr)
library(tidyr)
library(ez)
library(ggplot2)
library(moments)
library(emmeans)
library(stringr)
options(scipen = 999)  # Avoid scientific notation

# 1) Load MAT files
raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment1_sixlets_anova.mat"
raw_data_read <- readMat(raw_data)

# 2) Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment1.sixlets.anova
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# 3) Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "repetition", "block", "angle",
  "rt", "initiation_time", "movement_time",
  "condition", "context", "interference"
)

# 4) Rename the dataset (optional)
combinedData <- raw_data_data_frame


### PREPROCESSING

# 1) Put in your DV and IVs
dependent_variable <- "rt"
independent_variables <- c("repetition", "context", "interference")

# 2) Log-transform your dependent variable? Check true if yes. 
log_me <- TRUE

# 3) Add a small epsilon value to your raw data before log-transform to avoid log(0)? 
epsilon_yes <- TRUE
epsilon <- if (epsilon_yes) 1e-6 else 0

# 4) Turn IVs into factors
combinedData_sub <- combinedData %>%
  mutate(
    DV = .data[[dependent_variable]],  
    across(all_of(independent_variables), factor)
  )

# 5) Apply log transform as requested
if (log_me) {
  if (epsilon_yes) {
    combinedData_sub <- combinedData_sub %>%
      mutate(DV = log(DV + epsilon))
  } else {
    combinedData_sub <- combinedData_sub %>%
      mutate(DV = log(DV))
  }
}

# 6) Outlier rejection
combinedData_sub <- combinedData_sub %>%
  group_by(subject) %>%
  mutate(mean_DV = mean(DV, na.rm = TRUE),
         sd_DV   = sd(DV, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(DV >= (mean_DV - 2.5 * sd_DV) &
           DV <= (mean_DV + 2.5 * sd_DV)) %>%
  select(-mean_DV, -sd_DV)  # drop temporary columns


# 7) Squeeze the dataset down to the critical item repetitions (1st & 5th)
combinedData_sub <- combinedData_sub %>%
  filter(
    repetition %in% c(1, 5),
    context %in% c(0, 1),
    interference %in% c(0, 1)
  )


## DESCRIPTIVE ANALYSIS
# 1) Describe the data in the report before ANOVA. This can't be done on log-transformed data.
# Thus, first store the raw version of your data

# Store the raw data, convert your IVs into factors
combinedData_desc <- combinedData %>%
  mutate(
    DV_raw = .data[[dependent_variable]],            
    across(all_of(independent_variables), factor)   
  ) %>%
  filter(!is.na(DV_raw))

# 2) Outlier rejection on the descriptive data
combinedData_desc <- combinedData_desc %>%
  group_by(subject) %>%
  mutate(
    mean_raw = mean(DV_raw, na.rm = TRUE),
    sd_raw   = sd(DV_raw, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(
    DV_raw >= (mean_raw - 2.5 * sd_raw) &
      DV_raw <= (mean_raw + 2.5 * sd_raw)
  ) %>%
  select(-mean_raw, -sd_raw)

# 3) Filter the descriptive data down to the critical item repetitions
combinedData_desc <- combinedData_desc %>%
  filter(
    repetition %in% c(1, 5),
    context %in% c(0, 1),
    interference %in% c(0, 1)
  )

# 4) Finally, compute means and SDs for each condition. 
descriptives <- combinedData_desc %>%
  group_by(repetition, context, interference) %>%
  summarize(
    mean_raw = mean(DV_raw, na.rm = TRUE),
    sd_raw   = sd(DV_raw, na.rm = TRUE),
    n        = n(),
    .groups = "drop"
  )

# These values should be reported in the Results section as a leisurely exploration into your data
# Then should be followed by ANOVA results 
print(descriptives)

## INFERENTIAL ANALYSIS

# 1) First, convert your data frame into a format that ANOVA can work with. 
# The following does that by grouping your data into experimental conditions 
# and computing the average outcome values for each. 

data_RMAnova <- combinedData_sub %>%
  group_by(subject, repetition, context, interference) %>%
  summarize(mean_DV = mean(DV), .groups = "drop")

# 2) Do the ANOVA test 
anova_res <- ezANOVA(
  data = data_RMAnova,
  dv = mean_DV, # <- Input here the summary estimate of your dependent variable           
  wid = subject, # <- Input here the subjects column
  within = .(repetition, context, interference), # Input here your factors
  type = 3,
  detailed = TRUE
)

# 3) Add effect sizes to the table, also edit the numbers for better readability
anova_clean <- anova_res$ANOVA %>%
  mutate(
    eta_p2 = SSn / (SSn + SSd)
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))

# Report these as your ANOVA results
print(anova_clean)

### ESTIMATED MARGINAL MEANS

# 4) Now, you know which factors are significant. But you don't know their directions. 
# That's why you need to estimate marginal means. 

# Fit a linear model with all main effects and interactions
lm_mod <- lm(mean_DV ~ repetition * context * interference, data = data_RMAnova)

# 5) Compute EMMs
# EMMs should be computed only for the significant effects, and each effect is analyzed separately. 

# Fetch the effects that are significant
sig_effects <- anova_clean$Effect[anova_clean$`p<.05` == "*"]
sig_effects <- sig_effects[-1]

# Estimate marginal means depending on the effect type
for (effect in 1:length(sig_effects)) {
  if (str_count(sig_effects[effect], fixed(":")) == 0) {
    
    # Select current significant effect
    factor_name <- sig_effects[effect]
    
    # Build the formula dynamically
    emm_formula <- as.formula(paste("~", factor_name))
    
    # Compute EMM
    emm_one_way <- emmeans(lm_mod, emm_formula)
    
    # Back-transform EMMs to original scale (you can't report the results in log units)
    emm_one_way_back <- summary(emm_one_way, infer = TRUE) %>%
      as.data.frame() %>%
      mutate(
        emmean_orig = exp(emmean) - epsilon,           
        lower.CL_orig = exp(lower.CL) - epsilon,       
        upper.CL_orig = exp(upper.CL) - epsilon
      )
    
    # Edit out the irrelevant information
    emm_one_way_back_clean <- emm_one_way_back %>%
      mutate(
        emmean_orig = round(emmean_orig, 2),
        lower.CL_orig = round(lower.CL_orig, 2),
        upper.CL_orig = round(upper.CL_orig, 2)
      ) %>%
      select(all_of(factor_name), emmean_orig, lower.CL_orig, upper.CL_orig)
    
    # Report these as your EMM results
    print(emm_one_way_back_clean)
    
  } else if (str_count(sig_effects[effect], fixed(":")) == 1) {
    
    # Current significant effect
    factor_name <- sig_effects[effect]
    
    # Parse the factor name into a vector
    factors <- str_split(factor_name, ":", simplify = FALSE)[[1]]
    
    # Use paste to create formula
    emm_formula <- as.formula(paste("~", paste(factors, collapse = "*")))
    
    # Compute EMMs
    emm_two_way <- emmeans(lm_mod, emm_formula)
    
    # Back-transform
    emm_two_way_back <- summary(emm_two_way, infer = TRUE) %>%
      as.data.frame() %>%
      mutate(
        emmean_orig = exp(emmean) - epsilon,
        lower.CL_orig = exp(lower.CL) - epsilon,
        upper.CL_orig = exp(upper.CL) - epsilon
      )
    
    # Round and select relevant columns
    emm_two_way_back_clean <- emm_two_way_back %>%
      mutate(
        emmean_orig = round(emmean_orig, 2),
        lower.CL_orig = round(lower.CL_orig, 2),
        upper.CL_orig = round(upper.CL_orig, 2)
      ) %>%
      select(all_of(factors), emmean_orig, lower.CL_orig, upper.CL_orig)
    
    # Report these as your EMM results
    print(emm_two_way_back_clean)
    
  } else if (str_count(sig_effects[effect], fixed(":")) == 2) {
    
    # Current significant effect
    factor_name <- sig_effects[effect]
    
    # Parse the factor name into a vector
    factors <- str_split(factor_name, ":", simplify = FALSE)[[1]]
    
    # Use paste to create formula
    emm_formula <- as.formula(paste("~", paste(factors, collapse = "*")))
    
    # Compute EMMs
    emm_three_way <- emmeans(lm_mod, emm_formula)
    
    # Back-transform
    emm_three_way_back <- summary(emm_three_way, infer = TRUE) %>%
      as.data.frame() %>%
      mutate(
        emmean_orig = exp(emmean) - epsilon,
        lower.CL_orig = exp(lower.CL) - epsilon,
        upper.CL_orig = exp(upper.CL) - epsilon
      )
    
    # Round and select relevant columns
    emm_three_way_back_clean <- emm_three_way_back %>%
      mutate(
        emmean_orig = round(emmean_orig, 2),
        lower.CL_orig = round(lower.CL_orig, 2),
        upper.CL_orig = round(upper.CL_orig, 2)
      ) %>%
      select(all_of(factors), emmean_orig, lower.CL_orig, upper.CL_orig)
    
    # Report these as your EMM results
    print(emm_three_way_back_clean)
  }
}

### VISUALIZATION

# The final stage in reporting RMAnova results is plotting. 
# The rule of thumb according to APA is this: If one or more main effect(s) 
# are part of a two or three way interaction, include them all in a single plot.  
# If a main effect is not a part of an interaction, plot it separately. 
# e.g. You have 4 significant effects: Repetition, Context, Interference and Repetition:Interference
# You need to plot 2 emms: Context and Repetition:Interference

interaction_effects <- sig_effects[str_detect(sig_effects, ":")]
main_effects <- sig_effects[!str_detect(sig_effects, ":")]

plots <- list()

### 1) Plot significant interactions (two-way)
if (length(interaction_effects) > 0) {
  
  for (effect in interaction_effects) {
    
    factors <- str_split(effect, ":", simplify = TRUE)
    
    emm_formula <- as.formula(paste("~", paste(factors, collapse = "*")))
    
    emm_int <- emmeans(lm_mod, emm_formula)
    
    emm_int_df <- summary(emm_int, infer = TRUE) %>%
      as.data.frame() %>%
      mutate(
        emmean_orig   = exp(emmean) - epsilon,
        lower.CL_orig = exp(lower.CL) - epsilon,
        upper.CL_orig = exp(upper.CL) - epsilon
      )
    
    p <- ggplot(
      emm_int_df,
      aes_string(
        x     = factors[1],
        y     = "emmean_orig",
        color = factors[2],
        group = factors[2]
      )
    ) +
      geom_point(size = 3) +
      geom_line(linewidth = 1) +
      geom_errorbar(
        aes(ymin = lower.CL_orig, ymax = upper.CL_orig),
        width = 0.15
      ) +
      labs(
        x = str_to_title(factors[1]),
        y = "Estimated Mean (original scale)",
        color = str_to_title(factors[2]),
        title = paste(str_to_title(factors[1]), "×", str_to_title(factors[2]))
      ) +
      theme_classic(base_size = 15)
    
    plots[[effect]] <- p
  }
}

### 2) Plot main effects ONLY if they are not part of an interaction
main_effects_to_plot <- main_effects[
  !main_effects %in% unlist(str_split(interaction_effects, ":"))
]

if (length(main_effects_to_plot) > 0) {
  
  for (factor_name in main_effects_to_plot) {
    
    emm_main <- emmeans(lm_mod, as.formula(paste("~", factor_name)))
    
    emm_main_df <- summary(emm_main, infer = TRUE) %>%
      as.data.frame() %>%
      mutate(
        emmean_orig   = exp(emmean) - epsilon,
        lower.CL_orig = exp(lower.CL) - epsilon,
        upper.CL_orig = exp(upper.CL) - epsilon
      )
    
    p <- ggplot(
      emm_main_df,
      aes_string(
        x = factor_name,
        y = "emmean_orig",
        group = 1
      )
    ) +
      geom_point(size = 3) +
      geom_line(linewidth = 1) +
      geom_errorbar(
        aes(ymin = lower.CL_orig, ymax = upper.CL_orig),
        width = 0.15
      ) +
      labs(
        x = str_to_title(factor_name),
        y = "Estimated Mean (original scale)",
        title = paste("Main Effect of", str_to_title(factor_name))
      ) +
      theme_classic(base_size = 15)
    
    plots[[factor_name]] <- p
  }
}

### 3) Print all plots
for (p in plots) print(p)


emm_ctx_by_rep <- emmeans(
  lm_mod,
  ~ context | repetition
)


simple_effects <- contrast(
  emm_ctx_by_rep,
  method = "pairwise",
  by = "repetition",
  adjust = "none"   # see note below
)


simple_effects_back <- summary(simple_effects, infer = TRUE) %>%
  as.data.frame() %>%
  mutate(
    estimate_orig   = exp(estimate) - epsilon,
    lower.CL_orig   = exp(lower.CL) - epsilon,
    upper.CL_orig   = exp(upper.CL) - epsilon
  )

simple_effects_clean <- simple_effects_back %>%
  mutate(
    estimate_orig = round(estimate_orig, 2),
    lower.CL_orig = round(lower.CL_orig, 2),
    upper.CL_orig = round(upper.CL_orig, 2),
    p.value = round(p.value, 4)
  ) %>%
  select(
    repetition,
    contrast,
    estimate_orig,
    lower.CL_orig,
    upper.CL_orig,
    p.value
  )

print(simple_effects_clean)



















