# Library calls & Source files ####
##-------------------##
##-- LIBRARY CALLS --##
##-------------------##
library(processx)
library(orca)
library(shiny)
library('mailR')

#library('stringr')
#library('DT')
#library('shinyjs')
#suppressPackageStartupMessages(library(EpiModel))  # param.dcm, init.dcm


##------------------##
##-- SOURCE FILES --##
##------------------##

source('env.R')
source("R/plot_resources.R")
source("R/plot_shiny_interface.R")
source('R/server_helpers.R')
source('R/styling_helpers.R')
source('R/server_utils.R')
source("R/server.routes.docs.R")
source("R/server.routes.runModel.R")
source("R/model_code/plot_simulations.R")

# Cache setup ####
##----------------------##
##-- SET UP THE CACHE --##
##----------------------##
shinyOptions(cache=diskCache(file.path(dirname(tempdir()), "myapp-cache")))
# Constants / initiliazers
# TODO: @jef/@tf: Add a 2nd diskCache that is dedicated to the necessary
# datasets we want to lazy load on app start for all sessions. For every,
# city, pulls those 2 files from the diskCache.
# CACHE = memoryCache(size = 20e6)
CACHE = diskCache(max_size = 20e6)

# Defaults ####
defaults <- list(
  # Unused
  # 'reset_main_sidebar'=FALSE,
  # 'sidebarItemExpanded'='',
  # 'sidebarCollapsed'=FALSE,
  # 'side_menu'='main',    
  # 'plotly_afterplot-A'='"mainPlot"',
  # '.clientValue-default-plotlyCrosstalkOpts'='',
  # 'plotly_relayout-A'='',
  
  # Page: run model
  # Runmodel 1/6: Projections
  'toggle_main'='Figure',
  'presetId'=NULL,
  
  # Runmodel 2/6: Location
  'geographic_location'=invert.keyVals(
    get.location.options(version))[1],
  
  # Runmodel 3/6: Potential Interventions
  'no_intervention_checkbox'=TRUE,
  
  'preset_tpop_1'='none',
  'intervention_1_selector'='prerun',
  
  # Runmodel 4/6: Epidemiological Indicators
  'epidemiological-indicators'=c('incidence', 'new'),
  
  # Runmodel 5/6: Demographic Subgroups
  'demog.selectAll'=FALSE,
  # 'sex'=c('male', 'female'),
  # 'racial-groups'=c('black', 'hispanic', 'other'),
  # 'age-groups'=c('age1', 'age2', 'age3', 'age4', 'age5'),
  # 'risk-groups'=c('msm', 'idu', 'msm_idu', 'heterosexual'),
  'sex'=names(DIMENSION.VALUES[['sex']][['choices']]),
  'racial-groups'=names(DIMENSION.VALUES[['race']][['choices']]),
  'age-groups'=names(DIMENSION.VALUES[['age']][['choices']]),
  'risk-groups'=names(DIMENSION.VALUES[['risk']][['choices']]),    
  'split'='',
  'facet'='',
  'color_by_split_1'=FALSE,    
  
  # Runmodel 6/6: Figure Options
  'plot_format'='individual.simulations',
  'interval_coverage'=95,
  'label_change'=TRUE,
  'change_years'=c(2020, 2030),
  'color_by'='Intervention',
  
  # Page: custom interventions
  'customIntervention_box_switch1'=TRUE,
  'customIntervention_box_switch2'=TRUE,
  'customIntervention_box_switch3'=TRUE,
  'customIntervention_box_switch4'=TRUE,
  'customIntervention_box_switch5'=TRUE
)
config.contents <- list(
  'customInterventions.groups.max'=5)
ci.defaults = customInterventions.demog.defaults()
for (i in config.contents[['customInterventions.groups.max']])
  for (dim in names(ci.defaults))
    defaults[[paste0(dim, i)]] = ci.defaults[[dim]]

