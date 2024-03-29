
##-----------------------------------##
##-- CONSTRUCTOR FOR THE PANEL GUI --##
##-----------------------------------##

create.plot.control.panel <- function(suffix, web.version.data)
{
    year.options = get.year.options(web.version.data$name)
    
    plot.statistic.choices = PLOT.STATISTIC.OPTIONS$names
    names(plot.statistic.choices) = PLOT.STATISTIC.OPTIONS$values

    tags$div(
        class='controls controls_narrow',
        
        
        checkboxGroupInput(inputId = paste0('outcomes_', suffix),
                           label = "Outcomes",
                           choiceValues = OUTCOME.OPTIONS$values,
                           choiceNames = OUTCOME.OPTIONS$names,
                           selected = OUTCOME.OPTIONS$values[1:2]),
        make.popover(paste0('outcomes_', suffix),
                     title='Epidemiological Outcomes to Display',
                     content="Select the epidemiological outcomes for which to display projections.",
                     placement='left'),
        
        checkboxGroupInput(inputId = paste0('facet_by_', suffix),
                           label = "Separate Projections By:",
                           choiceValues = DIMENSION.OPTIONS.1$values,
                           choiceNames = DIMENSION.OPTIONS.1$names,
                           selected = c()),
        make.popover(paste0('facet_by_', suffix),
                     title='Make Separate Panels by Subgroup',
                     content="Make a separate panel for each combination of the selected attributes. (Note: clicking more than two attributes is going to make a LOT of panels)",
                     placement='left'),
        
        
        tags$div(id=paste0('show_change_panel_', suffix),
                 tags$b('Summarize the Outcomes As:'),
                 
                  tags$table(class='table_select',
                    tags$tr(
                     # tags$td("As:"),
                      tags$td(colspan=2,
                        selectInput(inputId = paste0('plot_statistic_', suffix),
                                          label = NULL,
                                          width = '95%',
                                          choices = plot.statistic.choices,
                                          selected = web.version.data$default.plot.statistic,
                                          selectize = F))
                    ),       
                    tags$tr(
                      tags$td("from:"),
                      tags$td(selectInput(inputId = paste0('change_from_', suffix),
                                         label = NULL,
                                         width = '120px',
                                         choices = year.options$values[year.options$values<max(year.options$values)],
                                         selected = min(year.options$values[1]),
                                         selectize = F))
                    ),
                    tags$tr(
                      tags$td("to:"),
                      tags$td(selectInput(inputId = paste0('change_to_', suffix),
                                          label = NULL,
                                          width='120px',
                                          choices = year.options$values[-1],
                                          selected = max(year.options$values),
                                          selectize = F))
                    )
                 ), #</table>
                 
                 tags$div(class='squish_up',
                     checkboxInput(
                         inputId = paste0('show_change_', suffix),
                         label='Label this change on the figure',
                         value=T
                     ) #</div>
                 )
             ), #</div>
         
        make.popover(paste0('show_change_panel_', suffix),
                     title='Summarize the Outcomes Over Time',
                     content="Decide how and over what time to summarize the outcomes (as a change over time, cumulative sum, or change from baseline) in the figure and table.",
                     placement='left'),

        tags$div(style='height: 20px;'),
        
 #       tags$div(style='margin-right:-5px; margin-left:-5px',
 #       box(title='Advanced Options',
 #           status = 'info',
 #           solidHeader = T,
 #           width=12,
 #           collapsible = T,
 #           collapsed=T,
            
            #-- Plot Format --#
            radioButtons(inputId = paste0('plot_format_', suffix),
                         label='What to Show for Projections:',
                         choiceNames=PLOT.FORMAT.OPTIONS$names,
                         choiceValues=PLOT.FORMAT.OPTIONS$values,
                         selected=PLOT.FORMAT.OPTIONS$values[1]),
            make.popover(paste0('plot_format_', suffix),
                         title='What to Show in the Plot',
                         content="Each figure and table is a synthesis of 80 individual simulations. You can either show the mean and credible interval across these simulations, or you can plot a line for each individual simulation.",
                         placement='left'),
            
            #-- Split By --#
            # (we're no longer using this)
#            checkboxGroupInput(inputId = paste0('split_by_', suffix),
 #                              label = "Plot a Separate Line for Each:",
  #                             choiceValues = DIMENSION.OPTIONS.1$values,
   #                            choiceNames = DIMENSION.OPTIONS.1$names,
    #                           selected = c()),
     #       make.popover(paste0('split_by_', suffix),
      #                   title='Make Separate Lines by Subgroup',
       #                  content="Within each panel, plot a separate line for each combination of the selected attributes. (Note: clicking more than one attribute is going to make a LOT of lines)",
        #                 placement='left'),
        
#        ) #</box>
#        ) #</div>
    )
    
    
}

