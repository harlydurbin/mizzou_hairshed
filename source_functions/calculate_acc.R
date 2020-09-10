# * Square se to get diagonal element ($d_i$)
# * $PEV = d_i\sigma^2_e$
#   * $r^2 = 1-(\frac{PEV}{\sigma^2_u})$
#     + Assuming $\sigma^2_u$ is $\sigma^2_a$?


calculate_acc <- function(e, u, se, option = "reliability") {
  PEV <- (se ^ 2) * e
  
  acc <- if (option == "reliability") {
    1 - (PEV / u)
  }
  
  acc <- if(option == "bif"){
    
    1 - sqrt(PEV / u)
    
  }
  
  return(acc)
}