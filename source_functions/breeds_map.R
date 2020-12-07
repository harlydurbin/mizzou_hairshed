library(readr)
library(tidyr)
library(dplyr)
library(ggplot2)
library(stringr)
library(extrafont)

usa <- 
  borders("state", regions = ".", fill = "white", colour = "black")

coord_key <- read_csv(here::here("data/derived_data/environmental_data/coord_key.csv"))

breed_key <- read_rds(here::here("data/derived_data/breed_key/breed_key.rds"))

cleaned <- read_rds(here::here("data/derived_data/import_join_clean/cleaned.rds"))

map_dat <-
  breed_key %>% 
  select(-breed_code) %>% 
  left_join(cleaned) %>% 
  mutate(map_breed = case_when(cross == "AN" ~ "Angus",
                               an >= 0.625 ~ "Angus",
                               cross == "HFD" ~ "Hereford",
                               hfd >= 0.625 ~ "Hereford",
                               cross == "BGR" ~ "Brangus",
                               cross == "RAN" ~ "Red Angus",
                               cross == "CHA" ~ "Charolais",
                               cross == "SH" ~ "Shorthorn",
                               cross == "RDP" ~ "Maine-Anjou",
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
                               TRUE ~ "Crossbred or other"),
         map_color = case_when(map_breed == "Crossbred or other" ~ "#a2ceaa",
                               map_breed == "Angus" ~ "#4f6980",
                               map_breed == "Hereford" ~ "#f47942",
                               map_breed == "Red Angus" ~ "#fbb04e",
                               map_breed == "Simmental" ~ "#638b66",
                               map_breed == "Brangus" ~ "#bfbb60",
                               map_breed == "Gelbvieh"~ "#d7ce9f",
                               map_breed == "Charolais"~ "#849db1",
                               map_breed == "Shorthorn"~ "#b9aa97",
                               map_breed == "Maine-Anjou"~ "#7e756d"),
         map_breed = case_when(map_breed == "Crossbred or other" ~ "Crossbred or other: 14,986",
                               map_breed == "Angus" ~ "Angus: 10,222",
                               map_breed == "Hereford" ~ "Hereford: 2,993",
                               map_breed == "Red Angus" ~ "Red Angus: 2,316",
                               map_breed == "Simmental" ~ "Simmental: 2,288",
                               map_breed == "Brangus" ~ "Brangus: 1,918",
                               map_breed == "Gelbvieh" ~ "Gelbvieh: 748",
                               map_breed == "Charolais" ~ "Charolais: 676",
                               map_breed == "Shorthorn" ~ "Shorthorn: 489",
                               map_breed == "Maine-Anjou" ~ "Maine-Anjou: 263",
                               TRUE ~ map_breed),
         map_breed = forcats::fct_infreq(map_breed)) %>% 
  left_join(coord_key %>% 
              select(farm_id, lat, long)) %>% 
  group_by(map_breed, lat, long, map_color) %>%
  summarise(n = n()) %>% 
  ungroup()

ggplot() +
  usa +
  geom_point(data = map_dat,
             aes(x = long,
                 y = lat,
                 color = map_breed,
                 size = n),
             alpha = 0.85,
             position = position_jitter(width = 0.4,
                                        height = 0.2)) +
  scale_color_manual(values = c("Crossbred or other: 14,986" = "#a2ceaa",
                                "Angus: 10,222" = "#4f6980",
                                "Hereford: 2,993" = "#f47942",
                                "Red Angus: 2,316" = "#fbb04e",
                                "Simmental: 2,288" = "#638b66",
                                "Brangus: 1,918" = "#bfbb60",
                                "Gelbvieh: 748" = "#d7ce9f",
                                "Charolais: 676" = "#849db1",
                                "Shorthorn: 489" = "#b9aa97",
                                "Maine-Anjou: 263" = "#7e756d")) +
  guides(color = guide_legend(title = NULL),
         # Turn off size guide
         size = FALSE) + 
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  coord_map("albers",
            lat0 = 39,
            lat1 = 45) +
  cowplot::theme_map() +
  guides(color = guide_legend(override.aes = list(size = 1.5,
                                                  alpha = 1),
                              nrow = 4)) +
  labs(x = NULL,
       y = NULL,
       title = NULL) +
  theme(text = element_text(family = "Glacial Indifference"),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.box = "vertical",
        legend.spacing.y = unit(.1, 'cm'),
        legend.title = element_blank(),
        legend.text = element_text(size = 10),
        # top, right, bottom, left
        legend.box.margin = margin(b = 0.1,
                                   l = 0.1,
                                   r = 0.1,
                                   unit = "in"),
        plot.margin = margin(t = 0.175,
                             r = 0,
                             b = 0,
                             l = 0,
                             unit = "mm"))

ggsave(here::here("figures/data_summary/breed_map_transparent.png"),
       width = 7,
       height = 4,
       bg = "transparent")