
##---------------##
##-- TOOL-TIPS --##
##---------------##

OVERVIEW.POPOVER.TITLE = 'What this Site is About'
OVERVIEW.POPOVER = "We apply the JHEEM model of HIV transmission to the Ending the HIV Epidemic Initiative"


get.prerun.popover.title <- function(web.version.data)
{
    paste0("Explore Pre-defined ", web.version.data$intervention.label, "s Quickly")
}
get.prerun.popover <- function(web.version.data)
{
    paste0("This tab allows you to try out ", 
           tolower(web.version.data$intervention.label), 
           "s that we have already simulated. You can get results within a few seconds.")
}

get.custom.popover.title <- function(web.version.data)
{
    paste0("Define and Simulate Your Own ", web.version.data$intervention.label, "s")
}
get.custom.popover <- function(web.version.data)
{
    paste0("This tab allows you to define any ", tolower(web.version.data$intervention.label),
           " you want. It will take several minutes to simulate these ",
           tolower(web.version.data$intervention.label), "s")
}

FAQ.POPOVER.TITLE = "Frequently Asked Questions"
FAQ.POPOVER = "Answers to common questions about our model and its application here."

ABOUT.POPOVER.TITLE = "The Model Behind the Projections"
ABOUT.POPOVER = "A brief overview of the Johns Hopkins Epidemiologic and Economic Model of HIV (JHEEM) and the methods we use to calibrate it."

OUR.TEAM.POPOVER.TITLE = "The Research Team"
OUR.TEAM.POPOVER = "About the investigators behind the Johns Hopkins Epidemiologic and Economic Model of HIV (JHEEM)."

CONTACT.POPOVER.TITLE = "Contact Us"
CONTACT.POPOVER = "Send us a message with any questions, feedback, or suggestions."


# NB: these popover depends on a javascript hack to set the id of the title text, in setup_tooltips.js
make.tab.popover <- function(id,
                             title,
                             content)
{
    bsPopover(id, 
              title=paste0("<b>", title, "</b>"),
                  #title,#HTML(paste0("<a class='tab_popover_title'>", title, "</a>")),
              content=content,#HTML(paste0("<a class='tab_popover_content'>", content, "</a>")),
              trigger = "hover", placement='bottom',
              options=list(container="body", html=T))
}

make.popover <- function(id,
                         title,
                         content,
                         placement)
{
    bsPopover(id, 
              title=paste0("<b>", title, "</b>"),
              #title,#HTML(paste0("<a class='tab_popover_title'>", title, "</a>")),
              content=content,#HTML(paste0("<a class='tab_popover_content'>", content, "</a>")),
              trigger = "hover", placement=placement,
              options=list(container="body", html=T))
}