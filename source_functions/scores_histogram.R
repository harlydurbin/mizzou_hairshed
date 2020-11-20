library(readr)
library(tidyr)
library(dplyr)
library(ggplot2)
library(patchwork)

years_hist <-
  cleaned %>% 
  arrange(year) %>% 
  mutate(year = forcats::fct_inorder(as.factor(year))) %>% 
  ggplot(aes(x = year)) +
  geom_histogram(stat = "count") +
  theme_classic() +
  scale_y_continuous(labels = scales::comma) +
  theme(axis.text.y = element_text(size = 22),
        axis.text.x = element_text(size = 22,
                                   angle = 35,
                                   hjust = 1),
        axis.title.y = element_text(size = 24,
                                    margin = margin(r = 15)),
        axis.title.x = element_text(size = 24,
                                    margin = margin(t = 15)),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) +
  labs(y = "Number of scores",
       x = "Year")

scores_hist <-
  cleaned %>% 
  group_by(farm_id, temp_id) %>% 
  mutate(bin = case_when(n() == 1 ~ "1",
                         n() == 2 ~ "2",
                         n() == 3 ~ "3",
                         n() == 4 ~ "4",
                         n() == 5 ~ "5",
                         between(dplyr::n(), 6, 10) ~ "6-10",
                         between(dplyr::n(), 11, 20) ~ "11-20",
                         TRUE~ "21+")) %>%
  ungroup() %>%
  distinct(farm_id, temp_id, bin) %>% 
  mutate(bin = forcats::as_factor(bin),
         bin = forcats::fct_relevel(bin, c("1", "2", "3", "4", "5", "6-10", "11-20", "21+"))) %>% 
  ggplot(aes(x = bin)) +
  geom_histogram(stat = "count") +
  theme_classic() +
  scale_y_continuous(labels = scales::comma) +
  theme(axis.text.y = element_text(size = 22),
        axis.text.x = element_text(size = 22,
                                   angle = 35,
                                   hjust = 1),
        axis.title.y = element_text(size = 24,
                                    margin = margin(r = 15)),
        axis.title.x = element_text(size = 24,
                                    margin = margin(t = 15)),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank()) +
  labs(y = "Number of animals",
       x = "Number of scores")

years_hist/scores_hist + plot_annotation(tag_levels = c("a")) & 
  theme(plot.tag = element_text(size = 26,
                                margin = margin(r = 15)),
        plot.margin = margin(t = 0, b = 0, l = 1, r = 1))


ggsave(here::here("figures/data_summary/score_numbers.png"), width = 10, height = 8)