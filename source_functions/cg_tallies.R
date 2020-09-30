

cg_tallies <-
  function(df) {
    sum <-
      df %>%
      dplyr::group_by(cg_num) %>%
      dplyr::mutate(
        bin =
          dplyr::case_when(
            dplyr::n() == 1 ~ "1",
            dplyr::n() == 2 ~ "2",
            dplyr::n() == 3 ~ "3",
            dplyr::n() == 4 ~ "4",
            dplyr::between(dplyr::n(), 5, 10) ~ "5-10",
            dplyr::between(dplyr::n(), 11, 20) ~ "11-20",
            dplyr::between(dplyr::n(), 21, 50) ~ "21-50",
            dplyr::between(dplyr::n(), 51, 100) ~ "51-100",
            dplyr::n() > 100 ~ "101+"
          )
      ) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(bin = forcats::as_factor(bin),
             bin = forcats::fct_relevel(bin,
                                        c("1", "2", "3", "4", "5-10", "11-20", "21-50", "51-100", "101+"))) %>%
      dplyr::group_by(bin) %>%
      dplyr::summarise(n_CGs = dplyr::n_distinct(cg_num),
                n_animals = dplyr::n()) %>%
      dplyr::ungroup() %>%
      dplyr::arrange(bin)
    
    kept <-
      sum %>%
      dplyr::filter(!bin %in% c("1", "2", "3", "4")) %>%
      dplyr::summarise(n_CGs = sum(n_CGs),
                       n_animals = sum(n_animals)) %>%
      dplyr::mutate(bin = forcats::as_factor("Kept"))      
    
    dropped <-
      sum %>%
      dplyr::filter(bin %in% c("1", "2", "3", "4")) %>%
      dplyr::summarise(n_CGs = sum(n_CGs),
                       n_animals = sum(n_animals)) %>%
      dplyr::mutate(bin = forcats::as_factor("Dropped"))
    
    dplyr::bind_rows(sum, kept, dropped) %>% 
      dplyr::rename(
        Bin = bin,
        `n CGs` = n_CGs,
        `n animals` = n_animals
      )
  }