

cg_tallies <-
  function(df) {
    sum <-
      df %>%
      group_by(cg_num) %>%
      mutate(
        bin =
          case_when(
            n() == 1 ~ "1",
            n() == 2 ~ "2",
            n() == 3 ~ "3",
            n() == 4 ~ "4",
            between(n(), 5, 10) ~ "5-10",
            between(n(), 11, 20) ~ "11-20",
            between(n(), 21, 50) ~ "21-50",
            between(n(), 51, 100) ~ "51-100",
            n() > 100 ~ "101+"
          )
      ) %>%
      ungroup() %>%
      mutate(bin = forcats::as_factor(bin),
             bin = forcats::fct_relevel(
               bin,
               c("1", "2", "3", "4", "5-10", "11-20", "21-50", "51-100", "101+")
             )) %>%
      group_by(bin) %>%
      summarise(n_CGs = n_distinct(cg_num),
                n_animals = n()) %>%
      ungroup() %>%
      arrange(bin)
    
    kept <-
      sum %>%
      filter(!bin %in% c("1", "2", "3", "4")) %>%
      summarise(n_CGs = sum(n_CGs),
                n_animals = sum(n_animals)) %>%
      mutate(bin = forcats::as_factor("Kept"))      
    
    dropped <-
      sum %>%
      filter(bin %in% c("1", "2", "3", "4")) %>%
      summarise(n_CGs = sum(n_CGs),
                n_animals = sum(n_animals)) %>%
      mutate(bin = forcats::as_factor("Dropped"))
    
    bind_rows(sum, kept, dropped) %>% 
      rename(
        Bin = bin,
        `n CGs` = n_CGs,
        `n animals` = n_animals
      )
  }