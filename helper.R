# pulls data in from the DPLACE github repository, filters for trance & possesion analysis, tidies it up, saves it
# author: pracz
# date: 20/10/22

set.seed(1337)

setwd('~/Github/Racz2023trance/')
library(tidyverse)
library(glue)
library(caret)
library(rjson)
library(RCurl)
library(vctrs)

# --- pull --- #

# pull variables codes etc from the dplace github repository
variables = read_csv("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/datasets/EA/variables.csv")

codes = read_csv("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/datasets/EA/codes.csv")

codes = codes %>% # we need some changes in codes
  rename(
    var_description = description,
    var_name = name
  ) %>% 
  mutate(
    num_id = str_replace(var_id, 'EA', '') %>% as.double() %>% as.character()
  )

dat = read_csv("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/datasets/EA/data.csv")

languages = read_csv("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/csv/glottolog.csv") %>% 
  rename(family = family_name, glottocode = id) %>% 
  select(family, glottocode)

sccs = read_csv("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/datasets/SCCS/societies.csv") %>% 
  select(pref_name_for_society,glottocode,HRAF_name_ID) %>% 
  rename(society = pref_name_for_society)

# for societies, we don't keep everything and rename some things
societies = read_csv("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/datasets/EA/societies.csv") %>% 
  select(id, glottocode, pref_name_for_society, Lat, Long) %>% 
  rename(
    lat = Lat, 
    lon = Long, 
    soc_id = id, 
    society = pref_name_for_society
  )

# locations is a json. the json converter doesn't quite cope with it so we need some tricks
locations = getURL("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/geo/societies_tdwg.json") %>%
  fromJSON # makes it into a list of lists
soc_id = names(locations)
locations = locations %>% 
  map( ~ vec_rbind(.)) %>% # turn the lists in the list into tibbles
  map( ~ mutate_all(., as.character)) %>% # change all columns in the tibbles in the list to char
  bind_rows() # bind tibbles in list into big tibble (this won't work w/o prev line for reasons)
locations$soc_id = soc_id

# --- shape --- #

# joining data
names(variables) = paste0('var_', names(variables)) # keep names of variables separate
locations = locations %>% # we need to fix locations now
  select(soc_id, name) %>% 
  rename(region = name)

# we make a num_id by removing EA from each var_id
dat = dat %>% 
  mutate(
  num_id = str_replace(var_id, 'EA', '') %>% as.double() %>% as.character()
)

# --- filter --- #

# these are the variables of interest for trance and possession
keep_vars = paste('EA', c("008","012","015","023","030","031","032","033","034","042","043","053","054","066","068","070","072","073","074","078","112","113"), sep='')

