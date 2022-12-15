### A script for calculating the Principal Coordinate Analysis and creating a visualization from pig-data
##  Code for producing figure 5 in the manuscript

## Libraries ------------

library(vegan)
library(tidyverse)
library(janitor)
library(readxl)
library(glue)
library(viridis)
library(here)

theme_set(theme_bw(base_size = 16))

## Data loading --------
here::i_am(path = "R/Figure5.R")

data_path <- here("data/")
data_files <- list.files(path = data_path)


## read data to data.frames
biom_nonfil_df <- read_csv(file = here(data_path, data_files[1]))
metadata_df <- readxl::read_xlsx(path = here(data_path, data_files[2]), sheet = 1)
secuencias_tree_df <- read_csv(file = here(data_path, data_files[3]))
tax_table_nonfil_df <- read_csv(file = here(data_path, data_files[4]))

# add a name to un-named first columns
names(biom_nonfil_df)[1] <- names(secuencias_tree_df)[1] <- names(tax_table_nonfil_df)[1] <- "code"

#########
## Principal Coordinate analysis ------------
#########

# calculating Bray-Curtis distances
biom_dist <- 
  biom_nonfil_df %>% 
  # removing "non-pig" data
  select(-code, -`CN_MCC21-111_S106`) %>% 
  # transpose the data
  t() %>% 
  vegdist()

# first two axes in PCoA
PCoA_res <- cmdscale(biom_dist, eig = TRUE, add = TRUE)
positions <- PCoA_res$points


colnames(positions) <- c("PCoA1", "PCoA2")
positions <- positions %>% 
  as_tibble(rownames = "sample_id") %>% 
  left_join(y = metadata_df %>% 
              select(SAMPLE_ID, MANIPULATOR, `PAIR NO.`) %>% 
              rename(sample_id = SAMPLE_ID, manipulator = MANIPULATOR, pair = `PAIR NO.`),
            by = "sample_id") %>% 
  mutate(manipulator = if_else(manipulator == 1, true = "Manipulator", false = "Control") %>% as_factor())

#calculate percent explained
percents <- 100*PCoA_res$eig / sum(PCoA_res$eig)
percents <- round(percents, digits = 1)

lab_percent <- c(glue("PCoA 1({percents[1]}%)"), glue("PCoA 2({percents[2]}%)"))


## plot results ------

## Only the first 11 pairs
positions %>% 
  filter(pair <= 11) %>% 
  ggplot(aes(x = PCoA1, y = -PCoA2, color = manipulator)) +
  geom_point() +
  labs(x = lab_percent[1], y = lab_percent[2], color = "") +
  theme(legend.position = "top") +
  geom_text(aes(x = PCoA1+0.01, label = pair), color = "black") +
  ggtitle("Note: percentages calculated for all 15 pairs")



## Visualization with connecting lines ---

controls <- positions %>% 
  filter(manipulator == "Control")

manipulators <- positions %>% 
  filter(manipulator == "Manipulator")


controls <- controls %>% 
  # add manipulator pairs and their PCoA coordinates as end points for connecting lines
  left_join(select(manipulators, -sample_id, -manipulator) %>% rename(xend = PCoA1, yend = PCoA2), by = "pair")

manipulators <- manipulators %>% 
  # add manipulator pairs and their PCoA coordinates as end points for connecting lines
  left_join(select(controls, -sample_id, -manipulator, -xend, -yend) %>% rename(xend = PCoA1, yend = PCoA2), by = "pair")

positions2 <- rbind(controls, manipulators)

fig5_withpairs <- positions2 %>% 
  #let's switch factor levels to get same coloring
  mutate(manipulator = factor(manipulator, levels = c("Manipulator", "Control"))) %>% 
  ggplot(aes(x = PCoA1, y = PCoA2, color = manipulator)) +
  geom_point(size = 2, alpha = 0.8) +
  labs(x = lab_percent[1], y = lab_percent[2], color = "") +
  theme(legend.position = "top") +
  geom_text(aes(x = PCoA1+0.02, label = pair), color = "black", alpha = 0.8) +
  geom_segment(aes(xend = xend, yend = yend), color = "grey", alpha = 0.6) +
  scale_colour_brewer(palette = "Set1")

#ggsave(plot = fig5_withpairs, filename = "outputs/Figure5_withpairs.pdf", device = "pdf", width = 14, height = 12, units = "cm", dpi = 300)

fig5 <- positions2 %>% 
  #let's switch factor levels to get same coloring
  mutate(manipulator = factor(manipulator, levels = c("Manipulator", "Control"))) %>% 
  ggplot(aes(x = PCoA1, y = PCoA2, color = manipulator)) +
  geom_point(size = 2, alpha = 0.8) +
  labs(x = lab_percent[1], y = lab_percent[2], color = "") +
  theme(legend.position = "top") +
  geom_segment(aes(xend = xend, yend = yend), color = "grey", alpha = 0.6) +
  scale_colour_brewer(palette = "Set1")

#ggsave(plot = fig5, filename = "outputs/Figure5.pdf", device = "pdf", width = 14, height = 12, units = "cm", dpi = 300)
