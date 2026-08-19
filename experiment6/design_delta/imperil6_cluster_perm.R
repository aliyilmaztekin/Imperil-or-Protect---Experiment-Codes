
library(R.matlab)
options(scipen = 999)  # Avoids scientific notation
library(lme4)
library(lmerTest) 

# Load in condition data

cond1_dir <- '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/design_delta/allSamplesNovelCond1.mat'
cond2_dir <- '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/design_delta/allSamplesNovelCond2.mat'
cond3_dir <- '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/design_delta/allSamplesNovelCond3.mat'
cond4_dir <- '/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/design_delta/allSamplesNovelCond4.mat'

cond1matrix <- readMat(cond1_dir)$allCond1  
cond2matrix <- readMat(cond2_dir)$allCond2
cond3matrix <- readMat(cond3_dir)$allCond3
cond4matrix <- readMat(cond4_dir)$allCond4


library(lme4)
library(reshape2)

# Extract timepoint t=1 from all 4 conditions
t <- 1

slice1 <- cond1matrix[t, , ]  # 52 x 30
slice2 <- cond2matrix[t, , ]
slice3 <- cond3matrix[t, , ]
slice4 <- cond4matrix[t, , ]

# Melt each into long format and label condition
make_long <- function(mat, cond_label) {
  df <- melt(mat)
  colnames(df) <- c("trial", "participant", "value")
  df$condition <- cond_label
  return(df)
}

df_t <- rbind(
  make_long(slice1, "cond1"),
  make_long(slice2, "cond2"),
  make_long(slice3, "cond3"),
  make_long(slice4, "cond4")
)

df_t$condition <- as.factor(df_t$condition)
df_t$participant <- as.factor(df_t$participant)

df_t$trial <- as.factor(df_t$trial)

fit <- lmer(value ~ condition + (1 | participant), data = df_t)
summary(fit)

n_timepoints <- 60

# Store t-stats for each condition coefficient across time
t_stats <- matrix(NA, nrow = n_timepoints, ncol = 3)  # 3 contrasts vs cond1 baseline
colnames(t_stats) <- c("cond2", "cond3", "cond4")

for (t in 1:n_timepoints) {
  
  df_t <- rbind(
    make_long(cond1matrix[t, , ], "cond1"),
    make_long(cond2matrix[t, , ], "cond2"),
    make_long(cond3matrix[t, , ], "cond3"),
    make_long(cond4matrix[t, , ], "cond4")
  )
  df_t$condition  <- as.factor(df_t$condition)
  df_t$participant <- as.factor(df_t$participant)
  
  fit <- lmer(value ~ condition + (1 | participant), data = df_t)
  coefs <- summary(fit)$coefficients
  
  # Rows 2,3,4 are the condition contrasts (cond1 is baseline)
  t_stats[t, ] <- coefs[2:4, "t value"]
}

n_timepoints <- 60
t_stats <- matrix(NA, nrow = n_timepoints, ncol = 3)
colnames(t_stats) <- c("cond2", "cond3", "cond4")

for (t in 1:n_timepoints) {
  
  df_t <- rbind(
    make_long(cond1matrix[t, , ], "cond1"),
    make_long(cond2matrix[t, , ], "cond2"),
    make_long(cond3matrix[t, , ], "cond3"),
    make_long(cond4matrix[t, , ], "cond4")
  )
  df_t$condition   <- as.factor(df_t$condition)
  df_t$participant <- as.factor(df_t$participant)
  df_t$trial       <- as.factor(df_t$trial)
  
  fit <- lmer(value ~ condition + (1 | participant), data = df_t)
  coefs <- summary(fit)$coefficients
  t_stats[t, ] <- coefs[2:4, "t value"]
}

head(t_stats)
matplot(t_stats, type = "l", lty = 1, col = c("blue", "red", "green"),
        xlab = "Timepoint", ylab = "t-statistic",
        main = "Condition contrasts vs cond1 over time")
abline(h = 0, lty = 2)
legend("topright", colnames(t_stats), col = c("blue", "red", "green"), lty = 1)





library(parallel)
library(lme4)
library(dplyr)

n_perms <- 1000
threshold <- 2
n_cores <- detectCores() - 1  # leave one core free

cat("Using", n_cores, "cores\n")

# --- helper functions ---
make_long <- function(mat, cond_label) {
  df <- reshape2::melt(mat)
  colnames(df) <- c("trial", "participant", "value")
  df$condition <- cond_label
  return(df)
}

