Hsearchresult <- function(searchlist, a, b, c, d, e, val){

  Hsearch <- function(searchlist, var, val){
    uplist <- list()
    t <- 1
    for (mycor in searchlist) {

      if(var == "a"){
        myloc <- 3
      } else if (var == "b"){
        myloc <- 4
      } else if (var == "c"){
        myloc <- 5
      } else if (var == "d"){
        myloc <- 6
      } else if (var == "e"){
        myloc <- 7
      }
      updata <- subset(mycor, mycor[, myloc] == val)
      uplist[[t]] <- updata
      t <- t + 1
    }
    names(uplist) <- paste0(names(Result) ,"_", rep(c("pvalue_change", "effect_dir", "effect_non"), 6), sep = "")
    return(uplist)
  }


  if (!is.null(a)){
    searchlist <- Hsearch(searchlist, "a", a)
  }

  if (!is.null(b)){
    searchlist <- Hsearch(searchlist, "b", b)
  }

  if (!is.null(c)){
    searchlist <- Hsearch(searchlist, "c", c)
  }

  if (!is.null(d)){
    searchlist <- Hsearch(searchlist, "d", d)
  }

  if (!is.null(e)){
    searchlist <- Hsearch(searchlist, "e", e)
  }

  return(searchlist)

}

