Hsimu <- function(n){
  set.seed(1011)
  a <- diag(14)
  m <- diag(14)
  m[lower.tri(m, diag = F)] <- c(0.63, 0.48, 0.27, 0.33, 0.26, 0.28, 0.13, 0.18, 0.28, 0.40, 0.37, 0.42, 0.26,
                                 0.46, 0.28, 0.40, 0.28, 0.26, 0.10, 0.17, 0.24, 0.32, 0.28, 0.32, 0.20,
                                 0.24, 0.25, 0.29, 0.19, 0.02, 0.06, 0.18, 0.24, 0.21, 0.25, 0.27,
                                 0.38, 0.36, 0.18, 0.06, 0.11, 0.18, 0.16, 0.10, 0.16, 0.15,
                                 0.38, 0.29, 0.17, 0.19, 0.25, 0.26, 0.20, 0.27, 0.18,
                                 0.32, 0.14, 0.21, 0.33, 0.30, 0.20, 0.31, 0.23,
                                 0.43, 0.53, 0.67, 0.62, 0.45, 0.62, 0.38,
                                 0.59, 0.44, 0.38, 0.44, 0.39, 0.20,
                                 0.50, 0.47, 0.50, 0.47, 0.26,
                                 0.66, 0.48, 0.67, 0.37,
                                 0.62, 0.83, 0.37,
                                 0.66, 0.30,
                                 0.38)
  corre <- m + t(m) - a
  ## Mean and SD
  mu <- c(2.68, 2.72, 3.44, 2.75, 2.46, 2.67, 2.50, 2.36, 2.22, 2.25, 2.47, 2.67, 2.47, 5.63)
  sd <- c(0.98, 0.85, 0.79, 0.85, 0.91, 0.86, 0.85, 0.94, 1.01, 0.85, 0.93, 0.97, 0.96, 0.88)
  ## Covariance matrix
  cova <- sd %*% t(sd) * corre
  TIMSS_TW <- MASS::mvrnorm(n = n, mu = mu, Sigma = cova, empirical = T)
  TIMSS_TW <- data.frame(TIMSS_TW)
  names(TIMSS_TW) <- c("PTSR1", "PTSR2", "PTSR3",
                       "PPR1", "PPR2", "PPR3",
                       "SCS1", "SCS2", "SCS3", "SCS4",
                       "PATS1", "PATS2", "PATS3",
                       "PV1")
  return(TIMSS_TW)
}
