################################################
# gbm
################################################

set.seed(1337)

# -- header -- #

setwd('~/Github/Racz2023trance/')

library(tidyverse)
library(magrittr)
library(glue)
library(h2o) # to use h2o
# don't panic:
# https://docs.h2o.ai/h2o/latest-stable/h2o-docs/index.html

# -- read-in -- #

d = read_tsv('data/dat_wide.tsv')

# -- wrangling -- #

# outcome = d %>% 
#   filter(var_id == 'EA112') %>% 
#   mutate(
#     outcome = case_when(
#       var_description == 'No trance states of any kind are known to occur, and there is no belief in possession.' ~ 'No trance states nor belief in possession',
#       var_description == 'Trance behavior is known to occur, but there is no belief in possession.' ~ 'Trance only',
#       var_description == 'A belief in possession exists.' ~ 'Possession only',
#       var_description == 'There is both a trance state and a belief in possession, but this belief refers to phenomena other than trance, which is explained through other categories.' ~ 'Separate trance and possession',
#       var_description %in% c(
#         'Two types of trance states are known to occur. One which is explained as due to possession and one which is given another type of explanation. In addition to explaining trance, possession belief also refers to one or more other phenomena.',
#         'Trance explained as due to possession is known to occur, and there are no other trance states, but cases of possession outside of trance are also believed to occur.',
#         'Trance states of two kinds are known to occur, some of which are explained by possession. No other phenomena are explained by possession.'
#         ) ~ 'Trance typically if possession',
#       var_description == 'Trance behavior is known to occur and is explained as due to possession. There is no possession belief referring to other experiences and there are no trance states with other explanations.' ~ 'Trance if and only if possession'
#     )
#   ) %>% 
#   select(soc_id,outcome)

# h2o not keen on character vectors
d %<>% 
  mutate_if(is.character, as.factor) %>% 
  mutate_if(is.logical, as.double)

d_sccs = filter(d, in_sccs == 1)

x = names(d)[!names(d) %in% c('soc_id','outcome','EA112_Trance_states','trance_present','possession_present','possession_trance_present','in_sccs')]
y = 'outcome'

# -- gbm -- #

# four gbm models. 
# i everything
# ii trance only
# iii possession only
# iv possession trance only

h2o.init(nthreads=16)

train = as.h2o(d_sccs)
trainea = as.h2o(d) 

# we define hyperparameters in the grid. we think most predictors are useless and colinear and aggressively force the parameter space to focus on including a few predictors but using most of the data (and using heaps of trees)
gbm_params1 = list(
  learn_rate = c(0.01,0.02,0.03,0.1),
  max_depth = c(1,3,5,7),
  sample_rate = c(0.4,0.7,0.9,0.95),
  col_sample_rate = c(0.1,0.2,0.3),
  min_split_improvement = c(1e-3,1e-5)
)

#
# i all possible levels
#

# we do a grid search
gbm_grid1 = h2o.grid("gbm", 
                     x = x, 
                     y = y,
                     grid_id = "gbm_grid1",
                     training_frame = train,
                     nfolds = 3,
                     ntrees = 100,
                     seed = 1,
                     distribution = 'multinomial',
                     categorical_encoding = 'enum', # important
                     stopping_metric = 'logloss',
                     hyper_params = gbm_params1
)

# save grid
# h2o.saveGrid(
#   'models',
#   'gbm_grid1',
#   save_params_references = FALSE,
#   export_cross_validation_predictions = FALSE
# )
# gbm_grid = h2o.loadGrid('models/gbm_grid')

# pick the best models from grid
gbm_grid_best1 = h2o.getGrid(grid_id = "gbm_grid1",
                            sort_by = "logloss",
                            decreasing = FALSE)

# pick bestest model
fit11 = h2o.getModel(gbm_grid_best1@model_ids[[1]])
# pick worst model
fit12 = h2o.getModel(gbm_grid_best1@model_ids[[384]])

