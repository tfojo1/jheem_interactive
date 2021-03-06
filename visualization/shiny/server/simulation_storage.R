library(aws.iam)
library(aws.s3)

BUCKET.NAME.SIMS = 'endinghiv.sims'
CUSTOM.PREFIX = 'CSTM.'

##--------------------------------------------------------------##
##-- HIGHER-LEVEL FUNCTIONS THAT MOVE FILES AND SHOW PROGRESS --##
##--------------------------------------------------------------##

# Returns true if success, false otherwise
pull.files.to.cache <- function(session, filenames, cache)
{
    filenames = filenames[!are.simsets.in.disk.cache(filenames, cache) &
                            !are.simsets.in.cache.directory(filenames, cache) &
                              !are.simsets.in.explicit.cache(filenames, cache)]
    success = T
    #-- Pre-fetch the simsets --#
    if (length(filenames)>0)
    {
        #      print(paste0('need to fetch: ', paste0(filenames, collapse=', ')))
        if (length(filenames)==1)
            msg = "Fetching 1 Simulation File from Remote Server:"
        else
            msg = paste0("Fetching ", length(filenames), 
                         " Simulation Files from Remote Server:")
        withProgress(
            message=msg, min=0, max=1, value=0.2/length(filenames),
            detail=paste("Fetching file 1 of ", length(filenames)),
            {
                for (i in 1:length(filenames))
                {
                    if (success)
                    {
                        if (i>1)
                            setProgress(
                                (i-1)/length(filenames),
                                detail=paste("Fetching file ", i, " of ", 
                                             length(filenames)))
                        filename = filenames[i]
                        success = pull.simsets.to.cache(session, filename, cache)
                    }
                }
                setProgress(1, detail='Done')
            })
    }
    
    return (success)
}


##-------------------------------------##
##-- THE FOUR S3 INTERFACE FUNCTIONS --##
##-------------------------------------##

sims.list <- function(
    version='1.0',
    include.location=F,
    include.version=F,
    bucket.name=BUCKET.NAME.SIMS) 
{
    rv = s3.list(bucket.name,
                 dir=version,
                 full.path=include.version)
    
    if (!include.version && !include.location)
    {
        split = strsplit(rv, '/')
        rv = sapply(split, function(one.split){
            paste0(one.split[-1], collapse='/')
        })
    }
    
    rv
}

sims.load <- function(filename)
{
    full.filename = get.filename.for.s3(filename)

 #   progress = function(...){
  #      print("I hacked it")
   #     httr::progress(...)
    #}
    
    s3load(full.filename, bucket=BUCKET.NAME.SIMS)
     #      show_progress=T)
    simset
}

sims.save <- function(simset, filename)
{
    full.filename = get.filename.for.s3(filename)
    
    s3save(simset, object=full.filename, bucket=BUCKET.NAME.SIMS)
}

is.sim.stored <- function(filename)
{
    full.filename = get.filename.for.s3(filename)
    
    x = get_bucket(bucket=BUCKET.NAME.SIMS,
                   prefix=full.filename)
    x.names = sapply(x, function(z) {z$Key} )
    any(x.names == full.filename)
}

##----------------------##
##-- FILENAME HELPERS --##
##----------------------##

is.custom.code <- function(code)
{
    nchar(code) >= nchar(CUSTOM.PREFIX) &&
        substr(code, 1, nchar(CUSTOM.PREFIX)) == CUSTOM.PREFIX
}

get.filename.for.s3 <- function(filename)
{
    if (substr(filename, nchar(filename)-5, nchar(filename))!='.Rdata')
        filename = paste0(code, '.Rdata')
    
    parsed.filename = parse.simset.filenames(filename)
    print(paste0("pulling from s3: ", filename))
    
    full.filename = file.path(parsed.filename['version'],
                              parsed.filename['location'],
                              filename)
    
    if (is.custom.code(parsed.filename['code']))
        full.filename = file.path('custom',
                                  full.filename)
    
    full.filename
}


get.new.custom.intervention.code <- function()
{
    # Strip the time of non-numeric numbers
    time.marker = Sys.time()
    time.marker = gsub("[^1-9 ]", '', time.marker)
    time.marker = trimws(time.marker)
    time.marker = gsub(' ', '_', time.marker)
    
    time.marker
    
    # Generate a random string
    random.str.len = 4
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    random.indices = ceiling(runif(random.str.len, .0000001, nchar(chars)))
    random.str = paste0(sapply(random.indices, function(i){
        substr(chars, i, i)
    }), collapse='')
    
    # Put them together
    paste0(CUSTOM.PREFIX, time.marker, '.', random.str)
}


##-------------------##
##-- OTHER HELPERS --##
##-------------------##

# Utils: AWS S3 Storage ####
s3.list <- function(
    dir,
    full.path,
    bucket.name,
    prefix=NULL
) {
    if (is.null(dir) || is.na(dir))
        dir = ''
    if (dir != '' && substr(dir, nchar(dir)-1, nchar(dir))!='/')
        dir = paste0(dir, '/')
    
    items.list = get_bucket(bucket=bucket.name, max=Inf, prefix = paste0(dir, prefix))
    items.names = sapply(items.list, function(x) x$Key )
    if (!full.path)
    {
        items.names = sapply(items.names, function(item.name){
            substr(item.name, 1 + nchar(dir), nchar(item.name))
        })
    }
    
    names(items.names) = NULL
    items.names = items.names[items.names != '']
    return(items.names)
}
