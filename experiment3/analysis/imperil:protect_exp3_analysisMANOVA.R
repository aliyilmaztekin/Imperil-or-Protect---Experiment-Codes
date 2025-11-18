library(car)
options(scipen = 999)  # Avoid scientific notation
# Load data
data <- read.csv("/Users/ali/Desktop/wideData.csv")

# Prepare DV matrix (columns 2–25)
dv_matrix <- as.matrix(data[, 2:25])

# Extract factor levels from column names
col_names <- colnames(data)[2:25]

# Split each name by "_"
split_names <- strsplit(col_names, "_")

# Extract repetition, context, interference
Repetition <- factor(sapply(split_names, function(x) x[3]), levels = c("1","5"))
ContextChange <- factor(sapply(split_names, function(x) x[4]), levels = c("0","1"))
Interference <- factor(sapply(split_names, function(x) x[5]), levels = c("0","1"))

# Combine into within-subject factor table
within_factors <- data.frame(Repetition, ContextChange, Interference)

# Fit MANOVA
library(car)
rm_model <- lm(dv_matrix ~ 1)
rm_manova <- Anova(rm_model,
                   idata = within_factors,
                   idesign = ~Repetition*ContextChange*Interference,
                   type = "III",
                   multivariate = TRUE)

# View results
summary(rm_manova, multivariate = TRUE)

library(dplyr)

# Get the summary of univariate ANOVA
uni_res <- summary(rm_manova, multivariate = FALSE)

# Get univariate ANOVA results from the rm_manova object
uni_table <- summary(rm_manova, multivariate = TRUE)$univariate.tests

# Inspect the table
head(uni_table)


# Add a column for Factor names
uni_table$Factor <- rownames(uni_table)

# Reorder columns
uni_table <- uni_table[, c("Factor", "Df", "F value", "Pr(>F)")]

# View the table
uni_table