##-----------------------------------------------##
##-- EVENT HANDLERS FOR UPDATING PLOT CONTROLS --##
##-----------------------------------------------##

add.control.event.handlers <- function(session, input, output, cache, suffix)
{   
    change.from.id = paste0('change_from_', suffix)
    change.to.id = paste0('change_to_', suffix)
    add.year.range.dropdown.handler(session, input,
                                    change.from.id, change.to.id,
                                    min.delta=1)
}


add.year.range.dropdown.handler <- function(session, input,
                                            from.id, to.id,
                                            min.delta,
                                            years = get.year.options(get.web.version(input))$values)
{
    observeEvent(input[[from.id]], {
        prev.to = input[[to.id]]
        min.year = as.numeric(input[[from.id]]) + min.delta
        new.choices = years[years >= min.year]
        updateSelectInput(session,
                          inputId = to.id,
                          choices = new.choices,
                          selected = max(prev.to, min(new.choices))
        )
    })
}

update.year.range.dropdown <- function(session,
                                       input,
                                       id1, value1,
                                       id2, value2)
{
    observeEvent(input[[id1]], {
        updateSelectInput(session,
                          inputId = id2,
                          selected = value2)
    },
    priority=-1,
    once=T)
    
    updateSelectInput(session,
                      inputId = id1,
                      selected = value1)
    
}

##-----------------------------##
##-- CONTROL SETTINGS OBJECT --##
##-----------------------------##

get.control.settings <- function(input, suffix)
{
    list(
        years=get.selected.years(input, suffix),
        data.types=get.selected.outcomes(input, suffix),
        facet.by=get.selected.facet.by(input, suffix),
        split.by=get.selected.split.by(input, suffix),
        dimension.subsets=get.selected.dimension.subsets(input, suffix),
        plot.format=get.selected.plot.format(input, suffix),
        plot.statistic=get.selected.plot.statistic(input, suffix),
        plot.interval.coverage = get.selected.interval.coverage(input, suffix),
        label.change = get.selected.show.change(input, suffix),
        change.years = get.selected.change.years(input, suffix)
    )
}

set.controls.to.settings <- function(session,
                                     input,
                                     suffix,
                                     settings)
{
    set.selected.years(session, suffix, years = settings$years)
    set.selected.outcomes(session, suffix, outcomes = settings$data.types)
    set.selected.facet.by(session, suffix, facet.by = settings$facet.by)
    set.selected.split.by(session, suffix, split.by = settings$split.by)
    set.selected.dimension.subsets(session, suffix, dimension.subsets = settings$dimension.subsets)
    set.selected.plot.format(session, suffix, plot.format = settings$plot.format)
    set.selected.plot.statistic(session, suffix, plot.statistic = settings$plot.statistic)
    set.selected.interval.coverage(session, suffix, interval.coverage = settings$plot.interval.coverage)
    set.selected.show.change(session, suffix, show.change = settings$label.change)
    set.selected.change.years(session, input, suffix, change.years = settings$change.years)
}

#puts into a key-value list for analytics to upload
control.settings.to.trackable <- function(control.settings, web.version.data)
{
  rv = list(
    show.years=paste0(control.settings$years, collapse=ANALYTICS.DELIMITER),
    outcomes = paste0(control.settings$data.types, collapse=ANALYTICS.DELIMITER),
    facet.by = paste0(control.settings$facet.by, collapse=ANALYTICS.DELIMITER),
    split.by = paste0(control.settings$split.by, collapse=ANALYTICS.DELIMITER),
    plot.statistic = control.settings$plot.statistic,
    change.outcome.start = control.settings$change.years[1],
    change.outcome.end = control.settings$change.years[2],
    show.change = control.settings$label.change,
    plot.format = control.settings$plot.format,
    show.ages = paste0(control.settings$dimension.subsets$age, collapse=ANALYTICS.DELIMITER),
    show.races = paste0(control.settings$dimension.subsets$race, collapse=ANALYTICS.DELIMITER),
    show.sexes = paste0(control.settings$dimension.subsets$sex, collapse=ANALYTICS.DELIMITER),
    show.risks = paste0(control.settings$dimension.subsets$risk, collapse=ANALYTICS.DELIMITER),
    plot.interval.coverage = control.settings$plot.interval.coverage
  )
  
  rv
}


