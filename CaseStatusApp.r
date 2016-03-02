require(shiny)
library(RMySQL)
library(dplyr)

## FUNCTIONS ---------------------------------------------------------------------------------------------------------- 

# Function to get data from the database, the query is passed in as argument
get.data <- function(query){
  con <- dbConnect(MySQL(),
                   user = "XXXXX",
                   password = "XXXXX",
                   host = "XXXXX",
                   dbname = "XXXXX")
  data <- dbGetQuery(con, query)
  dbDisconnect(con)
  return(data)
}

# Function to get amount of time in hours that the case was in a given status -----------------------------------------
status.time <- function(status, nsCase, osCase){
  start <- as.vector(nsCase[ , status])
  start <- as.POSIXct(na.omit(start))
  end <- as.vector(osCase[ , status])
  end <- as.POSIXct(na.omit(end))
  time <- as.numeric(difftime(start, end, units="days"))
  time[is.na(time)] <- 0
  return(time)
}

# Get Average of Status Times and Format ------------------------------------------------------------------------------
formatted.average <- function(avgTime){
  days <- round(avgTime, 2)
  hours <- round(avgTime*24, 2)
  if(days > 0){
    formattedTime <- paste(days, "Days")
  } else {
    formattedTime <- paste(hours, "Hours")
  }
  return(formattedTime)
}

# Add newid column to differentiate between different instances of a given status -------------------------------------
add.col <- function(x){ x$newid = 1:nrow(x); x}

## END FUNCTIONS ------------------------------------------------------------------------------------------------------

