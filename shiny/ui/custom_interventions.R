make.custom.content <- function(location,
                                web.version.data,
                                create.custom.intervention.unit.selector.function=web.version.data$create.custom.intervention.unit.selector.function)
{

CUSTOM.CONTENT = tags$table(id='custom_table',
                            class='display_table fill_page2', tags$tbody(
    class='display_tbody',
    
##-- HEADERS AND DISPLAY --####
tags$tr(
    #-- Left Header --#
    tags$td(id='left_controls_custom_header',
            class='controls_header_td controls_wide header_color collapsible',
            tags$div(class='controls_wide', 
                     paste0("Specify ", web.version.data$intervention.label)
                     )),
    
    #-- The Main Panel --#
    tags$td(class='display_td content_color', id='display_custom_td',
            rowspan=2,
            tags$div(class='display',
                     create.share.menu('custom'),
                     create.display.panel('custom', web.version.data=web.version.data)        
            ),
            
            #-- ACCORDION BUTTONS --#
            make.accordion.button('custom_collapse_left', 
                                  left.offset ='-10px',
                                  direction='left',
                                  hide.ids=c('custom_collapse_left'),
                                  show.ids='custom_expand_left',
                                  remove.class.ids=c('left_controls_custom','left_custom_cta','left_controls_custom_header'),
                                  add.class.ids=c('left_controls_custom','left_custom_cta','left_controls_custom_header'),
                                  remove.classes='controls_wide',
                                  add.classes='collapsed',
                                  shiny.ids='left_width_custom',
                                  shiny.values=0,
                                  visible=T
            ),
            bsTooltip('custom_collapse_left', paste0('Hide ', web.version.data$intervention.label, ' Selection'), placement='right'),
            
            make.accordion.button('custom_expand_left', 
                                  left.offset='0px',
                                  direction='right',
                                  show.ids=c('custom_collapse_left'),
                                  remove.class.ids=c('left_controls_custom','left_custom_cta','left_controls_custom_header'),
                                  add.class.ids=c('left_controls_custom','left_custom_cta','left_controls_custom_header'),
                                  remove.classes='collapsed',
                                  add.classes='controls_wide',
                                  shiny.ids='left_width_custom',
                                  shiny.values=LEFT.PANEL.SIZE['custom'],
                                  visible=F
            ),  
            make.popover('custom_expand_left', 
                         paste0('Show ', web.version.data$intervention.label, ' Selection'),
                         paste0('Click for controls to select ', 
                                web.version.data$intervention.label.article, ' ', 
                                tolower(web.version.data$intervention.label)),
                         placement='right'),
            
            
            make.accordion.button('custom_collapse_right', 
                                  right.offset ='-10px',
                                  direction='right',
                                  show.ids=c('prerun_expand_right','custom_expand_right'),
                                  hide.ids=c('prerun_collapse_right','custom_collapse_right'),
                                  remove.class.ids=c('right_controls_prerun','right_prerun_cta','right_controls_prerun_header',
                                                    'right_controls_custom','right_custom_cta','right_controls_custom_header'),
                                  add.class.ids=c('right_controls_prerun','right_prerun_cta','right_controls_prerun_header',
                                                  'right_controls_custom','right_custom_cta','right_controls_custom_header'),
                                  remove.classes='controls_narrow',
                                  add.classes='collapsed',
                                  shiny.ids=c('right_width_prerun','right_width_custom'),
                                  shiny.values=0,
                                  visible=F
            ),
            bsTooltip('custom_collapse_right', 'Hide Figure Settings', placement='left'),
            
            make.accordion.button('custom_expand_right', 
                                  right.offset='0px',
                                  direction='left',
                                  show.ids=c('prerun_collapse_right','custom_collapse_right'),
                                  hide.ids=c('prerun_expand_right','custom_expand_right'),
                                  remove.class.ids=c('right_controls_prerun','right_prerun_cta','right_controls_prerun_header',
                                                     'right_controls_custom','right_custom_cta','right_controls_custom_header'),
                                  add.class.ids=c('right_controls_prerun','right_prerun_cta','right_controls_prerun_header',
                                                  'right_controls_custom','right_custom_cta','right_controls_custom_header'),
                                  remove.classes='collapsed',
                                  add.classes='controls_narrow',
                                  shiny.ids=c('right_width_prerun','right_width_custom'),
                                  shiny.values=c(RIGHT.PANEL.SIZE['prerun'], RIGHT.PANEL.SIZE['custom']),
                                  visible=T
            ),  
            make.popover('custom_expand_right', 'Show Figure Settings',
                         'Click for controls to adjust what is plotted in the figures.',
                         placement='left')
            
            
            ),
    
    #-- Right Header --#
    tags$td(id='right_controls_custom_header',
            class='controls_header_td header_color collapsible collapsed',
            tags$div(class='controls_narrow', "Figure Settings"))
), #</tr>

##-- CONTROL PANELS --####
tags$tr(
    
    #-- The Left Panel --#
    tags$td(id='left_controls_custom',
            class='controls_td controls_wide controls_color collapsible',
            tags$div(class='controls controls_wide',
                              create.location.input(location=location,
                                                    web.version.data=web.version.data,
                                                    suffix='custom',
                                                    inline=T,
                                                    popover=T),

                     tags$div(id='n_subpop_panel',
                              inline.select.input(inputId='n_subpops',
                                                  label=paste0('How Many Distinct Subgroups to Target ', web.version.data$intervention.label,'s To:'),
                                                  choices=1:MAX.N.SUBPOPULATIONS,
                                                  width='60px',
                                                  selectize=F)
                     ),
                     make.popover('n_subpop_panel',
                                  title="Number of Target Subgroups",
                                  content=paste0("Select the number of different subgroups to which you want to deliver a different ", 
                                                 tolower(web.version.data$intervention.label), 
                                                 " Each subgroup can have a distinct ",
                                                 tolower(web.version.data$intervention.label),
                                                 " applied. Once you have chosen the number, specify the details for each subgroup below."),
                                  placement='right'),
                     
                     HTML(paste0('<strong>Specify ', web.version.data$intervention.label, ' for Subgroup:</strong>')),
                              
                     do.call(tabsetPanel,
                             c(list(id='custom_tabset_panel', type='pills'),
                               lapply(1:MAX.N.SUBPOPULATIONS, function(i){
                                   tabPanel(title=i,  
                                            value=i,
                                            wellPanel(style = "padding: 10px; padding-right:5px",
                                                      tags$table(class='specify_custom',
                                                                 tags$tr(
                                                                     tags$th(paste0("Subgroup ", i, " Characteristics:")),
                                                                     tags$th(paste0(web.version.data$intervention.label, " Components:"))
                                                                 ),
                                                                 tags$tr(
                                                                     tags$td(create.custom.tpop.box(i)),
                                                                     tags$td(create.custom.intervention.unit.selector.function(i, web.version.data))
                                                                 )
                                                      )
                                            ) #</wellPanel>
                                   ) #</tabPanel>
                               }))
                             ), #</tabsetPanel>

                    # A spacer so drop-down from suppression does not extend below end of element
                    HTML(paste0(rep("<BR>", length(SUPPRESSION.OPTIONS)-1), collapse=''))
                    
            ) #</div class=controls>
    ),  # </td>
    
    #-- The Right Panel --#
    tags$td(id='right_controls_custom',
            class='controls_td controls_color collapsible collapsed',
            create.plot.control.panel('custom',
                                      web.version.data=web.version.data)
    )
    
), #</tr>


##-- CTA BUTTONS --##
tags$tr(
    
    #-- Left panel button --#
    tags$td(id='left_custom_cta',
            class='cta_td controls_wide cta_background_color collapsible',
            tags$div(class='controls_wide cta_sub_td', 
                     
                     tags$table(class='cta_text_wrapper', tags$tr(
                         tags$td(
                             actionButton(class='cta cta_color', inputId='run_custom', label=paste0('Simulate ', web.version.data$intervention.label))
                         ),
                         tags$td(class='cta_text',
                                 HTML("This will take 2-5 minutes<BR>
                              <input type='checkbox' id='chime_run_custom' name='chime_run_custom' style='float: left'>
                              <label for='chime_run_custom'>&nbsp;Play a chime when done</label>")
                         )
                     ))
            ),
    ),
    
    #-- Under Display --#
    
    tags$td(id='under_display_custom',
            class='under_display_td content_color',
            create.projected.intervention.panel(suffix='custom', web.version.data = web.version.data)
    ),
    
    #-- Right panel button --#
    tags$td(id='right_custom_cta',
            class='cta_td cta_background_color collapsible collapsed',
            tags$div(class='controls_narrow cta_sub_td', 
                actionButton(class='cta cta_color', inputId='redraw_custom', label='Adjust Projections'))
            )
    
) #</tr>

)) #</tbody></table>

CUSTOM.CONTENT
}