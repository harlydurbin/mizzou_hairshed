library(tidyverse)

blist <-  c(
  riptide     = "#84d6d3",
   bluesapphire= "#126180",
   baltic      = "#1a9a9d",
 #  placidblue  = "#8daed7",
   berry       = "#ee5863",
 #  tangerine   = "#ef8759",
 #  garanceyellow = "#fbed87",
   yellow      = "#fedb11",
 #  garden      = "#629d62",
 #  agategreen  = "#5da19a",
 #  prismpink   = "#efa5c8",
   magenta     = "#fb82b7",
 #  violet      = "#c6b7d5",
   marigold    = "#ff7436",
 #  orange      = "#f0a561",
 #  rose        = "#fdaba3",
 #  peach       = "#edbba8",
 #  garancemelon = "#f27168",
 #  garancepeach = "#f7d2b1",
 #  desertflower = "#ff9a90",
 #  tenderpeach = "#f8d6b8",
 #  livingcoral = "#fa7268",
 #  red         = "#e74a2f",
 #  maroon      = "#5f1f29",
   burgundy    = "#8e4866")


bakeoff <- 
  tibble(name = names(blist),
         hex = blist,
         value = 10) %>% 
  mutate(hex = as_factor(hex))

labs <- 
  c(str_c(as.character(bakeoff$name), ": ", as.character(bakeoff$hex)))

bakeoff %>% 
  ggplot(aes(x = forcats::fct_inorder(name, hex),
             y = value,
             fill = forcats::fct_inorder(name, hex))) +
  geom_bar(stat = "identity",
           position = "identity")  +
  scale_fill_manual(values = blist,
                    labels = labs
                    #label = str_c(name, ": ", hex)
  ) +
  theme(axis.text.x = element_blank(),
        axis.title.x = element_blank(),
        axis.text.y = element_blank(),
        axis.title.y = element_blank(),
        axis.ticks = element_blank()) +
  labs(fill = "Color")

ggsave(here::here("figures/bakeoff_reference_man.png"), dpi = 500)