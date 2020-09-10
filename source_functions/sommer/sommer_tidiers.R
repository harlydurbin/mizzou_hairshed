
#### tidy extract BLUPs from sommer::mme output ----------------------

tidy_blup <- function(x, ...) {
  
  
  u <- 
    # This takes the first element of the list, which should be 
    # BLUP if it was specified first
    tibble::as_tibble(x$U[[1]][[1]]) %>%
    # Rename the column to blup
    rename(blup = 1)
  
  # Pull the label, remove the "u:" sommer appended
  col <- 
    rlang::sym(rlang::as_character(labels(x$U[1])) %>%
                 stringr::str_remove("u:"))
  
  labs <-
    tibble::tibble(!!col := labels(x$U[[1]][[1]]))
  
  bind_cols(labs, u)
}


#### tidy extract BLUP PEV and var/cov from sommer::mme output ----------------------

tidy_blup_var <- function(x, ...){
  
  
  # Returns a long version of the prediction error variance matrix +
  # variance-covariance matrix
  # for trait BLUPs 
  
  pevu <-
    as_tibble(x$PevU[[1]][[1]]) %>% 
    mutate(ind1 = colnames(.)) %>% 
    reshape2::melt(id = "ind1") %>% 
    rename(ind2 = variable, 
           pev_u = value) %>% 
    mutate(ind2 = as.character(ind2))
  
  
  varu <-
    as_tibble(x$VarU[[1]][[1]]) %>% 
    mutate(ind1 = colnames(.)) %>% 
    reshape2::melt(id = "ind1") %>% 
    rename(ind2 = variable, 
           var_u = value) %>% 
    mutate(ind2 = as.character(ind2))
  
  left_join(pevu, varu, by = c("ind1", "ind2"))
  
}