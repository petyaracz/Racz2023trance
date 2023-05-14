################################################
# bayestraits helper
# pracz
################################################


setwd('~/Github/Racz2023trance/')
library(tidyverse)
library(glue)

library(ape)
library(ggtree)
library(bayestraitr) # sam passmore's bayestraits helper library
library(magrittr)

# -- fun -- #

# run bayestraits in the shell using parameters from the runner table return marg lik
runBSTR = function(run = 'run1', variable = 'sl', family = 'atl', type = 'Independent'){
  run_string = glue('./Bayestraits/BayesTraitsV4 Bayestraits/{run}/{type}/{family}_{variable}.bttrees Bayestraits/{run}/{type}/{family}_{variable}.btdata < Bayestraits/{type}_runner.txt')
  out_string = glue('Bayestraits/{run}/{type}/{family}_{variable}.btdata.Stones.txt')
  
  system(run_string)
  stones = bt_read.stones(out_string)
  marg_lik = stones$marginal_likelihood
  return(marg_lik)
}


# -- in -- #

# data from helper.r
dw = read_tsv('data/dat_wide.tsv')
dl = read_tsv('data/dat_long.tsv')

# trees from d-place but please cite original papers
tr_aut = read.nexus("data/aut.bttrees")
tr_atlc = read.nexus("data/bantu.bttrees")

# taxa from d-place
tax_aut = read_csv('data/austronesian_taxa.csv') %>% 
  select(taxon,glottocode)
tax_atlc = read_csv('data/bantu_taxa.csv') %>% 
  select(taxon,glottocode)

# tr_aut$tip.label %in% tax_aut$taxon
# tax_aut$taxon %in% tr_aut$tip.label
# tr_atlc$tip.label %in% tax_atlc$taxon
# tax_atlc$taxon %in% tr_atlc$tip.label

# -- formatting -- #

# turning preds binary
dw %<>% 
  mutate(
    slavery_present = EA070_Slavery_type == "l_1",
    domestic_organisation_nuclear = EA008_Domestic_organization %in% c('l_1','l_2')
  )

# converting
dw2 = dl %>% 
  distinct(soc_id,society,glottocode,family) %>% 
  left_join(dw) %>% 
  select(family,glottocode,slavery_present,domestic_organisation_nuclear,possession_trance_present) %>% 
  mutate_if(is.logical,as.double) %>% 
  mutate_if(is.double,as.character)

# grabbing relevant data
d_aut = dw2 %>% 
  filter(family == 'Austronesian') %>% 
  left_join(tax_aut) %>% 
  filter(!is.na(taxon)) %>% 
  as.data.frame()

d_atlc = dw2 %>% 
  filter(family == 'Atlantic-Congo') %>% 
  left_join(tax_atlc) %>% 
  filter(!is.na(taxon)) %>% 
  as.data.frame()

rownames(d_aut) = d_aut$taxon
rownames(d_atlc) = d_atlc$taxon


# -- bayestraits: out -- #

bt_write(tree = tr_aut, data = d_aut, variables = c('slavery_present','possession_trance_present'), filename = 'Bayestraits/aut_sl')
bt_write(tree = tr_aut, data = d_aut, variables = c('domestic_organisation_nuclear','possession_trance_present'), filename = 'Bayestraits/aut_dom')

bt_write(tree = tr_atlc, data = d_atlc, variables = c('slavery_present','possession_trance_present'), filename = 'Bayestraits/atl_sl')
bt_write(tree = tr_atlc, data = d_atlc, variables = c('domestic_organisation_nuclear','possession_trance_present'), filename = 'Bayestraits/atl_dom')

# -- bayestraits: setup -- #

# copy trees and data to subfolders to keep files (Dependant/Independent)

# -- bayestraits: run -- #

# three runs to check whether they converge

runner = crossing(
  run = c('run1','run2','run3'),
  variable = c('sl','dom'),
  family = c('atl','aut'),
  type = c('Independent','Dependant')
)

# this takes a while partner:
marg_liks = pmap_dbl(runner, runBSTR)

runner$marginal_likelihoods = marg_liks

runner %<>% 
  pivot_wider(names_from = run, values_from = marginal_likelihoods)

# -- bayes factors -- #

runner %<>% 
  select(-run2,-run3) %>% 
  pivot_wider(names_from = type, values_from = run1) %>% 
  mutate(
    BF = 2*(Dependant - Independent)
  )

write_tsv(runner, 'models/bayes_factors.tsv')
