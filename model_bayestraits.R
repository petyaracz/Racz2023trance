setwd('~/Github/Racz2023trance/')
library(tidyverse)
library(glue)

library(ape)
library(ggtree)
library(bayestraitr) # sam passmore's bayestraits helper library
library(magrittr)

# -- in -- #

# data from helper.r
dw = read_tsv('data/dat_wide.tsv')
dl = read_tsv('data/dat_long.tsv')

# trees from d-place
tr_aut = read.nexus("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/phylogenies/glottolog_aust1307/summary.trees")
tr_afra = read.nexus("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/phylogenies/glottolog_afro1255/summary.trees")
tr_atla = read.nexus("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/phylogenies/glottolog_atla1278/summary.trees")

# -- formatting -- #

dw %<>% 
  mutate(
    slavery_present = EA070_Slavery_type == "l_1",
    domestic_organisation_nuclear = EA008_Domestic_organization %in% c('l_1','l_2')
  )

dw2 = dl %>% 
  distinct(soc_id,society,glottocode,family) %>% 
  left_join(dw) %>% 
  select(family,glottocode,slavery_present,domestic_organisation_nuclear,possession_trance_present) %>% 
  mutate_if(is.logical,as.double) %>% 
  mutate_if(is.double,as.character)

d_aut = dw2 %>% 
  filter(family == 'Austronesian') %>% 
  as.data.frame()
d_afr = dw2 %>% 
  filter(family == 'Afro-Asiatic',glottocode != 'kano1249') %>% 
  as.data.frame()
d_atl = dw2 %>% 
  filter(family == 'Atlantic-Congo',glottocode != 'boro1274') %>% 
  as.data.frame()

rownames(d_aut) = d_aut$glottocode
rownames(d_afr) = d_afr$glottocode
rownames(d_atl) = d_atl$glottocode

# -- bayestraits: out -- #

bt_write(tree = tr_aut, data = d_aut, variables = c('slavery_present','possession_trance_present'), filename = 'Bayestraits/aut_sl')
bt_write(tree = tr_aut, data = d_aut, variables = c('domestic_organisation_nuclear','possession_trance_present'), filename = 'Bayestraits/aut_dom')

bt_write(tree = tr_afra, data = d_afr, variables = c('slavery_present','possession_trance_present'), filename = 'Bayestraits/afr_sl')
bt_write(tree = tr_afra, data = d_afr, variables = c('domestic_organisation_nuclear','possession_trance_present'), filename = 'Bayestraits/afr_dom')

bt_write(tree = tr_atla, data = d_atl, variables = c('slavery_present','possession_trance_present'), filename = 'Bayestraits/atl_sl')
bt_write(tree = tr_atla, data = d_atl, variables = c('domestic_organisation_nuclear','possession_trance_present'), filename = 'Bayestraits/atl_dom')

# -- bayestraits: run -- #

# copied trees and data to subfolders to keep files (Dependant/Independent)

## slavery

### Atlantic-Congo
#### independent
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Independent/atl_sl.bttrees Bayestraits/Independent/atl_sl.btdata < Bayestraits/Independent_runner.txt')
atl_sl_indep_stones = bt_read.stones('Bayestraits/Independent/atl_sl.btdata.Stones.txt')
atl_sl_indep_marg_l = atl_sl_indep_stones$marginal_likelihood
#### dependant
# system('./Bayestraits/BayesTraitsV4 Bayestraits/atl_sl.bttrees Bayestraits/atl_sl.btdata < Bayestraits/Dependant_runner.txt')
atl_sl_dep_stones = bt_read.stones('Bayestraits/atl_sl.btdata.Stones.txt')
atl_sl_dep_marg_l = atl_sl_dep_stones$marginal_likelihood

### Afro-Asiatic
#### independent
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Independent/afr_sl.bttrees Bayestraits/Independent/afr_sl.btdata < Bayestraits/Independent_runner.txt')
afr_sl_indep_stones = bt_read.stones('Bayestraits/Independent/afr_sl.btdata.Stones.txt')
afr_sl_indep_marg_l = afr_sl_indep_stones$marginal_likelihood
#### dependant
# system('./Bayestraits/BayesTraitsV4 Bayestraits/afr_sl.bttrees Bayestraits/afr_sl.btdata < Bayestraits/Dependant_runner.txt')
afr_sl_dep_stones = bt_read.stones('Bayestraits/Dependant/afr_sl.btdata.Stones.txt')
afr_sl_dep_marg_l = afr_sl_dep_stones$marginal_likelihood

