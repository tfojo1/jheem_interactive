
##-------------------##
##-- LIBRARY CALLS --##
##-------------------##
#library(processx)
#library(orca)
library(shiny)
library(shinyWidgets)
library(mailR)
library(cachem)
library(DT)
library(shinycssloaders)

##------------------##
##-- SOURCE FILES --##
##------------------##


source('env.R')
source('helpers/location_names.R')
source('helpers/progress_bar.R')
source('helpers/display_size.R')
source('helpers/error_checking.R')
source('helpers/alerts.R')
source('server/contact_handlers.R')
source('server/control_helpers.R')
source('plot_interface/generate_plot.R')
source('plot_interface/plot_interface.R')
source('helpers/multi_cache.R')
source('helpers/intervention_map.R')
source('helpers/analytics.R')
#source('load_resources.R')
#source('ui/display_helpers.R', local=T)
source('ui/custom_interventions.R', local=T)
source('ui/modals.R')
source('helpers/time_text.R')
source('plot_interface/generate_plot.R')
source('plot_interface/plot_interface.R')
source('server/share_handlers.R')
source('server/control_helpers.R')
source('server/server_utils.R')
source('server/display_event_handlers.R')
source('simulation/simulate_intervention.R')
source('links/link_interface.R')


##----------------------##
##-- SET UP THE CACHE --##
##----------------------##
#shinyOptions(cache=diskCache(file.path(dirname(tempdir()), "myapp-cache")))
DISK.CACHE.1 = cachem::cache_disk(max_size = 1e9, evict='lru')
DISK.CACHE.2 = cachem::cache_disk(max_size = 1e9, evict='lru')

##---------------------------##
##-- THE server() FUNCTION --##
##---------------------------##

server <- function(input, output, session, cache) 
{
    ##--------------------##    
    ##-- INITIAL SET-UP --##
    ##--------------------##
    
    # Print an initial message - useful for debugging on shinyapps.io servers
    print(paste0("Launching server() function - ", Sys.time()))
    
    
    #-- Make our session cache --#
    mem.cache = cachem::cache_mem(max_size = 300e6, evict='lru')
    cache = create.multi.cache(mem.cache=mem.cache, 
                               disk.caches=list(DISK.CACHE.1, DISK.CACHE.2),
                               directories = 'sim_cache')
    
    
    ##-----------------------------------------##
    ##-- EVENT HANDLERS FOR UPDATING DISPLAY --##
    ##-----------------------------------------##

    # in server/display_event_handlers.R
    add.display.event.handlers(session, input, output, cache)
    

    ##-----------------------------------------------##
    ##-- EVENT HANDLERS FOR UPDATING PLOT CONTROLS --##
    ##-----------------------------------------------##
    
    # in server/control_helpers.R
    add.control.event.handlers(session, input, output, cache, suffix='prerun')
    add.control.event.handlers(session, input, output, cache, suffix='custom')
    
    ##-----------------------------------------------##
    ##-- EVENT HANDLERS: CUSTOM INTERVENTIONS      --##
    ##-----------------------------------------------##
    
    # in ui/custom_helpers.R
    add.custom.event.handlers(session, input, output)
    
    
    ##------------------##
    ##-- CONTACT FORM --##
    ##------------------##
    
    add.contact.handlers(session, input, output)
    
    ##-------------------------##
    ##-- LINKS FROM OVERVIEW --##
    ##-------------------------##
    
    observeEvent(input$link_from_overview, {
        print(paste0('link to ', input$link_from_overview))
        updateNavbarPage(session,
                         inputId = 'main_nav',
                         selected = input$link_from_overview)
    })
    
}
