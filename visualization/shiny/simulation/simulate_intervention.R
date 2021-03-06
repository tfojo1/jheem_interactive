
MAX.KEEP.FROM.YEAR = 2018
RUN.TO.YEAR = 2030

simulate.intervention <- function(session,
                                  version,
                                  location,
                                  intervention,
                                  cache)
{
    seed.filename = get.seed.filename(location=location,
                                          version=version)
    
    success = pull.files.to.cache(session, seed.filename, cache)
    if (!success)
        return(NULL)
    
    tryCatch({
        
        seed.simset = get.simsets.from.cache(seed.filename, cache)[[1]]
        
#print("Using limited seed for now")
#seed.simset = subset.simset(seed.simset, 1:5)
        
        withProgress(
            message=paste0("Preparing to run ", seed.simset@n.sim, " simulations"), 
            min=0, max=seed.simset@n.sim, value=0,
            detail=NULL,
            {   
                run.from.year = attr(seed.simset, 'run.from.year')
                keep.from.year = min(run.from.year-1, MAX.KEEP.FROM.YEAR-1)
                
                start.time = Sys.time()
                simset = run.simset.intervention(seed.simset, 
                                                 intervention,
                                                 run.from.year = run.from.year,
                                                 run.to.year = RUN.TO.YEAR,
                                                 keep.years = keep.from.year:RUN.TO.YEAR,
                                                 
                                                 update.progress=function(i){
                                                     time.diff = as.numeric(difftime(Sys.time(), start.time, units='secs'))
                                                     time.text = get.timespan.text(time.diff,
                                                                                   digits.for.last.span = 0)
                                                     setProgress(value=i,
                                                                 message=paste0("Running Simulation ", i, " of ", seed.simset@n.sim, ": "),
                                                                 detail=paste0(time.text, " elapsed"))
                                                 })
                setProgress(seed.simset@n.sim, detail='Done')
            })

        compress.simset(simset)
    },
    error = function(e){
        show.error.message("Error Simulating Intervention",
                           "There was an error running the simulations for the specified intervention. We apologize - please try again later.")
        NULL
    })
}

get.selected.custom.intervention <- function(input, suffix)
{
    subpopulation.nums = 1:get.custom.n.subpopulations(input)
    target.populations = lapply(subpopulation.nums,
                                get.custom.subpopulation, input=input)
    
    unit.interventions = lapply(subpopulation.nums,
                                get.custom.unit.interventions, input=input)
    
    sub.interventions = lapply(subpopulation.nums, function(i){
        create.intervention(target.populations[[i]], unit.interventions[[i]])
    })
    
    join.interventions(sub.interventions)
}


##-- MID-LEVEL --##

get.custom.subpopulation <- function(input, num)
{
    print("Get Custom Subpopulation: We need to do error checking here")
    ages = get.custom.ages(input, num)
    races = get.custom.races(input, num)
    sexes = get.custom.sexes(input, num)
    risks = get.custom.risks(input, num)
    
    tpop = NULL
    iterated.sexes = rep(sexes, each=length(risks))
    iterated.risks = rep(risks, length(sexes))
    mask = iterated.sexes != 'female' | !grepl('msm', iterated.risks)
    iterated.sexes = iterated.sexes[mask]
    iterated.risks = iterated.risks[mask]
    
    for (i in 1:length(iterated.sexes))
    {
        if (iterated.sexes[i]=='female')
            new.sex = 'female'
        else if (grepl('msm', iterated.risks[i]))
            new.sex = 'msm'
        else
            new.sex = 'heterosexual_male'
        
        if (grepl('active', iterated.risks[i]))
            new.risk = 'active_IDU'
        else if (grepl('prior', iterated.risks[i]))
            new.risk = 'IDU_in_remission'
        else
            new.risk = 'never_IDU'
        
        new.tpop = create.target.population(ages=ages,
                                            races=races,
                                            sexes=new.sex,
                                            risks=new.risk)
        
        if (is.null(tpop))
            tpop = new.tpop
        else
            tpop = union.target.populations(tpop, new.tpop)
    }
    
    tpop
}

get.custom.unit.interventions <- function(input, num)
{
    start.year = get.custom.start.year(input, num)
    end.year = get.custom.end.year(input, num)
    
    rv = list()
    
    if (get.custom.use.testing(input, num))
    {
        rv = c(rv,
               list(create.intervention.unit(type = 'testing', 
                                 start.year = start.year, 
                                 rates = 12/get.custom.testing.frequency(input, num),
                                 years = end.year)
               ))
    }
    
    if (get.custom.use.prep(input, num))
    {
        rv = c(rv,
               list(create.intervention.unit(type = 'prep', 
                                             start.year = start.year, 
                                             rates = get.custom.prep.uptake(input, num),
                                             years = end.year)
               ))
    }
    
    if (get.custom.use.suppression(input, num))
    {
        rv = c(rv,
               list(create.intervention.unit(type = 'suppression', 
                                             start.year = start.year, 
                                             rates = get.custom.suppressed.proportion(input, num),
                                             years = end.year)
               ))
    }
    
    rv
}