# we recode some of these as ordinal variables, others as factors, we leave the rest as is, thereby assuming it is an ordinal variable
trance_dict = codes %>% 
  filter(var_id %in% keep_vars) %>% 
  mutate(
    recoded_value =
      case_when(
        var_id == 'EA012' & code %in% c(4,8,10,12) ~ 'husband',
        var_id == 'EA012' & code %in% c(1,9,3,5,11) ~ 'wife',
        var_id == 'EA012' & code %in% c(2,6,7) ~ 'other',
        var_id == 'EA015' & code %in% c(1,2) ~ "endogamous",
        var_id == 'EA015' & code %in% c(3) ~ "agamous",
        var_id == 'EA015' & code %in% c(4,5,6) ~ "exogamous",
        var_id == 'EA023' & code %in% c(7,8) ~ '1',
        var_id == 'EA023' & code %in% c(11,12) ~ '2',
        var_id == 'EA023' & code %in% c(1,2,3,4,5,6,9,13) ~ '3',
        var_id == 'EA023' & code %in% c(10) ~ '4',
        var_id == 'EA043' & code %in% c(1) ~ "patrilineal",
        var_id == 'EA043' & code %in% c(3) ~ "matrilineal",
        var_id == 'EA043' & code %in% c(2,5,6) ~ "cognatic",
        var_id == 'EA043' & code %in% c(4,7) ~ "other",
        var_id == 'EA042' & code %in% c(7) ~ "int_agr",
        var_id == 'EA042' & code %in% c(5,6,9) ~ "ext_agr",
        var_id == 'EA042' & code %in% c(4) ~ "pastoralism",
        var_id == 'EA042' & code %in% c(1,2,3) ~ "foraging",
        var_id == 'EA042' & code == 8 ~ 'multiple',
        var_id == 'EA053' & code %in% c(1,2) ~ 'mostly male',
        var_id == 'EA053' & code %in% c(5,6) ~ 'mostly female',
        var_id == 'EA053' & code %in% c(3,4) ~ 'both',
        var_id == 'EA053' & code %in% c(7,8,9) ~ 'other',
        var_id == 'EA054' & code %in% c(1,2) ~ 'mostly male',
        var_id == 'EA054' & code %in% c(5,6) ~ 'mostly female',
        var_id == 'EA054' & code %in% c(3,4) ~ 'both',
        var_id == 'EA054' & code %in% c(7,8,9) ~ 'other',
        var_id == 'EA072' & code %in% c(1) ~ 'patrilineal',
        var_id == 'EA072' & code %in% c(2) ~ 'matrilineal',
        var_id == 'EA072' & code %in% c(3,4,5,6,7) ~ 'other',
        var_id == 'EA072' & code %in% c(9) ~ 'absent',
        var_id == 'EA073' & code %in% c(1,2) ~ 'patrilineal',
        var_id == 'EA073' & code %in% c(3,4) ~ 'matrilineal',
        var_id == 'EA073' & code %in% c(5) ~ 'other',
        var_id == 'EA073' & code %in% c(9) ~ 'absent',
        var_id == 'EA074' & code %in% c(6,7) ~ 'patrilineal',
        var_id == 'EA074' & code %in% c(2,3) ~ 'matrilineal',
        var_id == 'EA074' & code %in% c(4,5) ~ 'other',
        var_id == 'EA074' & code %in% c(1) ~ 'absent',
        var_id == 'EA113' & code == 1 ~ 'T',
        var_id == 'EA113' & code == 2 ~ 'F',
        # var_id == 'EA112' & code == 8 ~ '1', # out: no trance, no pos
        # var_id == 'EA112' & code %in% c(1:2) ~ '2', # out: trance xor pos
        # var_id == 'EA112' & code == 5 ~ '3', # out: trance and pos, independent
        # var_id == 'EA112' & code %in% c(4,6,7) ~ '4', # out: pos causes trance, maybe other trance, maybe other pos
        # var_id == 'EA112' & code == 3 ~ '5', # out: pos causes trance, nothing else causes t, pos causes nothing else
        TRUE ~ as.character(code) # otherwise do this
      )
  )

# --- wrangling --- #

# we tidy up the variables
variables_dict = variables %>% 
  select(var_id, var_title, var_definition, var_type) %>% 
  right_join(trance_dict, by = "var_id") %>% 
  mutate(var_title2 = var_title %>% str_replace_all(' ', '_') %>% 
           str_replace_all('[)(:]', '')
  )

# put together observations w/ lang and loc
observations_dict = societies %>% 
  left_join(languages, by = "glottocode") %>% 
  left_join(locations, by = "soc_id")

# --- combining to long --- #

# these are societies w/o trance and possession data. we won't use them. (alternatively we could generate predictors for them and then go and ask like the Chumash whether we got it right)
no_trance = dat %>% 
  filter(var_id == 'EA112', is.na(code)) %>% 
  distinct(soc_id) %>% 
  pull(soc_id)

