# Libraries
library(R.matlab)
library(dplyr)
library(tidyr)
library(ez)
library(ggplot2)
library(moments)
library(emmeans)
library(rlang)
options(scipen = 999)  # Avoid scientific notation


# Load MAT files

files <- c(
  "imperil4dataID13.mat",
  "imperil4dataID14.mat",
  "imperil4dataID15.mat",
  "imperil4dataID16.mat",
  "imperil4dataID17.mat",
  "imperil4dataID18.mat",
  "imperil4dataID19.mat",
  "imperil4dataID20.mat",
  "imperil4dataID21.mat",
  "imperil4dataID22.mat",
  "imperil4dataID23.mat",
  "imperil4dataID24.mat",
  "imperil4dataID25.mat",
  "imperil4dataID26.mat",
  "imperil4dataID27.mat"
)

base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/pilot_data_2/"

dfs <- lapply(files, function(f) {
  mat <- readMat(file.path(base_dir, f))
  df <- as.data.frame(mat$outputMatrix)
  df
})

# Combine all participants
combine <- bind_rows(dfs)

# Assign column names
colnames(combine) <- c(
  "subject", "conditionUsed", "block", "trial", "repetition",
  "context", "contextCode", "primaryColor", "secondaryColor",
  "angle1", "initiation_time1", "movement_time1", "rt1",
  "angle2", "initiation_time2", "movement_time2", "rt2",
  "breakTaken", "conditions"
)

# Column reference

# 10th: angle1
# 11th: initiation_time1
# 12th: movement_time1
# 13th: rt1
# 14th: angle2
# 15th: initiation_time2
# 16th: movement_time2
# 17th: rt2

# Preprocessing

# Enter the DV to analyze:
dv_col <- "angle1"


# Enter epsilon value for the log-transformation
epsilon <- 1

# Filter out missed tests, perform log conversion, code IVs into factors
combine_filtered <- combine %>%
  filter(!is.na(!!sym(dv_col)) & !is.nan(!!sym(dv_col))) %>%
  mutate(
    DV = log(abs(!!sym(dv_col)) + epsilon),
    repetition = factor(repetition),
    context = factor(context)
  )

skewness(combine_filtered$DV)

# Outlier rejection
combine_rejected <- combine_filtered %>%
  group_by(subject, context) %>%
  mutate(
    mean_DV = mean(DV, na.rm = TRUE),
    sd_DV = sd(DV, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(
    DV >= (mean_DV - 2.5 * sd_DV) &
      DV <= (mean_DV + 2.5 * sd_DV)
  ) %>%
  select(-mean_DV, -sd_DV)


# Reduce to critical trials
combine_final <- combine_rejected %>%
  filter(
    repetition %in% c(1, 5),
    context %in% c(0, 1)
  )
  
# Perform trial-level RMAnova
anova_table <- ezANOVA(
  data = combine_final,
  dv = .(DV),
  wid = .(subject),
  within = .(repetition, context),
  type = 3,
  detailed = TRUE
)

# Make the output more readable
anova_clean <- anova_table$ANOVA %>%
  mutate(across(where(is.numeric), ~ round(.x, 3))) 

print(anova_clean)

# Get SEM for plotting
summary_data <- combine_final %>%
  group_by(subject, repetition, context) %>%
  summarise(subject_mean = mean(DV, na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(repetition, context) %>%
  summarise(
    mean_DV = mean(subject_mean),
    sd_DV = sd(subject_mean),
    n = n(),  # number of subjects
    sem = sd_DV / sqrt(n)
  ) %>%
  ungroup()

# Plot the results
ggplot(summary_data, aes(x = repetition, y = mean_DV, group = context, color = factor(context))) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean_DV - sem, ymax = mean_DV + sem), width = 0.2) +
  scale_x_discrete(labels = c("1st", "5th")) +
  labs(
    x = "Repetition",
    y = "Log(abs(DV) + ε)",
    color = "Context",
    title = "DV by Repetition and Context"
  ) +
  theme_minimal(base_size = 14)



