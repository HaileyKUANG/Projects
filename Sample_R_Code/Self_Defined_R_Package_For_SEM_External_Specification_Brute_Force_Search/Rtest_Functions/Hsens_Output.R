Hsens_Output <- function(Output, Standardized_mp) {
  
  Packages <- c("tidyr", "dplyr", "tidyverse")
  for (BAO in Packages) {
    if (BAO %in% rownames(installed.packages()) == FALSE){
      install.packages(BAO)
    }
    if (BAO %in% (.packages()) == FALSE){
      library(BAO, character.only = TRUE)
    }
  }

  path_list <- names(Output)[1:(ncol(Output)-5)]
  path_list <- strsplit(path_list, split = '_', fixed = TRUE)
  path_list <- data.frame(unlist(path_list))
  path_list <- unique(path_list)
  path_list <- path_list[path_list != c("pvalue", "est.std")]
  
  Stfit1 <- data.frame(Standardized_mp)
  Stfit1 <- Stfit1[which(Stfit1$op == "~" ), ]
  Stfit1 <- unite(Stfit1, sname, lhs,op,rhs, sep = "")
  Stfit1 <- subset(Stfit1, select = -c(z, ci.lower, ci.upper, se))
  names(Stfit1) <- c("Path", "Estimate", "pvalue")
  
  Mytable1 <- data.frame(matrix(NA, ncol = 3))
  names(Mytable1) <- c("Path", "Lower Bound", "Upper Bound")
  
  Changes_list <- list() 
  
  i <- 1  
  v <- 1
  for (p in path_list) {
    
    pplist <- list()
    
    lst <- c(p, "simucor")
    Sub_Table <- Output[, grep(paste(lst, collapse="|"), colnames(Output))]
    
    Mytable1[i, 1:3] <- c(p, min(Sub_Table[1]), max(Sub_Table[1]))
    Mytable1[i, 1] <- gsub("\\.","~",Mytable1[i, 1])
    
    i <- i+1
    
    if (grepl(".Unmeasured", p)){
      next 
    } else{ 
      
      
      Sub_Table_n <- subset(Sub_Table, eval(parse(text = paste("Sub_Table","$", p,"_est.std", sep = ""))) < 0 & eval(parse(text = paste("Sub_Table","$", p,"_pvalue", sep = ""))) < 0.05)
      pplist[[1]] <- Sub_Table_n
      names(pplist)[1] <- paste0(p, "_effect_dir",  sep = "")
      
      Sub_Table_z <- subset(Sub_Table, eval(parse(text = paste("Sub_Table","$", p,"_est.std", sep = ""))) > -0.05 & eval(parse(text = paste("Sub_Table","$", p,"_est.std", sep = ""))) < 0.05)
      pplist[[2]] <- Sub_Table_z
      names(pplist)[2] <- paste0(p, "_effect_non",  sep = "")
      
      Sub_Table_p <- subset(Sub_Table, eval(parse(text = paste("Sub_Table","$", p,"_pvalue", sep = ""))) > 0.05)
      # range(Sub_Table_p$simucor_a)
      # range(Sub_Table_p$simucor_b)
      # range(Sub_Table_p$simucor_c)
      # range(Sub_Table_p$simucor_d)
      # range(Sub_Table_p$simucor_e)
      pplist[[3]] <- Sub_Table_p 
      names(pplist)[3] <- paste0(p, "_pvalue_change",  sep = "")
      Changes_list[[v]] <- pplist
      names(Changes_list)[v] <- p
      v <- v+1 
    }
    
  }
  Mytable2 <- merge(Mytable1, Stfit1, by = "Path", all.x = T)
  Mytable2 <- Mytable2[order(Mytable2$Estimate),]
  Changes_list[[v]] <- Mytable2
  names(Changes_list)[v] <- "Path Summary"

  return(Changes_list)
}
