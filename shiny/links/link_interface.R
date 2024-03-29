LINK.BUCKET = 'endinghiv.links'
DOMAIN.NAME = 'www.jheem.org'

library(shinybusy)

##--------------##
##-- MAKE URL --##
##--------------##

make.link.url <- function(link)
{
    paste0(DOMAIN.NAME, "?", link)
}

##---------------------------##
##-- CREATING LINK OBJECTS --##
##---------------------------##

create.link <- function(type = c('prerun','custom')[1],
                        plot.and.table)
{
    list(type=type,
         intervention.codes=plot.and.table$intervention.codes,
         main.settings=plot.and.table$main.settings,
         control.settings=plot.and.table$control.settings,
         intervention.settings=plot.and.table$int.settings,
         web.version=plot.and.table$web.version,
         time=Sys.time())
}

# returns the link id, or NULL if there was an error
save.link <- function(session, plot.and.table, suffix, cache)
{
    if (suffix=='custom')
    {
        filename = get.intervention.filenames(plot.and.table$intervention.codes,
                                              version=plot.and.table$main.settings$version, 
                                              location=plot.and.table$main.settings$location)
        
        if (!is.sim.stored(filename))
        {
            show_modal_spinner(session=session,
                               text=HTML('<div class="uploading_custom"><h1>Uploading Simulation File to Remote Server...</h1><h2>(This will take 10-20 seconds)</h2></div>'),
                               spin='bounce')
            tryCatch({
                    simset = get.simsets.from.cache(filename, cache)[[1]]
                    
                    sims.save(simset=simset,
                              filename = filename)
                    
                    remove_modal_spinner(session)
                },
                error=function(e){
                    log.error(e)
                    remove_modal_spinner(session)
                    show.error.message(session,
                                       title='Error Creating Link',
                                       message='There was an error uploading the simulation files to the remote server. We apologize, but we are unable to generate a link at this time. Please try again after a few minutes.')
                    return (NULL)
                }  
            )
        }
    }
    #if intervention not uploaded
    # upload intervention
    
    # Generate a link
    tryCatch({
        id = get.new.link.id()
        link.obj = create.link(type=suffix, plot.and.table)
        
        set.link.data(id, link.obj)
        
        id
    },
    error = function(e){
        log.error(e)
        show.error.message(session,
                           title="Error Creating Link",
                           message = "There was an error saving the data to generate a link. We apologize. Please try again after a few minutes.")
        NULL
    })
}


##---------------------##
##-- INTERFACE TO S3 --##
##---------------------##

get.link.data <- function(id)
{
    tryCatch({
        filename = paste0(id, '.Rdata')
        s3load(filename, bucket=LINK.BUCKET)
        
        if (is.null(data$web.version))
            data$web.version = DEFAULT.WEB.VERSION
        
        data
    },
    error=function(e){
        NULL
    })
}

set.link.data <- function(id, data)
{
    filename = paste0(id, '.Rdata')
    s3save(data, object=filename, bucket=LINK.BUCKET)
}

link.exists <- function(id)
{
    filename = paste0(id, '.Rdata')
    x = get_bucket(bucket=LINK.BUCKET,
                   prefix=filename)
    x.names = sapply(x, function(z) {z$Key} )
    any(x.names == filename)
}

get.new.link.id <- function(len=5)
{
    choices = 'ABCDEFGHIJKLMNOPQRSTUWXYZ0123456789' #no v as special character
    id = NULL
    
    while(is.null(id))
    {
        indices = ceiling(runif(len, .000001, nchar(choices)))
        chars = sapply(indices, function(i){substr(choices, i, i)})
        id = paste0(chars, collapse='')
        
        if (link.exists(id))
            id = NULL
    }
    
    id
}