shinyServer(function(input, output, session) {
  
  # User Selected Date Range ------------------------------------------------------------------------------------------
  output$choose.dateRange <- renderUI({
    dateRangeInput("dateRange", "Date range:", 
                   start = "01-01-2014", end = "01-31-2014",
                   min = "12-31-2013", format = "mm/dd/yy")
  })
  
  # Generate Category Dropdown  ---------------------------------------------------------------------------------------
  output$choose.category <- renderUI({
    catQuery <- paste("SELECT DISTINCT category FROM CTI")
    category <- get.data(catQuery)
    selectInput("cat", "Choose a Category:", choices <- category, selected <- category[1])
  })
  
  # Generate Type Dropdown based on Category Input --------------------------------------------------------------------
  output$choose.type <- renderUI({
    typeQuery <- paste("SELECT DISTINCT type FROM CTI WHERE category='", input$cat, "'", sep="")
    type <- get.data(typeQuery)
    selectInput("type", "Choose a Type:", choices <- type, selected <- type[1])
  })
  
  # Generate Item Dropdown based on Category and Type Input -----------------------------------------------------------
  output$choose.item <- renderUI({
    itemQuery <- paste("SELECT DISTINCT item FROM CTI WHERE category='", input$cat, "' AND type ='", input$type, "'", sep="")
    item <- get.data(itemQuery)
    selectInput("item", "Choose an Item:", choices <- item, selected <- item[1])
  })
  
  
  # Get Data based on input in CTI Dropdowns --------------------------------------------------------------------------
  getDataset <- reactive({
    remedyQuery <- paste("SELECT statusTrack.caseId, statusTrack.datetime, statusTrack.oldStatus, statusTrack.newStatus,
                                 remedy.Create_Time, remedy.Category, remedy.Type, remedy.Item
                         FROM remedy INNER JOIN statusTrack ON statusTrack.caseID=remedy.Case_ID
                         WHERE remedy.Category = '", input$cat, "' 
                         AND remedy.Type = '", input$type, "' AND remedy.Item = '", input$item, "' 
                         AND remedy.Create_Time between '", input$dateRange[1], "' and '", input$dateRange[2], "'", sep="")
    casesDF <- get.data(remedyQuery)
    return(casesDF)
  })
 
  observeEvent(input$submitButton, {
    withProgress(message = "Please wait while we get the data", value = 0, {
      casesDF <- getDataset()
      caseids <- unique(casesDF$caseId)

      statusTimes <- data.frame(caseID = as.character("1"), assigned = as.numeric(1), wip = as.numeric(1), pending = as.numeric(1), resolved = as.numeric(1), stringsAsFactors = FALSE)

      if(nrow(casesDF) == 0){
        shinysky::showshinyalert(session,"alert", "There is no data for the CTI and Date Range you selected.", styleclass = "info")
        assignTime <- 0
        wipTime <- 0
        pendingTime <- 0
        resolvedTime <- 0
      } else {

       system.time({
        #  For each case id call status.time function for each status --------------------------------------------------
         for(i in 1:length(caseids)){
            assignTime <- NULL
            wipTime <- NULL
            pendingTime <- NULL
            resolvedTime <- NULL
            
            case <- casesDF[ which(casesDF$caseId == caseids[i]), ]
            case <- add.col(case)
                             
            # reshaped for Old Status
            osCase <- reshape2::dcast(case, newid + oldStatus ~ newStatus, value.var = "datetime")
            osCase <- osCase[,-which(colnames(osCase) == "newid")]

            # reshaped for New Status
            nsCase <- reshape2::dcast(case, newid + newStatus ~ oldStatus, value.var = "datetime")
            nsCase <- nsCase[,-which(colnames(nsCase) == "newid")]
            
            if(("Assigned" %in% nsCase$newStatus) && ("Assigned" %in% osCase$oldStatus)){
              assignTime <- append(assignTime, (status.time('Assigned', nsCase, osCase)))
            }
            if(("Work In Progress" %in% nsCase$newStatus) && ("Work In Progress" %in% osCase$oldStatus)){
              wipTime <- append(wipTime, (status.time('Work In Progress', nsCase, osCase)))
            }
            if(("Pending" %in% nsCase$newStatus) && ("Pending" %in% osCase$oldStatus)){
              pendingTime <- append(pendingTime, (status.time('Pending', nsCase, osCase)))
            }
            if(("Resolved" %in% nsCase$newStatus) && ("Resolved" %in% osCase$oldStatus)){
              resolvedTime <- append(resolvedTime, (status.time('Resolved', nsCase, osCase)))
            }
            statusTimes <- rbind(statusTimes, c(caseids[i], sum(assignTime), sum(wipTime), sum(pendingTime), sum(resolvedTime)))
         }
        # Get 10 cases with the longest times for each status
        statusTimes <- statusTimes[-1, ]
        statusTimes <- statusTimes %>% mutate(assigned = as.numeric(assigned)) %>% mutate(wip = as.numeric(wip)) %>% mutate(pending = as.numeric(pending)) %>% mutate(resolved = as.numeric(resolved))
        
        topAssign <- statusTimes %>% dplyr::select(caseID, assigned) %>% dplyr::arrange(desc(assigned)) %>% dplyr::slice(1:10) 
        topWip <- statusTimes %>% dplyr::select(caseID, wip) %>% dplyr::arrange(desc(wip)) %>% dplyr::slice(1:10)
        topPend <- statusTimes %>% dplyr::select(caseID, pending) %>% dplyr::arrange(desc(pending)) %>% dplyr::slice(1:10)
        topResolve <- statusTimes %>% dplyr::select(caseID, resolved) %>% dplyr::arrange(desc(resolved)) %>% dplyr::slice(1:10)
        
        assignedAvg <- mean(statusTimes$assigned)
        wipAvg <- mean(statusTimes$wip)
        pendingAvg <- mean(statusTimes$pending)
        resolvedAvg <- mean(statusTimes$resolved)
       })
      }   
    
    # Output Status Boxes ------------------------------------------------------------------------------------------------
    
      output$description <- renderUI({
             introText <- paste(h6(class = "margin", "The average number days/hours the selected cases have been set to each status:")) 
        HTML(introText) 
      })
    
      assignedAvg[is.null(assignedAvg)] = 0
      output$assignedBox <- renderInfoBox ({
           infoBox(
                "Assigned", formatted.average(assignedAvg), icon = icon("plus-square-o"), 
                color = "green",
                downloadHandler(
                     filename = function() { paste("Top_Assigned_Cases.csv", sep='')},
                     content = function(file) {
                          write.csv(topAssign, file)
                     }
                )
           )
      }) 
  
      wipAvg[is.null(wipAvg)] = 0  
      output$wipBox <- renderInfoBox ({    
            infoBox(
              "Work In Progress", formatted.average(wipAvg), icon = icon("spinner"),
              color = "orange",
              downloadHandler(
                   filename = function() { paste("Top_WIP_Cases.csv", sep='')},
                   content = function(file) {
                        write.csv(topWip, file)
                   }
              )
            )
      })    
  
      pendingAvg[is.null(pendingAvg)] = 0  
      output$pendingBox <- renderInfoBox ({    
          infoBox(
            "Pending", formatted.average(pendingAvg), icon = icon("clock-o"),
            color = "red",
            downloadHandler(
                 filename = function() { paste("Top_Pending_Cases.csv", sep='')},
                 content = function(file) {
                      write.csv(topPend, file)
                 }
            )
          )
      })  
  
      resolvedAvg[is.null(resolvedAvg)] = 0
      output$resolvedBox <- renderInfoBox ({        
        infoBox(
          "Resolved", formatted.average(resolvedAvg), icon = icon("check"),
          color = "blue",
          downloadHandler(
               filename = function() { paste("Top_Resolved_Cases.csv", sep='')},
               content = function(file) {
                    write.csv(topResolve, file)
               }
          )
        )
      })
  })
  
   observeEvent(input$displayData, {
        shinyBS::updateButton("hideData", disabled = !input$displayData)
        
         output$table <- renderUI({
              introText <- paste(h6(class = "margin", "This table shows the data included in the above analysis. The table can be searched, sorted or filtered.")) 
              HTML(introText) 
         })
         
         output$get.status <- renderDataTable(casesDF)
   })
  }) 
})


