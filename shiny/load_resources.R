##------------------------------------------##
##            load_resources.R              ##
##                                          ##
##   Loads the libraries, source files and  ##
##   data objects needed to run plot code   ##
##------------------------------------------##


##---------------##
##-- LIBRARIES --##
##---------------##

library(jheem)
library(distributions)
library(bayesian.simulations)

library(plotly)
library(data.table)
library(ggsci)


##------------------##
##-- DATA OBJECTS --##
##------------------##

load('resources/msa_surveillance.Rdata')
load('resources/state_surveillance.Rdata')
load('resources/census_totals.Rdata')
load('resources/locale_mapping.Rdata')


##-----------------##
##-- SOURCE CODE --##
##-----------------##

source('model_code/version_manager.R')
source('model_code/plot_simulations.R')
source('model_code/postprocessing.R')
source('model_code/locale_mappings.R')
source('model_code/hiv_surveillance_manager.R')
source('model_code/census_totals.R')
source('model_code/setup_jheem_from_components.R')
source('model_code/interpolating.R')
source('model_code/file_manager.R')
source('model_code/default_jheem_settings.R')
source('model_code/base_parameters.R')

source('model_code/intervention_units.R')
source('model_code/target_population.R')
source('model_code/interventions.R')
source('model_code/create_standard_intervention_presets.R')
source('model_code/intervention_presets.R')
source('model_code/systematic_intervention_sets.R')

source('model_code/interventions_for_simset.R')
source('model_code/interpolating.R')
source('model_code/setup_helpers.R')
source('model_code/logit_transformations.R')
source('model_code/setup_jheem_from_components.R')
source('model_code/setup_jheem_components.R')
source('model_code/compression.R')

source('model_code/calibrated_parameters_113_helpers.R')
source('model_code/prep_manager_2.R')
source('model_code/pairing_manager.R')

source('model_code/covid_jheem_web_interface.R')