# we merge everything together, drop observations with no trance data, only keep variables of interest, get nice long df
datl = dat %>%
  select(soc_id,sub_case,year,var_id,code,references,source_coded_data) %>% 
  left_join(observations_dict, by = 'soc_id') %>% 
  left_join(variables_dict, by = c("var_id", "code")) %>% 
  filter(
    var_id %in% trance_dict$var_id,
    !soc_id %in% no_trance
    ) %>% 
  mutate(in_sccs = society %in% sccs$society)

# count(datl, society)
# count(datl, in_sccs)
# count(filter(datl,var_id == 'EA112'), recoded_value)
# count(filter(datl,var_id == 'EA112',in_sccs), recoded_value)

# --- building wide for ML --- #

# for the ML fit, we want to make sure it gets factors right. so we make (a) factors with levels that work in alphabetic order (1,2,3 turns into l_1,l_2,l_3) that can be enum encoded
# and (b) one-hot encoded factors (which will be also enum encoded but for a factor w/ two levels it doesn't make a difference)

# one-hot encode factors, make numeric vars ordinal (or at least make it so that h2o figures this out)

datw = datl %>% 
  select(soc_id,var_id,var_title2,recoded_value,in_sccs) %>% 
  mutate(var_title3 = glue('{var_id}_{var_title2}')) %>% 
  select(soc_id,var_title3,in_sccs,recoded_value) %>% 
  pivot_wider(names_from = var_title3, values_from = recoded_value)

# map(datw, ~ max(., na.rm = T)) # nothing over 10 which would mess with auto ordering

datwo = datw %>% 
  select(matches('EA(008|023|027|030|031|032|033|034|066|068|070|078)')) %>% 
  map_df(., ~ str_replace(., '^','l_'))

datwc = datw %>% 
  select(matches('EA(012|015|042|043|053|054|072|073|074|113)')) %>% 
  mutate_all(fct_infreq) # rerank these to show some consistent pattern: most populous level is highest

# turn them into one-hot encoded with no identifiability problems (fullrank does that)
datwc = as_tibble(predict(dummyVars(" ~ .", fullRank = T, data = datwc), newdata = datwc))

# nice names
names(datwc) = str_replace(names(datwc), '\\.', '_')

datw2 = datw %>% 
  select(soc_id,in_sccs,EA112_Trance_states) %>% 
  bind_cols(datwc) %>% 
  bind_cols(datwo)

# and since I bound columns with no index I basically check by hand to make sure they line up
checkDat = function(){
  rown = sample(nrow(datw2),1)
  coln = sample(ncol(datw2),1)
  my_socid = datw2[rown,]$soc_id
  my_varid = str_extract(names(datw2[,coln]), '^EA...')
  my_value = datw2[rown,coln]
  return(c(my_socid,my_varid,my_value))
}

my_vars = checkDat()
my_vars
datl %>% 
  filter(soc_id == my_vars[1],var_id == my_vars[2]) %>% 
  select(code,var_title,var_type,var_description)
# yes okay

# define a few possible outcome codings.
datw2 = datl %>% 
  filter(var_id == 'EA112') %>% 
  distinct(code,var_name) %>% 
  mutate(
    EA112_Trance_states = as.character(code),
    trance_present = case_when(
      EA112_Trance_states %in% c(1,3,4,5,6,7) ~ T,
      EA112_Trance_states %in% c(2,8) ~ F # second outcome column
         ),
    possession_present = case_when(
      EA112_Trance_states %in% c(2,3,4,5,6,7) ~ T,
      EA112_Trance_states %in% c(1,8) ~ F # third outcome column
        ),
    possession_trance_present = case_when(
      EA112_Trance_states %in% c(3,4,6,7) ~ T,
      EA112_Trance_states %in% c(1,2,5,8) ~ F
        )
  ) %>% 
  rename('outcome' = var_name) %>% # first outcome column
  select(-code) %>% 
  left_join(datw2, by = "EA112_Trance_states")

# --- write --- #

write_tsv(datl, 'data/dat_long.tsv')
write_tsv(datw2, 'data/dat_wide.tsv')
