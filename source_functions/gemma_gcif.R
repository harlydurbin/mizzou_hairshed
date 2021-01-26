

gcif <- 
  function(df, p_col = p_wald, adjust_p = FALSE){
    
    p_col <- rlang::enquo(p_col)
    
    df <- 
      df %>% 
      rename(p = !!p_col)
    
    gci <- median(qchisq(df$p, 1, lower.tail=FALSE))/qchisq(0.5, 1)
    
    if(adjust_p == TRUE){
      new_p <- pchisq(qchisq(df$p, 1, lower.tail=FALSE)/gci, df = 1, lower.tail = FALSE)
      return(new_p)
    } else {
      return(gci)
    }
  }