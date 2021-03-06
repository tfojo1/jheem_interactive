
get.default.download.filename <- function(plot.and.table,
                                          ext='')
{
    if (ext != '' && !grepl("^\\.", ext))
        ext = paste0(".", ext)
    
    if (length(plot.and.table$control.settings$facet.by)==0 && length(plot.and.table$control.settings$split.by)==0)
        by.suffix = ''
    else
        by.suffix = paste0(" by ",
                           paste0(unique(c(plot.and.table$control.settings$facet.by,
                                           plot.and.table$control.settings$split.by)), 
                                  collapse=', ')
        )
    
    paste0(get.location.short.name(plot.and.table$main.settings$location), " - ",
           paste0(WEB.DATA.TYPE.NAMES[plot.and.table$control.settings$data.types], collapse=", "),
           by.suffix,
           ext)
}

download.plot <- function(plot.and.table, input, suffix)
{
    figure.size = get.figure.size(plot.and.table,
                                  input=input, 
                                  suffix=suffix)
    
    js$download_plotly(id = get.plot.id(suffix),
                       width = figure.size$width,
                       height = figure.size$height,
                       filename = get.default.download.filename(plot.and.table,
                                                                ext=''))
}

# https://plotly.com/javascript/static-image-export/#saving-as-png

