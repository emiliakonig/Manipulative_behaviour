### A script for calculating the Shannon index and creating a visualization from pig-data
##  Code for producing figure 4 in the manuscript

## Libraries ------------

library(vegan)
library(tidyverse)
library(janitor)
library(readxl)
library(glue)
library(viridis)
library(lme4)
library(nlme)
library(here)

theme_set(theme_bw(base_size = 16))

## Data loading --------
here::i_am(path = "R/Figure4.R")

data_path <- here("data/")

data_files <- list.files(path = data_path)


## read data to data.frames
biom_nonfil_df <- read_csv(file = here(data_path, data_files[1]))
metadata_df <- readxl::read_xlsx(path = here(data_path, data_files[2]), sheet = 1)
secuencias_tree_df <- read_csv(file = here(data_path, data_files[3]))
tax_table_nonfil_df <- read_csv(file = here(data_path, data_files[4]))

# add a name to un-named first columns
names(biom_nonfil_df)[1] <- names(secuencias_tree_df)[1] <- names(tax_table_nonfil_df)[1] <- "code"

##########
### Calculating the Shannon index ---------------
##########

# Calculate Shannon index from pig data
biom_shannon <- 
  biom_nonfil_df %>% 
  # removing "non-pig" data
  select(-code, -`CN_MCC21-111_S106`) %>% 
  # Calculate the Shannon index for columns (i.e. data for all pigs)
  diversity(MARGIN = 2, index = "shannon")

## add data to a data.frame
shannon_df <- tibble("sample_id" = names(biom_shannon), "shannon" = biom_shannon) %>% 
  ## add information of manipulator pigs etc
  left_join(select(metadata_df, SAMPLE_ID, MANIPULATOR, `PAIR NO.`, SEX, SIZE) %>% 
              # rename columns to match existing names
              rename(sample_id = SAMPLE_ID, manipulator = MANIPULATOR, pair = `PAIR NO.`, sex = SEX, size = SIZE),
            # combine by sample id
            by = "sample_id") %>% 
  # Change manipulator to factor and change level names
  mutate(status = if_else(manipulator == 1, true = "Manipulator", false = "Control") %>% factor(levels = c("Manipulator", "Control")),
         sex = if_else(sex == 1, true = "female", false = "barrow") %>% factor(levels = c("female", "barrow")))


######
##  Create visualization -------------------
######

fig4 <- shannon_df %>% 
  ggplot(aes(x = status, y = shannon)) +
  geom_boxplot(fill = "grey", outlier.size = 0, alpha = 0.5) +
  geom_jitter(aes(color = sex), width = 0.1, size = 2) +
  scale_y_continuous(limits = c(4,6), breaks = c(4,4.5,5,5.5,6)) +
  labs(x = "", y = "Shannon index", color = "Sex") +
  theme(legend.position = "top") +
  scale_color_brewer(palette = "Set1")

## save figure 4
#ggsave(plot = fig4, filename = "outputs/Figure4.pdf", device = "pdf", width = 14, height = 14*2/3, units = "cm", dpi = 300)


#########
### Statistical tests for Shannon index and Richness -----------
#########



# Calculate richness from pig data
biom_richness <- 
  biom_nonfil_df %>% 
  # removing "non-pig" data
  select(-code, -`CN_MCC21-111_S106`) %>% 
  # Calculate the Shannon index for columns (i.e. data for all pigs)
  apply(MARGIN = 2, function(x){sum(x>0)})

## Calculate Chao1
biom_chao1 <- 
  biom_nonfil_df %>% 
  # removing "non-pig" data
  select(-code, -`CN_MCC21-111_S106`) %>% 
  # Calculate the Shannon index for columns (i.e. data for all pigs)
  apply(MARGIN = 2, function(x){estimateR(x)}) %>% 
  .["S.chao1",]


shannon_df <- shannon_df %>% 
  left_join(y = tibble("richness" = biom_richness, "chao1" = biom_chao1, sample_id = names(biom_richness)), by = "sample_id")

#Statisctical tests
t.test(shannon ~ manipulator, data = shannon_df)

aov1 <- aov(shannon ~ status*sex, data = shannon_df)
aov1

glmfit <- glm(shannon ~ status*sex, data = shannon_df)
glmfit2 <- glm(chao1 ~ status*sex, data = shannon_df)

glmfit3 <- glm(shannon ~ status*size, data = shannon_df)
glmfit4 <- glm(chao1 ~ status*size, data = shannon_df)


glmfit5 <- glm(chao1 ~ status*size, data = filter(shannon_df, size>0))

## Visualize Chao1

chao_plot <- shannon_df %>% 
  ggplot(aes(x = status, y = chao1)) +
  geom_boxplot(fill = "grey", outlier.size = 0, alpha = 0.5) +
  geom_jitter(aes(color = sex), width = 0.1, size = 2) +
  #scale_y_continuous(limits = c(4,6), breaks = c(4,4.5,5,5.5,6)) +
  labs(x = "", y = "Chao1 index", color = "Sex") +
  theme(legend.position = "top") +
  scale_color_brewer(palette = "Set1")

## save Chao figure
#ggsave(plot = chao_plot, filename = "outputs/Chao1.pdf", device = "pdf", width = 14, height = 14*2/3, units = "cm", dpi = 300)