# check stats
h2o.performance(fit11, xval = TRUE)
h2o.performance(fit12, xval = TRUE)

# varimp
varimp11 = as_tibble(h2o.varimp(fit11))

# don't trust the built-in confusion matrix!
pred11 = bind_cols(d_sccs,as_tibble(h2o.predict(object = fit11, newdata = train)))
conf_matrix1 = pred11 %>% 
  select(outcome,predict) %>% 
  count(outcome,predict) %>% 
  pivot_wider(names_from = predict, values_from = n, values_fill = 0)
conf_matrix1b = as_tibble(h2o.confusionMatrix(fit11))
# these are the same, good.

# predict on "test data"
pred11b = bind_cols(d,as_tibble(h2o.predict(object = fit11, newdata = trainea)))
conf_matrix1c = pred11b %>% 
  select(outcome,predict) %>% 
  count(outcome,predict) %>% 
  pivot_wider(names_from = predict, values_from = n, values_fill = 0)

#
# ii trance only 
#

train$trance_present = h2o.asfactor(train$trance_present)

# we do a grid search
gbm_grid2 = h2o.grid("gbm", 
                    x = x, 
                    y = 'trance_present',
                    grid_id = "gbm_grid2",
                    training_frame = train,
                    nfolds = 3,
                    ntrees = 100,
                    seed = 1,
                    distribution = 'bernoulli',
                    categorical_encoding = 'enum', # important
                    stopping_metric = 'logloss',
                    hyper_params = gbm_params1
)

# pick the best models from grid
gbm_grid_best2 = h2o.getGrid(grid_id = "gbm_grid2",
                           sort_by = "logloss",
                           decreasing = FALSE)

# pick bestest model
fit21 = h2o.getModel(gbm_grid_best2@model_ids[[1]])
# pick worst model
fit22 = h2o.getModel(gbm_grid_best2@model_ids[[384]])

# check stats
h2o.performance(fit21, xval = TRUE)
h2o.performance(fit22, xval = TRUE)

# varimp
varimp21 = as_tibble(h2o.varimp(fit21))

# don't trust the built-in confusion matrix!
pred21 = bind_cols(d_sccs,as_tibble(h2o.predict(object = fit21, newdata = train)))
conf_matrix2 = pred21 %>% 
  select(outcome,predict) %>% 
  count(outcome,predict) %>% 
  pivot_wider(names_from = predict, values_from = n, values_fill = 0)
conf_matrix2b = as_tibble(h2o.confusionMatrix(fit21))
# looks fine 

# predict on "test data"
pred21b = bind_cols(d,as_tibble(h2o.predict(object = fit21, newdata = trainea)))
conf_matrix2c = pred21b %>% 
  select(outcome,predict) %>% 
  count(outcome,predict) %>% 
  pivot_wider(names_from = predict, values_from = n, values_fill = 0)

#
# iii pos only 
#

train$possession_present = h2o.asfactor(train$possession_present)

# we do a grid search
gbm_grid3 = h2o.grid("gbm", 
                     x = x, 
                     y = 'possession_present',
                     grid_id = "gbm_grid3",
                     training_frame = train,
                     nfolds = 3,
                     ntrees = 100,
                     seed = 1,
                     distribution = 'bernoulli',
                     categorical_encoding = 'enum', # important
                     stopping_metric = 'logloss',
                     hyper_params = gbm_params1
)

# pick the best models from grid
gbm_grid_best3 = h2o.getGrid(grid_id = "gbm_grid3",
                             sort_by = "logloss",
                             decreasing = FALSE)

# pick bestest model
fit31 = h2o.getModel(gbm_grid_best3@model_ids[[1]])
# pick worst model
fit32 = h2o.getModel(gbm_grid_best3@model_ids[[384]])

# check stats
h2o.performance(fit31, xval = TRUE)
h2o.performance(fit32, xval = TRUE)

# varimp
varimp31 = as_tibble(h2o.varimp(fit31))

