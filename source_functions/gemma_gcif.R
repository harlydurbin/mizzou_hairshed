

gcif <- 
  function(df, adjust_p = FALSE){
    gci <- median(qchisq(df$p_wald, 1, lower.tail=FALSE))/qchisq(0.5, 1)
    
    if(adjust_p == TRUE){
      new_p <- pchisq(qchisq(df$p_wald, 1, lower.tail=FALSE)/gci, df = 1, lower.tail = FALSE)
      return(new_p)
    } else {
      return(gci)
    }
  }