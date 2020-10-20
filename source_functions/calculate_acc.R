# * Square se to get diagonal element ($d_i$)
# * $PEV = d_i\sigma^2_e$
#   * $r^2 = 1-(\frac{PEV}{\sigma^2_u})$

calculate_acc <- function(u, se, f, option = "reliability") {
  PEV <- (se ^ 2)
  
  acc <- if (option == "reliability") {
    1 - (PEV / ((1+f)/u))
  } else if(option == "bif"){
    
    1 - sqrt(PEV / ((1+f)/u))
    
  }
  
  return(acc)
}