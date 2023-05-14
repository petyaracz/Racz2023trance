################################################
# glm
################################################

set.seed(1337)

# -- header -- #

setwd('~/Github/Racz2023trance/')

library(tidyverse)
library(magrittr)
library(glue)
library(rstanarm) 

# -- read-in -- #

# data long
dl = read_tsv('data/dat_long.tsv')
# data wide
dw = read_tsv('data/dat_wide.tsv')
# important vars according to gbm
vars = read_tsv('models/varimp11.tsv')

# -- wrangling -- #

# vars
vars %<>% 
  mutate(cumsump = cumsum(percentage)) %>%
  filter(cumsump < .8) %>%
  pull(variable)
# grouping factors
dl %<>% 
  distinct(soc_id,family,region)
# sort out factor order, add grouping factors
dw %<>% 
  select(all_of(c('soc_id','possession_trance_present',vars))) %>% 
  left_join(dl) %>% 
  mutate(across(starts_with('EA'), ~ factor(.x, ordered = T)))
for(i in 3:9){
  print(nrow(na.omit(dw[,1:i])))
}

dw2 = na.omit(dw)

# -- model -- #

fit1 = stan_glmer(possession_trance_present ~ 1 + 
                    EA070_Slavery_type +
                    EA008_Domestic_organization +
                    EA078_Norms_of_premarital_sexual_behavior_of_girls +
                    EA066_Class_differentiation_primary +
                    EA033_Jurisdictional_hierarchy_beyond_local_community +
                    EA030_Settlement_patterns +
                    EA034_Religion_high_gods +
                    (1|family) +
                    (1|region), family = binomial, data = dw2, cores = 8, chains = 8, iter = 2000)

plot(fit1, regex_pars = 'EA')
ggsave('figures/glm_res.png', width = 8, height = 6)
plot(fit1, "dens_overlay", pars = "(Intercept)")
plot(fit1, 'rhat')
broom.mixed::tidy(fit1, conf.int = T, conf.level = .95) %>% 
  write_tsv('models/glm_estimates.tsv')

# -- pred -- #