# don't trust the built-in confusion matrix!
pred31 = bind_cols(d_sccs,as_tibble(h2o.predict(object = fit31, newdata = train)))
conf_matrix3 = pred31 %>% 
  select(outcome,predict) %>% 
  count(outcome,predict) %>% 
  pivot_wider(names_from = predict, values_from = n, values_fill = 0)
conf_matrix3b = as_tibble(h2o.confusionMatrix(fit31))

# predict on "test data"
pred31b = bind_cols(d,as_tibble(h2o.predict(object = fit31, newdata = trainea)))
conf_matrix3c = pred31b %>% 
  select(outcome,predict) %>% 
  count(outcome,predict) %>% 
  pivot_wider(names_from = predict, values_from = n, values_fill = 0)

#
# iv pos trance
#

train$possession_trance_present = h2o.asfactor(train$possession_trance_present)

# we do a grid search
gbm_grid4 = h2o.grid("gbm", 
                     x = x, 
                     y = 'possession_trance_present',
                     grid_id = "gbm_grid4",
                     training_frame = train,
                     nfolds = 3,
                     ntrees = 100,
                     seed = 1,
                     distribution = 'bernoulli',
                     categorical_encoding = 'enum', # important
                     stopping_metric = 'logloss',
                     hyper_params = gbm_params1
)

# pick the best models from grid
gbm_grid_best4 = h2o.getGrid(grid_id = "gbm_grid4",
                             sort_by = "logloss",
                             decreasing = FALSE)

# pick bestest model
fit41 = h2o.getModel(gbm_grid_best4@model_ids[[1]])
# pick worst model
fit42 = h2o.getModel(gbm_grid_best4@model_ids[[384]])

# check stats
h2o.performance(fit41, xval = TRUE)
h2o.performance(fit42, xval = TRUE)

# varimp
varimp41 = as_tibble(h2o.varimp(fit41))

# don't trust the built-in confusion matrix!
pred41 = bind_cols(d_sccs,as_tibble(h2o.predict(object = fit41, newdata = train)))
conf_matrix4 = pred41 %>% 
  select(outcome,predict) %>% 
  count(outcome,predict) %>% 
  pivot_wider(names_from = predict, values_from = n, values_fill = 0)
conf_matrix4b = as_tibble(h2o.confusionMatrix(fit41))

# predict on "test data"
pred41b = bind_cols(d,as_tibble(h2o.predict(object = fit41, newdata = trainea)))
conf_matrix4c = pred41b %>% 
  select(outcome,predict) %>% 
  count(outcome,predict) %>% 
  pivot_wider(names_from = predict, values_from = n, values_fill = 0)

# -- save everything -- #

# fit11,fit21,fit31,fit41
# varimp, pred, conf matrix
map(c(fit11,fit21,fit31,fit41), ~ h2o.saveModel(., 'models'))
write_tsv(varimp11, 'models/varimp11.tsv')
write_tsv(varimp21, 'models/varimp21.tsv')
write_tsv(varimp31, 'models/varimp31.tsv')
write_tsv(varimp41, 'models/varimp41.tsv')
write_tsv(conf_matrix1, 'models/conf_matrix11.tsv')
write_tsv(conf_matrix2, 'models/conf_matrix21.tsv')
write_tsv(conf_matrix3, 'models/conf_matrix31.tsv')
write_tsv(conf_matrix4, 'models/conf_matrix41.tsv')
write_tsv(conf_matrix1b, 'models/conf_matrix11model.tsv')
write_tsv(conf_matrix2b, 'models/conf_matrix21model.tsv')
write_tsv(conf_matrix3b, 'models/conf_matrix31model.tsv')
write_tsv(conf_matrix4b, 'models/conf_matrix41model.tsv')
write_tsv(conf_matrix1c, 'models/conf_matrix11test.tsv')
write_tsv(conf_matrix2c, 'models/conf_matrix21test.tsv')
write_tsv(conf_matrix3c, 'models/conf_matrix31test.tsv')
write_tsv(conf_matrix4c, 'models/conf_matrix41test.tsv')
