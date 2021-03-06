

##----------------------##
##-- CREATE THE PANEL --##
##----------------------##

create.intervention.selector.panel <- function(suffix,
                                               lump.idu=T)
{
    # Make the Aspect Selector
    aspect.selector = make.intervention.aspect.selector(INTERVENTION.LIST,
                                                        suffix=suffix,
                                                        include.none=T)
    
    # Make the Target Population Selector
    tpop.selector = conditionalPanel(condition=paste0("input.int_aspect_", suffix," != 'none'"),
                                     make.intervention.tpop.selector(INTERVENTION.LIST,
                                                                     suffix=suffix))
    
    # Make the Final Selector
    final.selector = make.intervention.final.selector(INTERVENTION.LIST,
                                                      suffix=suffix)
    
    
    # Put it all together and return
    tags$div(
        fluidRow(aspect.selector),
        fluidRow(tpop.selector),
        fluidRow(final.selector)
    )
}

##---------------------------------------------##
##-- GETTING/SETTING INPUT FROM/TO THE PANEL --##
##---------------------------------------------##

get.intervention.selection <- function(input, suffix)
{
    aspect.selection = input[[paste0("int_aspect_", suffix)]]
    if (is.null(aspect.selection) || aspect.selection=='none')
        NULL
    else
    {
        tpop.selection = input[[paste0("int_tpop_", suffix)]]
        final.selector.id = paste0('int_', tpop.selection, "_", aspect.selection, "_", suffix)
        input[[final.selector.id]]
    }
}

set.intervention.selection <- function(session, suffix, int.code)
{
    mask = INTERVENTION.LIST$intervention.code == int.code

    if (is.null(int.code) || !any(mask))
        updateRadioButtons(session, 
                           inputId = paste0("int_aspect_", suffix), 
                           selected = 'none')
    else
    {
        index = (1:length(mask))[mask][1]
        
        # Aspect
        aspect.selection = INTERVENTION.LIST$unit.type.code[index]
        updateRadioButtons(session,
                           inputId = paste0("int_aspect_", suffix),
                           selected = aspect.selection)
        
        # Target Population
        tpop.selection = INTERVENTION.LIST$target.population.index[index]
        updateRadioButtons(session,
                           inputId = paste0("int_tpop_", suffix),
                           selected = tpop.selection)
        
        # Final
        final.selector.id = paste0('int_', tpop.selection, "_", aspect.selection, "_", suffix)
        updateRadioButtons(session,
                           inputId = final.selector.id,
                           selected = int.code)
    }
}

##----------------------------------##
##-- HELPERS FOR MAKING THE PANEL --##
##----------------------------------##

make.intervention.aspect.selector <- function(int.list,
                                              suffix,
                                              include.none=T)
{
    unique.unit.types = unique(int.list$unit.type)
    
    unit.choice.values = lapply(unique.unit.types, unit.type.code)
    
    unit.choice.names = lapply(unique.unit.types, unit.types.to.pretty.name)
    
    unit.choice.values = c(list('none'), unit.choice.values)
    unit.choice.names = c(list('None'), unit.choice.names)
    
    names(unit.choice.values) = names(unit.choice.names) = NULL
    
    
    tags$div(
        radioButtons(inputId = paste0('int_aspect_', suffix),
                     label='Which Aspects to Intervene On:',
                     choiceNames=unit.choice.names,
                     choiceValues=unit.choice.values,
                     selected='none'
        ),
        
        make.popover(paste0('int_aspect_', suffix),
                     title='What Should the Intervention Affect?',
                     content="You can choose interventions that affect HIV testing, PrEP uptake among those at risk for HIV acquisition, viral suppression among PWH, or a combination of all three.",
                     placement='right')
    )
}

make.intervention.tpop.selector <- function(int.list,
                                            suffix)
{
    tpop.choice.names = lapply(int.list$unique.target.population.codes, function(codes){
        target.population.codes.to.pretty.name(codes)
    })

    tpop.choice.values = 1:length(int.list$unique.target.population.codes)
    
    names(tpop.choice.names) = names(tpop.choice.values) = NULL
    
    
    tags$div(
        radioButtons(inputId = paste0('int_tpop_', suffix),
                     label='Target Subgroup(s):',
                     choiceNames=tpop.choice.names,
                     choiceValues=tpop.choice.values,
                     selected=tpop.choice.values[1]
                     ),
        
        make.popover(paste0('int_tpop_', suffix),
                     title='What Subgroups Should the Intervention Target?',
                     content="Choose which population subgroups the intervention should be deployed in.",
                     placement='right')
    )
}

