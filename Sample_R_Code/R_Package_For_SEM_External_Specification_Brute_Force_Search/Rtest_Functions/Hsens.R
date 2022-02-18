Hsens <- function(mydata, mymodel){

  Packages <- c("lavaan", "tidyr", "dplyr", "tidyverse", "svMisc")
  for (BAO in Packages) {
    if (BAO %in% rownames(installed.packages()) == FALSE){
      install.packages(BAO)
    }
    if (BAO %in% (.packages()) == FALSE){
      suppressPackageStartupMessages(library(BAO, character.only = TRUE))
    }
  }

  Hmulti_spread <- function(data, key, value) {
    hkey <- rlang::enquo(key)
    hvalue <- rlang::enquo(value)
    s <- rlang::quos(!!hvalue)
    data %>% gather(variable, value, !!!s) %>%
      unite(temp, !!hkey, variable) %>%
      spread(temp, value)
  }

  ## Correlation matrix
  svcov <- inspect(mymodel, what="cor.all")
  svcov <- as.matrix(round(svcov, 5))
  ## Correlation among latent variables
  latentcov <- svcov[(ncol(mydata)+1):ncol(svcov), (ncol(mydata)+1):ncol(svcov)]
  ## Correlation among observed variables
  observoc <- svcov[1:ncol(mydata), 1:ncol(mydata)]

  ## Record Computational time
  start_time <- Sys.time()

  ## Define default values
  interval <- 0.5
  inf_1 <- NULL
  models_sen <- NULL


  for (a in seq(0, 1, by = interval)) {
    for (b in seq(0, 1, by = interval)) {
      for (c in seq(0, 1, by = interval)) {
        for (d in seq(0, 1, by = interval)) {
          for (e in seq(0, 1, by = interval)) {

            ## Create a vector represents the correlation between U and the exist variables
            v1 <- matrix( c(a, a, a, b, b, b, c, c, c, c, d, d, d, e),
                          nrow = ncol(mydata),
                          byrow = TRUE)
            v2 <- rbind(v1, 1) # v2 add variance (sigma^2 =1) of the nmeasured confounder variable

            ## Combine the correlation vector with the implied correlation matrix (positive define)
            cor_with_u_1 <- cbind(observoc, v1)
            cor_with_u <- rbind(cor_with_u_1,t(v2))

            new_cor <- as.matrix(cor_with_u)
            colnames(new_cor)[ncol(new_cor)] <- c("Unmeasured")
            rownames(new_cor) <- colnames(new_cor)

            ## Build Model with U
            Umodel <- 'PTSR =~ PTSR1 + PTSR2 + PTSR3
                       PPR =~ PPR1 + PPR2 + PPR3
                       SCS =~ SCS1 + SCS2 + SCS3 + SCS4
                       PATS =~ PATS1 + PATS2 + PATS3

                       PV1 ~ SCS + PATS
                       SCS ~ PTSR + PPR
                       PATS ~ PTSR + PPR


                       PTSR ~ Unmeasured
                       PPR ~ Unmeasured
                       SCS ~ Unmeasured
                       PATS ~ Unmeasured
                       PV1 ~ Unmeasured

                       SCS ~~ PATS'

            ## Fit the (Ufit/UModel) model with correlation matrix
            options(warn = 2)
            Ufit <- try(sem(model = Umodel,
                            sample.cov = new_cor,
                            sample.nobs = nrow(mydata)),
                        silent = TRUE)

            options(warn = 1)
            if(class(Ufit) == "try-error"){next}

            ## Add Ufit elements to a models_sen vector
            #models_sen <- append(models_sen, Ufit)

            ## Record Standardized parameters
            s <- as.data.frame(standardizedSolution(Ufit))

            ## Keep the 10 regression coefficient
            s1 <- s[which(s$op == "~" ), ]
            s1 <- unite(s1, sname, lhs,op,rhs, sep = "")

            ## Only keep three colunms: sname, estimated regression coefficient and p_value
            s1 <- subset(s1, select = -c(z, ci.lower, ci.upper, se) )

            ## Move multiple rows into one row
            s2 <- s1 %>%
              group_by(sname) %>%
              Hmulti_spread(sname, c(est.std, pvalue))

            ## Recode the assigned correlation
            cor_u <- as.data.frame(matrix(c(a, b, c, d, e), nrow = 1))
            names(cor_u) <- c("simucor_a", "simucor_b", "simucor_c", "simucor_d", "simucor_e")

            s2 <- as.data.frame(s2)
            s2 <- cbind(s2, cor_u)

            #Create the final table
            inf_1 <- rbind(inf_1, s2)

          }
        }
      }
    }
  }



  # for (i in 0:(1/interval)^5) {
  #   progress(i, max.value = (1/interval)^5, progress.bar = TRUE)
  #   Sys.sleep(0.01)
  #   if (i == (1/interval)^5) {
  #     cat("Done!\n")
  #   }
  # }

  ## Record Computational time
  end_time <- Sys.time()
  consumed_time <- end_time - start_time
  print(consumed_time)

  ## Return result
  inf_1 <- as.matrix(round(inf_1, 5))
  inf_1 <- data.frame(inf_1)
  return(inf_1)
}
