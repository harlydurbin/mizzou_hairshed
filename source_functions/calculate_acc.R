# * Square se to get diagonal element ($d_i$)
# * $PEV = d_i\sigma^2_e$
#   * $r^2 = 1-(\frac{PEV}{\sigma^2_u})$

calculate_acc <- function(u, se, diagonal, option = "reliability") {
  PEV <- (se ^ 2)
  
  acc <- if (option == "reliability") {
    1 - (PEV / (diagonal*u))
  } else if(option == "bif"){
    
    1 - sqrt((PEV / (diagonal*u)))
    
  }
  
  return(acc)
}