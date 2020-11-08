library(readr)
library(magrittr)
library(purrr)
library(dplyr)
library(stringr)
library(glue)
library(ggplot2)
library(magrittr)

source(here::here("source_functions/iterative_id_search.R"))

breed_key <- read_rds(here::here("data/derived_data/breed_key/breed_key.rds"))

cleaned <- read_rds(here::here("data/derived_data/import_join_clean/cleaned.rds"))

sim_breed <-
  read_csv(here::here("data/raw_data/201005.SIM.breeds.csv")) %>% 
  select(registration_number = asa_nbr, brd = breed_code, pct) %>% 
  mutate(cross = if_else(pct == 1, brd, "CROS")) %>% 
  tidyr::pivot_wider(id_cols = c("registration_number", cross),
                     names_from = brd,
                     values_from = pct) %>% 
  mutate_at(vars(SM:SH), ~ replace_na(., 0)) %>% 
  janitor::clean_names() %>% 
  # Don't differentiate between horned and polled Hereford
  mutate(hfd = hh + hp,
         # Don't differentiate between purebred and commercial 
         sim = sm + cs) %>% 
  select(registration_number, cross, an, ar, br, chi = ca, gv, hfd, sim) %>% 
  # Don't differentiate between Red Angus and Angus since RAAA doesn't
  mutate(ar = case_when(ar != 0 & an != 0 & br == 0 & chi == 0 & gv == 0 & hfd == 0 & sim == 0 ~ ar + an,
                        TRUE ~ ar),
         ar = if_else(ar > 1, 1, ar),
         cross = case_when(ar == 1 ~ "AR",
                           (ar + an) == 1 ~ "AR",
                           sim == 1 ~ "SIM",
                           an == 1 ~ "AN",
                           TRUE ~ cross),
         brd_source = glue("ASA{row_number()}"),
         cross = case_when(an >= 0.625 ~ "AN",
                           sim >= 0.625 ~ "SIM",
                           ar >= 0.625 ~ "RAN",
                           gv >= 0.625 ~ "GEL",
                           hfd >= 0.625 ~ "HFD",
                           TRUE ~ "Crossbred or other"),
         registration_number = as.character(glue("SIM{registration_number}")))

bvs <- 
  read_table2(here::here("data/derived_data/aireml_varcomp/fixed9/solutions"),
              skip = 1,
              col_names = c("trait", "effect", "id_renamed", "solution", "se")) %>% 
  filter(effect == 2) %>% 
  left_join(read_table2(here::here("data/derived_data/aireml_varcomp/fixed9/renadd02.ped"),
                        col_names = FALSE) %>% 
              select(id_renamed = X1, full_reg = X10)) %>% 
  select(-trait, -effect, -id_renamed)

bvs %<>% 
  left_join(breed_key %>% 
              select(-breed_code)) %>% 
  left_join(cleaned %>% 
              distinct(farm_id, animal_id, temp_id, breed_code)) %>% 
  id_search(source_col = full_reg,
            search_df = sim_breed,
            search_col = registration_number,
            key_col = cross) %>% 
  mutate(map_breed = case_when(cross == "AN" ~ "Angus",
                               str_detect(full_reg, "BIR|AAA|AAN") ~ "Angus",
                               an >= 0.625 ~ "Angus",
                               cross == "HFD" ~ "Hereford",
                               str_detect(full_reg, "HER") ~ "Hereford",
                               hfd >= 0.625 ~ "Hereford",
                               cross == "BGR" ~ "Brangus",
                               str_detect(full_reg, "BGR") ~ "Brangus",
                               cross == "RAN" ~ "Red Angus",
                               cross == "CHA" ~ "Charolais",
                               str_detect(full_reg, "CHA") ~ "Charolais",
                               cross == "SH" ~ "Shorthorn",
                               str_detect(full_reg, "BSH") ~ "Shorthorn",
                               cross == "RDP" ~ "Maine-Anjou",
                               str_detect(full_reg, "RDP") ~ "Maine-Anjou",
                               cross == "GEL" ~ "Gelbvieh",
                               gv >= 0.625 ~ "Gelbvieh", 
                               str_detect(full_reg, "^GVH") ~ "Gelbvieh",
                               source == "American Gelbvieh Association" ~ "Gelbvieh",
                               cross == "RAN" ~ "Red Angus",
                               ar >= 0.625 ~ "Red Angus",
                               str_detect(full_reg, "^RAN") ~ "Red Angus",
                               source == "Red Angus Association of America" ~ "Red Angus",
                               cross == "SIM" ~ "Simmental",
                               sim >= 0.625 ~ "Simmental",
                               TRUE ~ "Crossbred or other"))

breeds_boxswarm <-
  bvs %>% 
  ggplot(aes(x = forcats::fct_reorder(map_breed, solution, median),
             y = solution)) +
  ggforce::geom_sina(aes(color = map_breed),
                     alpha = 0.3,
                     kernel = "rectangular") +
  geom_boxplot(aes(fill = map_breed),
               alpha = 0.4,
               show.legend = FALSE) +
  scale_color_manual(values = c("Crossbred or other" = "#a2ceaa",
                                "Angus" = "#4f6980",
                                "Hereford" = "#f47942",
                                "Red Angus" = "#fbb04e",
                                "Simmental" = "#638b66",
                                "Brangus" = "#bfbb60",
                                "Gelbvieh"= "#d7ce9f",
                                "Charolais"= "#849db1",
                                "Shorthorn"= "#b9aa97",
                                "Maine-Anjou"= "#7e756d")) +
  scale_fill_manual(values = c("Crossbred or other" = "#a2ceaa",
                               "Angus" = "#4f6980",
                               "Hereford" = "#f47942",
                               "Red Angus" = "#fbb04e",
                               "Simmental" = "#638b66",
                               "Brangus" = "#bfbb60",
                               "Gelbvieh"= "#d7ce9f",
                               "Charolais"= "#849db1",
                               "Shorthorn"= "#b9aa97",
                               "Maine-Anjou"= "#7e756d")) +
  guides(colour = FALSE,
         fill = FALSE) +
  theme_classic() +
  theme(axis.text.y = element_text(size = 24),
        axis.text.x = element_text(size = 24,
                                   angle = 35,
                                   hjust = 1),
        legend.text = element_text(size = 22),
        legend.title = element_text(size = 24),
        axis.title.y = element_text(size = 28,
                                    margin = margin(r = 15)),
        axis.title.x = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) +
  labs(y = "EBV")


ggsave(here::here("figures/breeds/fixed9.breeds_boxswarm.png"),
       plot = breeds_boxswarm, 
       width = 12,
       height = 8)