get.main.settings <- function(input,
                              suffix)
{
    list(
#        version = get.version(),
        location = get.selected.location(input, suffix)
    )
}

set.main.to.settings <- function(session,
                                 suffix,
                                 settings)
{
 #   set.version(session, suffix, version=setting$version)
    set.selected.location(session, suffix, settings$location)
}


##-------------------------##
##-- GETTERS and SETTERS --##
##-------------------------##

# Hard-coded for now
get.version <- function(input, suffix)
{
    stop("get.version is deprecated")
    '1.0'
}

set.version <- function(session, suffix, version)
{
    stop('set.version is deprecated')
    # Do nothing - this is hard coded
}


get.selected.location <- function(input, suffix)
{
    input[[paste0("location_", suffix)]]
}

set.selected.location <- function(session, suffix, location)
{
    updateSelectInput(session, paste0('location_', suffix), selected=location)
}


get.selected.years <- function(input, suffix)
{
    web.version.data = get.web.version.data(get.web.version(input))
    web.version.data$min.pre.intervention.year:web.version.data$max.intervention.year
}

set.selected.years <- function(session, suffix, years)
{
    # Do nothing - this is hard coded
}


get.selected.outcomes <- function(input, suffix)
{
    input[[paste0('outcomes_', suffix)]]
}

set.selected.outcomes <- function(session, suffix, outcomes)
{
    updateCheckboxGroupInput(session,
                             inputId = paste0('outcomes_', suffix),
                             selected = outcomes)
}


get.selected.facet.by <- function(input, suffix)
{
    input[[paste0('facet_by_', suffix)]]
}

set.selected.facet.by <- function(session, suffix, facet.by)
{
    updateCheckboxGroupInput(session,
                             inputId = paste0('facet_by_', suffix),
                             selected = facet.by)
}


get.selected.split.by <- function(input, suffix)
{
    #for now, hard-coded
    NULL
#    input[[paste0('split_by_', suffix)]]
}

set.selected.split.by <- function(session, suffix, split.by)
{
    # Do nothing - hard coded
  
#    updateCheckboxGroupInput(session,
 #                            inputId = paste0('split_by_', suffix),
  #                           selected = split.by)
}


get.selected.dimension.subsets <- function(input, suffix)
{
    ALL.DIMENSION.VALUES
}

set.selected.dimension.subsets <- function(session, suffix, dimension.subsets)
{
    # Do nothing - this is hard coded
}


get.selected.plot.statistic <- function(input, suffix)
{
    input[[paste0('plot_statistic_', suffix)]]
}

set.selected.plot.statistic <- function(session, suffix, plot.statistic)
{
    updateSelectInput(session,
                       inputId = paste0('plot_statistic_', suffix),
                       selected = plot.statistic)
}


get.selected.plot.format <- function(input, suffix)
{
    input[[paste0('plot_format_', suffix)]]
}

set.selected.plot.format <- function(session, suffix, plot.format)
{
    updateRadioButtons(session,
                       inputId = paste0('plot_format_', suffix),
                       selected = plot.format)
}


get.selected.interval.coverage <- function(input, suffix)
{
    0.95
}

set.selected.interval.coverage <- function(session, suffix, interval.coverage)
{
    # Do nothing - this is hard coded
}


get.selected.show.change <- function(input, suffix)
{
    input[[paste0('show_change_', suffix)]]
}

set.selected.show.change <- function(session, suffix, show.change)
{
    updateCheckboxInput(session,
                        inputId = paste0('show_change_', suffix),
                        value = show.change)
}


get.selected.change.years <- function(input, suffix)
{
    as.numeric(c(input[[paste0('change_from_', suffix)]],
                 input[[paste0('change_to_', suffix)]]))
}

set.selected.change.years <- function(session, input, suffix, change.years)
{
    update.year.range.dropdown(session, input,
                               id1 = paste0('change_from_', suffix),
                               value1 = change.years[1],
                               id2 = paste0('change_to_', suffix),
                               value2 = change.years[2])
}