# Main ####
##------------------------------##
##-- THE MAIN SERVER FUNCTION --##
##------------------------------##
server <- function(input, output, session) {
  # State, config, cache ####
  state <- reactiveVal(defaults)
  config <- reactiveVal(config.contents)
  data.table <- reactiveVal()
  data.plot <- reactiveVal()
  plot.and.cache = NULL
  
  # Print an initial message - useful for debugging on shinyapps.io servers
  print(paste0("Launching server() function - ", Sys.time()))

  # Make our session cache the cache available to all sessions
  cache = CACHE

  # Page definitions ####  
  output$ui_main = server.routes.runModel.get(input, session, state)
  ui_main_old = server.routes.runModel.old.get(input, session, state)
  output$ui_main_old = ui_main_old
  output$introductionText = server.routes.docs
  output[['design-interventions']] = 
#    renderUI({includeMarkdown('tempCustomHolder.Rmd')}) #This generates a temporary placeholder saying 'coming soon'
    server.routes.designInterventions.get(input, session, config, state)
  output[['help-and-feedback']] = 
    server.routes.helpAndFeedback.get(input)

  # observeEvent(input$geographic_location, {
  #   if (state()[['geographic_location']] != input$geographic_location) {
  #     tempstate = state()
  #     tempstate[['geographic_location']] = input$geographic_location
  #     state(tempstate)
  #   }
  # })
  
  # Events: Simulate & plot ####
  reset.handler = function(input, cache, data.plot) {
    # Validate
    valid = TRUE
    dims = get.dimension.value.options(
      version=version,
      location=input[['geographic_location']])
    invalidInputs = c()
    for (dim in dims)
      if (length(input[[dim$name]]) < 1)
        invalidInputs = c(invalidInputs, dim$label)
    if (length(invalidInputs) > 0)
      valid = FALSE
    
    if (!valid) {
      msg = '<h2>Error: Invalid selections</h2>
      <p>At least one option must be selected in each demographic category. The
      following demographic categories did not have any selections:</p><ul>'
      for (category in invalidInputs)
        msg = paste0(msg, '<li>', category, '</li>')
      msg = paste0(msg, '</ul>')
      showMessageModal(msg)      
    
    } else {
      # Plot & cache
      plot.and.cache <<- generate.plot.and.table(input, cache)
      # This is not needed for diskCache; only mem cache:
      # cache = plot.and.cache$cache
      
      # Update the plot
      data.plot(plot.and.cache$plot)
      output$mainPlot = renderPlotly(plot.and.cache$plot)
      
      # Update the table
      pretty.table = make.pretty.change.data.frame(
        plot.and.cache$change.df, data.type.names=DATA.TYPES)
      data.table(pretty.table)
      output$mainTable = renderDataTable(pretty.table)
      output$mainTable_message = NULL
      
      shinyjs::enable('downloadButton.table')
      shinyjs::enable('downloadButton.plot')
      shinyjs::enable('createPresetId1')      
    }
  }
  
  # Plot in response to action buttons:
  # observeEvent(input$reset_main, {reset.handler(input, cache, data.plot)})
  # observeEvent(input$reset_main_sidebar, {
  #     # shinyjs::runjs("window.scrollTo(0, 0)")
  #     shinyjs::runjs("window.scrollTo({ top: 0, behavior: 'smooth' })")
  #     reset.handler(input, cache, data.plot)
  # })
  
  # - Sync state from input ####
  # - Plot when 'preset' is in the URL
  # observe({
  #   # TODO: Address performance. This is pretty slow locally. Maybe try to trigger
  #   # this only under certain conditions?
  #   # Perhaps I dynamically create a number of specific observables, one for each
  #   # of our apps inputs. I can just iterate over 'defaults', because we have to
  #   # maintain that list anyway.
  #   # # Speed up ideas --
  #   # Joe's ideas:
  #   # 1. dynamically create an observable for every item inside `input`
  #   # 2. only execute the following block of code if the length of `state` and
  #   #  `input` differ. This may cause complication because of soem other keys
  #   #   inside of state
  #   # Todd's ideas:
  #   # 3. Switch from state() related input updates (which we added for the preset
  #   # feature) and change to using these imperative updates, like updateTextInput,
  #   # etc.
  #   # 4. Does simply changing state from reactive val to something else work?
  #   state.valuesUpdated = 0
  #   state.keysUpdated = c()
  #   tempstate = state()
  #   for (key in names(input)) {
  #     if (
  #       !is.null(input[[key]]) &&
  #       !(key %in% state.ignoreList)
  #     )
  #       if (!(key %in% names(tempstate))) {
  #         tempstate[[key]] = input[[key]]
  #         state.valuesUpdated = state.valuesUpdated + 1
  #         state.keysUpdated = c(state.keysUpdated, key)
  #       } else {
  #         # Protects against edge cases w/ lists, e.g.
  #         # ".clientValue-default-plotlyCrosstalkOpts", w/ err:
  #         # Warning: Error in !=: comparison of these types is not implemented
  #         if (any(class(input[[key]]) != 'list'))
  #           if (any(tempstate[[key]] != input[[key]])) {
  #             tempstate[[key]] = input[[key]]
  #             state.valuesUpdated = state.valuesUpdated + 1
  #             state.keysUpdated = c(state.keysUpdated, key)
  #           }
  #       }
  #   }
  #   if (state.valuesUpdated > 0) {
  #     state(tempstate)
  #     print(paste0(
  #       'State: Updated ', state.valuesUpdated,' new values from `input`.'))
  #     # print(state.keysUpdated)
  #   }
  #   
  #   # Require that page be loaded first. We ascertain that by requiring inputs.
  #   # req(input$no_intervention_checkbox)  # doesn't work; arbitrary input won't do
  #   req(input$intervention_1_selector)  # works; because has nested UI?
  #   if (!is.null(state()[['presetId']]))
  #     reset.handler(input, cache, data.plot)
  # })
  
  # Event: Custom interventions ####
  # observeEvent(input$run_custom_interventions, {
  #   # TODO: @tf
  # })
  ##------------------------------------##
  ##-- INTERVENTION SELECTOR HANDLERS --####
  ##------------------------------------##
  
  ##-- LOCATION HANDLER --##
  # observeEvent(input$geographic_location, {
  #   output$mainPlot = renderPlotly(make.plotly.message(BLANK.MESSAGE))
  #   message.df = data.frame(BLANK.MESSAGE)
  #   names(message.df) = NULL
  #   # matrix(BLANK.MESSAGE,nrow=1,ncol=1))
  #   output$mainTable = renderDataTable(message.df)  
  #   output$mainTable_message = renderText(BLANK.MESSAGE)
  # })
  
  # Select All Subgroups: RunModel: selections #
  # observeEvent(input$demog.selectAll, {
  #   if (input$demog.selectAll == 'TRUE') {
  #     dims.namesAndChoices = map(
  #       get.dimension.value.options(
  #         version=version,
  #         location=input[['geographic_location']]), 
  #       function(dim) {
  #         list(
  #           'choices'=names(dim[['choices']]),
  #           'name'=dim[['name']] )
  #       })
  #     for (dim in dims.namesAndChoices) {
  #       updateCheckboxGroupInput(
  #         session, 
  #         inputId=dim[['name']], 
  #         selected=dim[['choices']])
  #     }
  #   }
  # })
  
  # Select All Subgroups: RunModel: enable/disable #
  # observeEvent(input$demog.selectAll, {
  #     checked = input$demog.selectAll
  #     dim.value.options = get.dimension.value.options()
  #     subgroup.checkbox.ids = unname(
  #       sapply(dim.value.options, function(elem){elem$name}))
  #     
  #     if (checked) {
  #       for (i in 1:length(dim.value.options)) {
  #           id = subgroup.checkbox.ids[i]
  #           shinyjs::disable(id)
  #          # updateCheckboxGroupInput(session, inputId=id,
  #          #                         selected=dim.value.options[[i]]$choices)
  #       }
  #     } else
  #       for (id in subgroup.checkbox.ids)
  #           shinyjs::enable(id)
  # })
  
  # Select All Subgroups: Custom interventions ####
  customInts.namesAndChoices = map(
    get.dimension.value.options(
      version=version,
      location=input$geographic_location,
      msm_idu_mode=TRUE), 
    function(dim) {
      list(
        'choices'=names(dim[['choices']]),
        'name'=dim[['name']],
        'shortName'=dim[['shortName']] )
    })
  
  customInts.checkboxIds = c()
  customInts.switchIds = c()
  customInts.dimNames = c()
  for (i in 1:5) {
    for (dim in customInts.namesAndChoices) {
      customInts.switchIds <- c(
        customInts.switchIds, 
        paste0(dim[['name']], '_switch', i))
      customInts.checkboxIds <- c(
        customInts.checkboxIds, 
        paste0(dim[['name']], i))
      customInts.dimNames <- c(
        customInts.dimNames, 
        dim[['shortName']])
    }
  }
  
  # observe({
  #   lapply(1:length(customInts.switchIds), function(i) {
  #     shortName = customInts.dimNames[i]
  #     switchId = customInts.switchIds[i]
  #     checkboxGroupId = customInts.checkboxIds[i]
  #       
  #     observeEvent(input[[switchId]], {
  #         checked = input[[switchId]]
  #         # Update checkboxes
  #         if (checked)
  #           updateCheckboxGroupInput(
  #             session, 
  #             inputId=checkboxGroupId, 
  #             selected=customInts.namesAndChoices[[shortName]][['choices']])
  #         # Enable / disable
  #         if (checked)
  #           shinyjs::disable(checkboxGroupId)
  #         else
  #           shinyjs::enable(checkboxGroupId)
  #       })
  #   })
  # })
  
  # This does not seem to be working - take it out? ####
  # observeEvent(input$plot_format, {
  #     updateKnobInput(
  #       session, 
  #       inputId='interval_coverage',
  #       options = list(readOnly = input$plot_format=='individual.simulations'))
  # })
  
  # Download buttons ####
  output$downloadButton.table <- downloadHandler(
    filename=function() {get.default.download.filename(input, ext='csv')},
    content=function(filepath) {
      write.csv(plot.and.cache$change.df, filepath) 
      } )
  
 #  observeEvent(input$downloadButton.plot, {
 #      width = 1000 #we can fill in a user-specified width in pixels later
 #      height = 650 #ditto
 #      shinyjs::runjs(
 #      paste0("plot=document.getElementById('mainPlot');
 #    Plotly.downloadImage(plot, {format: 'png', width: ", 
 #    width, ", height: ", height, ", 
 #    filename: '", get.default.download.filename(input),"'})"))
 # })
  
  # Custom interventions button ####
  # for now
  output$custom_int_msg_1 = renderText(NO.CUSTOM.INTERVENTIONS.MESSAGE)
  
  # observeEvent(input[['n-custom-interventions-btn']], {
  #   state.temp = state()
  #   state.temp[['n-custom-interventions']] = 
  #     input[['n-custom-interventions']]
  #   state(state.temp)
  #   print('State: updated custom interventions')
  # })
  
  # Preset ID ####
  # observeEvent(input[['createPresetId1']], {
  #   handleCreatePreset(input)
  # })
  # observeEvent(input[['createPresetId2']], {
  #   handleCreatePreset(input)
  # })
  
  # Contact form ####
  observeEvent(input[['feedback_submit']], {
    name = input[['feedback_name']]
    email = input[['feedback_email']]
    contents = input[['feedback_contents']]
    
    # https://r-bar.net/mailr-smtp-webmail-starttls-tls-ssl/#majorHosts
    # https://www.r-bloggers.com/2019/04/mailr-smtp-setup-gmail-outlook-yahoo-starttls/
    # TODO: Handle validation for email addresses, e.g.:
    # Warning: Error in .jcall: org.apache.commons.mail.EmailException: 
    # javax.mail.internet.AddressException: Missing final '@domain' in string
    #  ``askjdfkljfalmvlkgjlkaj''
    #  Warning: Error in .jcall: org.apache.commons.mail.EmailException: 
    #  javax.mail.internet.AddressException: Domain contains illegal character 
    #  in string ``kfjasklklfjlk@lksdjfkldsjfkl@lkdjfjkljlkj''
    showMessageModal('Your message has been sent.')
    
    send.mail(
      from=email, 
      to=c(
        Sys.getenv("EMAIL_USERNAME"),
        'anthony.fojo@jhmi.edu',
        'jflack1@jhu.edu'), 
      subject=paste0('EndingHIV email from: ', name),
      body=paste0(
# Keep indented like this for email formatting purposes.
'Name: ', name, '
Email: ', email, '
Contents: 
', contents),
      smtp=list(
        host.name="smtp.gmail.com",
        port=list(
          'ssl'=465,
          'tls'=587
        )[['tls']],
        user.name=Sys.getenv("EMAIL_USERNAME"),
        passwd=Sys.getenv("EMAIL_PASSWORD"),
        #ssl=T,
        tls=T),
      # debug=T
      authenticate=T, 
      send=T)
  })
  
}