get_cluster_mass <- function(t_vec, threshold) {
  above <- abs(t_vec) > threshold
  if (!any(above)) return(0)
  clusters <- rle(above)
  masses <- c()
  pos <- 1
  for (i in seq_along(clusters$lengths)) {
    len <- clusters$lengths[i]
    if (clusters$values[i]) {
      masses <- c(masses, sum(t_vec[pos:(pos + len - 1)]))
    }
    pos <- pos + len
  }
  return(max(abs(masses)))
}

run_one_perm <- function(perm_id, cond1matrix, cond2matrix, cond3matrix, cond4matrix, threshold) {
  library(lme4)
  library(dplyr)
  
  perm_t <- matrix(NA, nrow = 60, ncol = 3)
  
  for (t in 1:60) {
    df_t <- rbind(
      make_long(cond1matrix[t, , ], "cond1"),
      make_long(cond2matrix[t, , ], "cond2"),
      make_long(cond3matrix[t, , ], "cond3"),
      make_long(cond4matrix[t, , ], "cond4")
    )
    df_t$condition   <- as.factor(df_t$condition)
    df_t$participant <- as.factor(df_t$participant)
    
    # Permute condition labels within each participant
    df_t <- df_t %>%
      group_by(participant) %>%
      mutate(condition = sample(condition)) %>%
      ungroup()
    
    fit <- tryCatch(
      lmer(value ~ condition + (1 | participant), data = df_t, 
           control = lmerControl(optimizer = "bobyqa")),
      error = function(e) NULL
    )
    
    if (!is.null(fit)) {
      coefs <- summary(fit)$coefficients
      perm_t[t, ] <- coefs[2:4, "t value"]
    }
  }
  
  apply(perm_t, 2, get_cluster_mass, threshold = threshold)
}

# --- observed t-stats (already computed) ---
obs_mass <- apply(t_stats, 2, get_cluster_mass, threshold = threshold)
cat("Observed cluster masses:\n")
print(obs_mass)

# --- parallel permutations ---
cl <- makeCluster(n_cores)

clusterExport(cl, varlist = c(
  "cond1matrix", "cond2matrix", "cond3matrix", "cond4matrix",
  "make_long", "get_cluster_mass", "threshold"
))

perm_results <- parLapply(
  cl,
  1:n_perms,
  run_one_perm,
  cond1matrix = cond1matrix,
  cond2matrix = cond2matrix,
  cond3matrix = cond3matrix,
  cond4matrix = cond4matrix,
  threshold = threshold
)

stopCluster(cl)

# --- collect results ---
perm_mass <- do.call(rbind, perm_results)
colnames(perm_mass) <- c("cond2", "cond3", "cond4")

# --- p-values ---
p_values <- colMeans(sweep(perm_mass, 2, obs_mass, FUN = ">"))
cat("\nCluster-based permutation p-values:\n")
print(p_values)



# Find which timepoints belong to significant clusters
find_clusters <- function(t_vec, threshold) {
  above <- abs(t_vec) > threshold
  clusters <- rle(above)
  pos <- 1
  result <- list()
  for (i in seq_along(clusters$lengths)) {
    len <- clusters$lengths[i]
    if (clusters$values[i]) {
      result[[length(result) + 1]] <- list(
        timepoints = pos:(pos + len - 1),
        mass = sum(t_vec[pos:(pos + len - 1)])
      )
    }
    pos <- pos + len
  }
  return(result)
}

find_clusters(t_stats[, "cond3"], threshold = 2)
find_clusters(t_stats[, "cond4"], threshold = 2)

















# Rerun t-stats with cond3 as reference
t_stats_34 <- matrix(NA, nrow = 60, ncol = 1)
colnames(t_stats_34) <- c("cond4_vs_cond3")

for (t in 1:60) {
  df_t <- rbind(
    make_long(cond3matrix[t, , ], "cond3"),
    make_long(cond4matrix[t, , ], "cond4")
  )
  df_t$condition   <- as.factor(df_t$condition)
  df_t$participant <- as.factor(df_t$participant)
  df_t$condition   <- relevel(df_t$condition, ref = "cond3")  # cond3 as baseline
  
  fit <- lmer(value ~ condition + (1 | participant), data = df_t,
              control = lmerControl(optimizer = "bobyqa"))
  coefs <- summary(fit)$coefficients
  t_stats_34[t, ] <- coefs[2, "t value"]
}

# Plot first to see what you're working with
plot(t_stats_34, type = "l", col = "purple",
     xlab = "Timepoint", ylab = "t-statistic",
     main = "cond4 vs cond3 over time")
abline(h = 0, lty = 2)
abline(h = c(-2, 2), lty = 3, col = "gray")