### Austronesian
#### independent
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Independent/aut_sl.bttrees Bayestraits/Independent/aut_sl.btdata < Bayestraits/Independent_runner.txt')
aut_sl_indep_stones = bt_read.stones('Bayestraits/Independent/aut_sl.btdata.Stones.txt')
aut_sl_indep_marg_l = aut_sl_indep_stones$marginal_likelihood
#### dependant
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Dependant/aut_sl.bttrees Bayestraits/Dependant/aut_sl.btdata < Bayestraits/Dependant_runner.txt')
aut_sl_dep_stones = bt_read.stones('Bayestraits/Dependant/aut_sl.btdata.Stones.txt')
aut_sl_dep_marg_l = aut_sl_dep_stones$marginal_likelihood

## domestic organisation

### Atlantic-Congo
#### independent
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Independent/atl_dom.bttrees Bayestraits/Independent/atl_dom.btdata < Bayestraits/Independent_runner.txt')
atl_dom_indep_stones = bt_read.stones('Bayestraits/Independent/atl_dom.btdata.Stones.txt')
atl_dom_indep_marg_l = atl_dom_indep_stones$marginal_likelihood
#### dependant
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Dependant/atl_dom.bttrees Bayestraits/Dependant/atl_dom.btdata < Bayestraits/Dependant_runner.txt')
atl_dom_dep_stones = bt_read.stones('Bayestraits/Dependant/atl_dom.btdata.Stones.txt')
atl_dom_dep_marg_l = atl_dom_dep_stones$marginal_likelihood

### Afro-Asiatic
#### independent
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Independent/afr_dom.bttrees Bayestraits/Independent/afr_dom.btdata < Bayestraits/Independent_runner.txt')
afr_dom_indep_stones = bt_read.stones('Bayestraits/Independent/afr_dom.btdata.Stones.txt')
afr_dom_indep_marg_l = afr_dom_indep_stones$marginal_likelihood
#### dependant
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Dependant/afr_dom.bttrees Bayestraits/Dependant/afr_dom.btdata < Bayestraits/Dependant_runner.txt')
afr_dom_dep_stones = bt_read.stones('Bayestraits/Dependant/afr_dom.btdata.Stones.txt')
afr_dom_dep_marg_l = afr_dom_dep_stones$marginal_likelihood

### Austronesian
#### independent
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Independent/aut_dom.bttrees Bayestraits/Independent/aut_dom.btdata < Bayestraits/Independent_runner.txt')
aut_dom_indep_stones = bt_read.stones('Bayestraits/Independent/aut_dom.btdata.Stones.txt')
aut_dom_indep_marg_l = aut_dom_indep_stones$marginal_likelihood
#### dependant
# system('./Bayestraits/BayesTraitsV4 Bayestraits/Dependant/aut_dom.bttrees Bayestraits/Dependant/aut_dom.btdata < Bayestraits/Dependant_runner.txt')
aut_dom_dep_stones = bt_read.stones('Bayestraits/Dependant/aut_dom.btdata.Stones.txt')
aut_dom_dep_marg_l = aut_dom_dep_stones$marginal_likelihood

# -- bayes factors -- #

bf_atl_sl = 2*(atl_sl_dep_marg_l-atl_sl_indep_marg_l)
bf_afr_sl = 2*(afr_sl_dep_marg_l-afr_sl_indep_marg_l)
bf_aut_sl = 2*(aut_sl_dep_marg_l-aut_sl_indep_marg_l)

bf_atl_dom = 2*(atl_dom_dep_marg_l-atl_dom_indep_marg_l)
bf_afr_dom = 2*(afr_dom_dep_marg_l-afr_dom_indep_marg_l)
bf_aut_dom = 2*(aut_dom_dep_marg_l-aut_dom_indep_marg_l)

bayes_factors = tibble(
  varible = c(
    rep('Slavery',3),rep('Nuclear family', 3)
  ),
  family = rep(
    c(
      'Atlantic-Congo','Afro-Asiatic','Austronesian'
    ),2
  ),
  bayes_factor = c(
    bf_atl_sl,bf_afr_sl,bf_aut_sl,bf_atl_dom,bf_afr_dom,bf_aut_dom
  )
)

write_tsv(bayes_factors, 'models/bayes_factors.tsv')