make.intervention.final.selector <- function(int.list,
                                             suffix)
{
    unique.unit.type.codes = unique(int.list$unit.type.code)
    
    selectors = lapply(1:length(int.list$unique.target.population.codes), function(tpop.index){
        lapply(unique.unit.type.codes, function(unit.type.code){
            
            mask = int.list$target.population.index == tpop.index &
                int.list$unit.type.code == unit.type.code
            
            choice.values = int.list$intervention.code[mask]
            choice.names = lapply(int.list$intervention.lumped.idu[mask], intervention.brief.description)
            choice.names = lapply(choice.names, function(name){tags$div(lump.idu.in.name(name))})
            names(choice.names) = names(choice.values) = NULL
            
            id = paste0('int_', tpop.index, "_", unit.type.code, "_", suffix)
            radios = radioButtons(inputId=id,
                         label='Intensity of Interventions:',
                         choiceNames=choice.names,
                         choiceValues=choice.values,
                         selected=choice.values[1])
            
            conditionalPanel(
                condition = paste0("input.int_aspect_", suffix," == '", unit.type.code, "' && input.int_tpop_", suffix, " == ", tpop.index),
                radios,
                
                make.popover(id,
                             title='What Intensity of Interventions Should be Applied?',
                             content="Choose the specific levels of HIV testing, PrEP uptake among those at risk for HIV acquisition, and/or viral suppression among PWH to apply to the targeted subgroups.",
                             placement='right')
            )
            
        })
    })
    
    do.call(tags$div, selectors)
}


##-------------##
##-- HELPERS --##
##-------------##

##-- READING THE INTERVENTION LIST --##

#returns a list with two elements
# $location - a vector of location ids
# $intervention - a list of interventions
get.interventions.list <- function(include.no.intervention=F,
                                   disregard.location=T,
                                   lump.idu=T)
{
    rv = get.prerun.intervention.codes()   

    if (disregard.location)
        rv = list(intervention.code = unique(rv$intervention.code))

    rv$intervention = lapply(rv$intervention.code, intervention.from.code)
    
    if (!include.no.intervention)
    {
        mask = !sapply(rv$intervention, is.null.intervention)
        rv$intervention = rv$intervention[mask]
        rv$intervention.code = rv$intervention.code[mask]
        rv$location = rv$location[mask]
    }
    
    o = order.interventions(rv$intervention)
    rv$intervention = rv$intervention[o]
    rv$intervention.code = rv$intervention.code[o]
    rv$location = rv$location[o]
    
    rv$unit.type = lapply(rv$intervention, function(int){
        sort(get.intervention.unit.types(int))
    })
    rv$unit.type.code = sapply(rv$unit.type, unit.type.code)
 #   rv$unique.unit.type.codes = unique(rv$unit.type.code)
    
    if (lump.idu)
        rv$intervention.lumped.idu = lapply(rv$intervention, lump.idu.for.intervention)
    else
        rv$intervention.lumped.idu = rv$interventions
    
    rv$target.population.code = lapply(
        rv$intervention.lumped.idu, function(int) {
            sapply(
                get.target.populations.for.intervention(int), 
                target.population.to.code)
        })
    
    rv$unique.target.population.codes = unique(rv$target.population.code)
    rv$target.population.index = sapply(rv$target.population.code, function(tpop1){
        mask = sapply(rv$unique.target.population.codes, function(tpop2){
            setequal(tpop1, tpop2)
        })
        (1:length(rv$unique.target.population.codes))[mask]
    })
    
    
    rv
}

##-- UNIT TYPE --##

unit.types.to.pretty.name <- function(unit.types)
{
    unit.types = get.pretty.unit.type.names(unit.types)
    if (length(unit.types)==1)
        paste0(unit.types, " only")
    else if (length(unit.types)==2)
        paste0(unit.types[1], " and ", unit.types[2])
    else
        paste0(paste0(unit.types[-length(unit.types)], collapse=", "),
               ", and ", unit.types[length(unit.types)])
}

unit.type.code <- function(unit.types)
{
    paste0(unit.types, collapse="_")
}


##-- INTERVENTION --##

intervention.brief.description <- function(int, include.start.text=F)
{
    HTML(get.intervention.description.by.target(int, 
                                                include.start.text=include.start.text,
                                                pre="<table>",
                                                post="</table>",
                                                bullet.pre = "<tr><td style='vertical-align: text-top; word-wrap:break-word;'>&#149;&nbsp;</td><td>",
                                                bullet.post = "</td></tr>",
                                                tpop.delimeter = '',
                                                unit.delimiter = ', ',
                                                pre.header = "<u>",
                                                post.header = ":</u> "
    ))
}

##-- TARGET POPULATION --##

target.population.codes.to.pretty.name <- function(tpop.codes)
{
    if (length(tpop.codes)==1 && tpop.codes=='none')
    {
        bullet = ''
        content = 'None'
    }
    else
    {
        bullet = paste0("<td style='vertical-align: text-top;'>&#149;&nbsp;&nbsp;</td>")
        tpops = lapply(tpop.codes, target.population.from.code)
        content = sapply(tpops, function(tpop){
            lump.idu.in.name(target.population.name(tpop))})
    }
    #paste0("", paste0("&#149; ", sapply(tpops, target.population.name), collapse='<BR>'), "")
    HTML(paste0("<table>",
                paste0("<tr>",
                       bullet,
                       "<td style='text-align: left'>",
                       content,
                       "</td></tr>", collapse=''), 
                "</table>"))
}




##----------------------------------##
##-- SET UP THE INTERVENTION LIST --##
##----------------------------------##


# Make and save the intervention list to be universally available
#  Note - this is executed on launching the app
print("Making Intervention List")
INTERVENTION.LIST = get.interventions.list(disregard.location=T) 
#for now, we just assume that every location has every intervention
# and just assume that every location has every intervention