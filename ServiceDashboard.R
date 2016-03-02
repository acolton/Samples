library(shiny)
library(rJava)

.jinit(classpath="data/XXXXX.jar")
.jinit(classpath="data/XXXXX.jar")
.jinit(classpath="data/XXXXX.jar")
.jinit(classpath="data/XXXXX.jar")

.jinit(classpath="data/XXXXX.jar")
.jinit(classpath="data/XXXXX.jar")
.jclassPath()

rdata <- list()
initialStartTime <- format(Sys.Date(), "%Y-%m-%d 00:00:00")

shinyServer(function(input, output, session) {
  
  timestamp <- as.character(format(Sys.time(), "%Y-%m-%d %H.%M.%S"))
  logfilename <- paste0("data/directory/", timestamp, ".log")

  #START OBSERVE/INVALIDATE LATER --------------------------------------------------------------  
  observe({
    hostname <- session$clientData$url_hostname
    write.table(paste0("URL Hostname:", hostname), logfilename, append = TRUE, row.names = FALSE,
                col.names = FALSE, quote = FALSE)
    write.table(Sys.time(), logfilename, append = TRUE, row.names = FALSE,
                col.names = FALSE, quote = FALSE)
    
    if ((session$clientData$url_hostname == "localhost") || (session$clientData$url_hostname == "127.0.0.1")){
      
      endTime <- format(Sys.time(), "%Y-%m-%d %H:%M:%S") 
      XData <- J("com.XXXXX.api.Query")$GetUrgentEmailTicketsWithFirstAssignTimeinBetween(initialStartTime, endTime)
        rdata$UrgentEmails <<- XData[1]
        rdata$UrgentAvgRT <<- XData[2]   # unit in hours
      XData <- J("com.XXXXX.api.Query")$GetHighEmailTicketsWithFirstAssignTimeinBetween(initialStartTime, endTime)
        rdata$HighEmails <<- XData[1]
        rdata$HighAvgRT <<- XData[2]   # unit in hours
      XData <- J("com.XXXXX.api.Query")$GetMediumEmailTicketsWithFirstAssignTimeinBetween(initialStartTime, endTime)
        rdata$MediumEmails <<- XData[1]
        rdata$MediumAvgRT <<- XData[2]   # unit in hours
      XData <- J("com.XXXXX.api.Query")$GetLowEmailTicketsWithFirstAssignTimeinBetween(initialStartTime, endTime)
        rdata$LowEmails <<- XData[1]
        rdata$LowAvgRT <<- XData[2]   # unit in hours
      rdata <<- rapply(rdata, f=function(x) ifelse(is.nan(x),0,x), how="replace") 
      
      newStartTime <- endTime
      
      write.table(paste0("Complete: Get Initial Data ", Sys.time(), "\n"), logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
      write.table(paste0("initialStartTime: ",initialStartTime,"\n","endTime: ",endTime,"\n","newStartTime",newStartTime), 
                  logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)

    
 observe({
    invalidateLater(30000, session)
    
    today <- format(Sys.Date(), "%A %B %d, %Y")
    surveyStart <- format(Sys.Date(), "%Y-%m-%d")
    surveyEnd <- format(as.Date(surveyStart, format="%Y-%m-%d")+1,"%Y-%m-%d")
    endTime <- format(Sys.time(), "%Y-%m-%d %H:%M:%S") 
    
    write.table(paste0("Before New Day Evaluation: ", Sys.time()), logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
    write.table(paste0("initialStartTime: ",initialStartTime,"\n","endTime: ",endTime,"\n","newStartTime",newStartTime), 
                logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)

    
      if (initialStartTime != (format(Sys.Date(), "%Y-%m-%d 00:00:00"))) {
        initialStartTime <<- format(Sys.Date(), "%Y-%m-%d 00:00:00")
        
        endTime <- format(Sys.time(), "%Y-%m-%d %H:%M:%S") 
        XData <- J("com.XXXXX.api.Query")$GetUrgentEmailTicketsWithFirstAssignTimeinBetween(initialStartTime, endTime)
          rdata$UrgentEmails <<- XData[1]
          rdata$UrgentAvgRT <<- XData[2]   # unit in hours
        XData <- J("com.XXXXX.api.Query")$GetHighEmailTicketsWithFirstAssignTimeinBetween(initialStartTime, endTime)
          rdata$HighEmails <<- XData[1]
          rdata$HighAvgRT <<- XData[2]   # unit in hours
        XData <- J("com.XXXXX.api.Query")$GetMediumEmailTicketsWithFirstAssignTimeinBetween(initialStartTime, endTime)
          rdata$MediumEmails <<- XData[1]
          rdata$MediumAvgRT <<- XData[2]   # unit in hours
        XData <- J("com.XXXXX.api.Query")$GetLowEmailTicketsWithFirstAssignTimeinBetween(initialStartTime, endTime)
          rdata$LowEmails <<- XData[1]
          rdata$LowAvgRT <<- XData[2]   # unit in hours
        rdata <<- rapply(rdata, f=function(x) ifelse(is.nan(x),0,x), how="replace") 
        newStartTime <- endTime
        
        write.table(paste0("Complete: Get Data for New Day ", Sys.time()), logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
        write.table(paste0("initialStartTime: ",initialStartTime,"\n","endTime: ",endTime,"\n","newStartTime",newStartTime), 
                    logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)

      }  
     
      #Urgent--------------------------------------------------------------------------------------
       XData <- J("com.XXXXX.api.Query")$GetUrgentEmailTicketsWithFirstAssignTimeinBetween(newStartTime, endTime)
       UrgentNewEmails <- XData[1]
       UrgentNewAvgRT <- XData[2]   # unit in hours
       UrgentRT <- (((rdata$UrgentEmails * rdata$UrgentAvgRT)+(UrgentNewEmails * UrgentNewAvgRT))/(rdata$UrgentEmails + UrgentNewEmails))
        
       if (is.na(UrgentRT)[1]) rdata$UrgentAvgRT <- rdata$UrgentAvgRT else rdata$UrgentAvgRT <<- UrgentRT
        
       rdata$UrgentEmails <<- (UrgentNewEmails + rdata$UrgentEmails)
    

      #High----------------------------------------------------------------------------------------
      XData <- J("com.XXXXX.api.Query")$GetHighEmailTicketsWithFirstAssignTimeinBetween(newStartTime, endTime)
      HighNewEmails <- XData[1]
      HighNewAvgRT <- XData[2]   # unit in hours
      HighRT <- (((rdata$HighEmails * rdata$HighAvgRT)+(HighNewEmails * HighNewAvgRT))/(rdata$HighEmails + HighNewEmails))
    
      if(is.na(HighRT)[1]) rdata$HighAvgRT <- rdata$HighAvgRT else rdata$HighAvgRT <<- HighRT
    
      rdata$HighEmails <<- (HighNewEmails + rdata$HighEmails)
    
      
      #Medium--------------------------------------------------------------------------------------
      XData <- J("com.XXXXX.api.Query")$GetMediumEmailTicketsWithFirstAssignTimeinBetween(newStartTime, endTime)
      MediumNewEmails <- XData[1]
      MediumNewAvgRT <- XData[2]   # unit in hours
      MediumRT <- (((rdata$MediumEmails * rdata$MediumAvgRT)+(MediumNewEmails * MediumNewAvgRT))/(rdata$MediumEmails + MediumNewEmails))
    
      if (is.na(MediumRT)[1]) rdata$MediumAvgRT <- rdata$MediumAvgRT else rdata$MediumAvgRT <<- MediumRT
    
      rdata$MediumEmails <<- (MediumNewEmails + rdata$MediumEmails)
    

      #Low----------------------------------------------------------------------------------------
      XData <- J("com.XXXXX.api.Query")$GetLowEmailTicketsWithFirstAssignTimeinBetween(newStartTime, endTime)
      LowNewEmails <- XData[1]
      LowNewAvgRT <- XData[2]   # unit in hours
      LowRT <- (((rdata$LowEmails * rdata$LowAvgRT)+(LowNewEmails * LowNewAvgRT))/(rdata$LowEmails + LowNewEmails))
    
      if (is.na(LowRT)[1]) rdata$LowAvgRT <- rdata$LowAvgRT else rdata$LowAvgRT <<- LowRT
    
      rdata$LowEmails <<- (LowNewEmails + rdata$LowEmails)

    write.table(paste0("Complete: Get Priority Data ", Sys.time()), logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
    
      rdata$survey <- round(J("com.XXXXX.api.Query")$GetSurveyScore(surveyStart, surveyEnd), 2)
      rdata$openCases <- J("com.XXXXX.api.Query")$GetNumofL1Pending()
      rdata$avgEmail = round(J("com.XXXXX.api.Query")$GetRollingAverage(endTime) * 100, 2)
      
    write.table(paste0("Complete: Get Survey, Open Cases, Avg Email ", Sys.time()), logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
      
      #-------------------------------------------------------------------------------------------
      acdData <- J("com.XXXXX.Query")$GetACDStats(initialStartTime, endTime)  
      rdata$totalCalls <- acdData[1]
      rdata$asa <- round(acdData[2], 2)
      rdata$abd <- round(acdData[5] * 100, 2)
      rdata$avgABD <- round(acdData[4], 2)
      rdata$avgCalls <- round(J("com.XXXXX.Query")$GetRollingAverage(endTime) * 100, 2)
      
      rdata$totalEmails <- (rdata$LowEmails +  rdata$MediumEmails +  rdata$HighEmails +  rdata$UrgentEmails)
      rdata$totalInteractions <- (rdata$totalEmails + rdata$totalCalls)
      rdata$avgInteraction <- round(((rdata$totalEmails * rdata$avgEmail) + (rdata$totalCalls * rdata$avgCalls))/(rdata$totalInteractions), 2)
     
    write.table(paste0("Complete: Get ACD Data ", Sys.time()), logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
      
      write.table(rdata, paste0("data/", Sys.Date(), "-RData.csv"))
      newStartTime <<- endTime
      
    write.table(paste0("Complete: Write to file ", Sys.time()), logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
    
    #UI Information -----------------------------------------------------------------------------
    
    output$today <- renderUI ({
      str <- paste (h2("Real-Time Service Desk Metrics for", today))
      HTML(paste(str))
    })
    
    output$totalCalls <- renderUI ({
      rdata$totalCalls[is.na(rdata$totalCalls)] = 0
      str1 <- paste (h4("Total Inbound Calls"), h1(img(src="ServiceDeskDashboard-10.png"), rdata$totalCalls))
      tags$div(title="# of tickets currently in queue received via phone", HTML(paste(str1)))
    })
    
    output$avgCalls <- renderUI ({
      rdata$avgCalls[is.na(rdata$avgCalls)] = 0
      str2 <- paste (h4("% Rolling Average Inbound Calls"), h1(img(src="ServiceDeskDashboard-05.png"), rdata$avgCalls, "%"))
      tags$div(title="% of tickets received via phone compared to the same date and time for the past 4 weeks", HTML(paste(str2)))
    })
    
    output$totalEmail <- renderUI ({
      rdata$totalEmails[is.na(rdata$totalEmails)] = 0
      str3 <- paste (h4("Total Email (EQ) Tickets"), h1(img(src="ServiceDeskDashboard-15.png"), rdata$totalEmails))
      tags$div(title="# of tickets currently in queue received via email", HTML(paste(str3)))
    })
    
    output$avgEmail <- renderUI ({
      rdata$avgEmail[is.na(rdata$avgEmail)] = 0
      str4 <- paste (h4("% Rolling Average Email (EQ) Tickets"), h1(img(src="ServiceDeskDashboard-05.png"), rdata$avgEmail, "%"))
      tags$div(title="% of tickets received via email compared to the same date and time for the past 4 weeks", HTML(paste(str4)))
    })
    
    output$totalInteraction <- renderUI ({
      rdata$totalInteractions[is.na(rdata$totalInteractions)] = 0
      str5 <- paste (h4("Total Interactions"), h1(img(src="ServiceDeskDashboard-20.png"), rdata$totalInteractions))
      tags$div(title="Total Inbound Calls + Total Email (EQ) Tickets", HTML(paste(str5)))                                                              
    })
    
    output$avgInteraction <- renderUI ({
      rdata$avgInteraction[is.na(rdata$avgInteraction)] = 0
      str6 <- paste (h4("% Rolling Average Total Interactions"), h1(img(src="ServiceDeskDashboard-05.png"), rdata$avgInteraction,"%"))
      tags$div(title="% of total interactions compared to the same date and time for the past 4 weeks", HTML(paste(str6)))                                           
    })
    
    output$asa <- renderUI ({
      rdata$asa[is.na(rdata$asa)] = 0
      str7 <- paste (h4("Average Speed of Answer"), h5("(in Seconds)"), h1(img(src="ServiceDeskDashboard-09.png"), rdata$asa))
      tags$div(title="average time (in seconds) that calls were online before being answered", HTML(paste(str7)))                                   
    })
    
    output$abd <- renderUI ({
      rdata$abd[is.na(rdata$abd)] = 0
      str8 <- paste (h4("Abandoned %"), h1(img(src="ServiceDeskDashboard-03.png"), rdata$abd))
      tags$div(title="% of calls that were abandoned", HTML(paste(str8)))                             
    })
    
    output$avgABD <- renderUI ({
      rdata$avgABD[is.na(rdata$avgABD)] = 0
      str9 <- paste (h4("Average Abandoned"), h5("(in Seconds)"), h1(img(src="ServiceDeskDashboard-04.png"), rdata$avgABD))
      tags$div(title="average time (in seconds) that abandoned calls were online before being abandoned", HTML(paste(str9)))                                             
    })
    
    output$survey <- renderUI ({
      rdata$survey[is.na(rdata$survey)] = 0
      str10 <- paste (tags$div(title="tool tip thingy goes here", h4("Survey Average (1-4)")), h1(img(src="ServiceDeskDashboard-07.png"), rdata$survey))
      tags$div(title="average survey score (between 1 and 4)", HTML(paste(str10)))                                         
    })
    
    output$openCases <- renderUI ({
      rdata$openCases[is.na(rdata$openCases)] = 0
      str11 <- paste (h4("Open Cases"), h1(img(src="ServiceDeskDashboard-08.png"), rdata$openCases))
      tags$div(title="# of pending tickets", HTML(paste(str11)))                                
    })
    
    output$UrgentAveRT <- renderUI ({
      rdata$UrgentAvgRT <- round(rdata$UrgentAvgRT * 60, 1)
      rdata$UrgentAvgRT[is.na(rdata$UrgentAvgRT)] = 0
      if (rdata$UrgentAvgRT > 15){
        str12 <- paste (h4("Urgent", br(), "Avg. Response Time", br()), h5("(in Minutes)"), h6(img(src="ServiceDeskDashboard-02.png"), rdata$UrgentAvgRT))}
      else {
        str12 <- paste (h4("Urgent", br(), "Avg. Response Time", br()), h5("(in Minutes)"), h1(img(src="ServiceDeskDashboard-02.png"), rdata$UrgentAvgRT))}
      tags$div(title="average response time (in minutes) for urgent priority tickets", HTML(paste(str12)))                                          
    })
    
    output$HighAveRT <- renderUI ({
      rdata$HighAvgRT <- round(rdata$HighAvgRT * 60, 1)
      rdata$HighAvgRT[is.na(rdata$HighAvgRT)] = 0
      if (rdata$HighAvgRT > 45){
        str13 <- paste (h4("High", br(), "Avg. Response Time", br()), h5("(in Minutes)"), h6(img(src="ServiceDeskDashboard-02.png"), rdata$HighAvgRT))}
      else {
        str13 <- paste (h4("High", br(), "Avg. Response Time", br()), h5("(in Minutes)"), h1(img(src="ServiceDeskDashboard-02.png"), rdata$HighAvgRT))}
      tags$div(title="average response time (in minutes) for high priority tickets", HTML(paste(str13))) 
    })
    
    output$MediumAveRT <- renderUI ({
      rdata$MediumAvgRT <- round(rdata$MediumAvgRT * 60, 1)
      rdata$MediumAvgRT[is.na(rdata$MediumAvgRT)] = 0
      if (rdata$MediumAvgRT > 240){
        str14 <- paste (h4("Medium", br(), "Avg. Response Time", br()), h5("(in Minutes)"), h6(img(src="ServiceDeskDashboard-02.png"), rdata$MediumAvgRT))}
      else {
        str14 <- paste (h4("Medium", br(), "Avg. Response Time", br()), h5("(in Minutes)"), h1(img(src="ServiceDeskDashboard-02.png"), rdata$MediumAvgRT))}
      tags$div(title="average response time (in minutes) for medium priority tickets", HTML(paste(str14)))                                          
    })
    
    output$LowAveRT <- renderUI ({
      rdata$LowAvgRT <- round(rdata$LowAvgRT * 60, 1)
      rdata$LowAvgRT[is.na(rdata$LowAvgRT)] = 0
      if (rdata$LowAvgRT > 1440) {
        str15 <- paste (h4("Low", br(), "Avg. Response Time", br()), h5("(in Minutes)"), h6(img(src="ServiceDeskDashboard-02.png"), rdata$LowAvgRT))}
      else {
        str15 <- paste (h4("Low", br(), "Avg. Response Time", br()), h5("(in Minutes)"), h1(img(src="ServiceDeskDashboard-02.png"), rdata$LowAvgRT))}
      tags$div(title="average response time (in minutes) for low priority tickets", HTML(paste(str15)))                                     
    })
    

    write.table(paste0("Finished Loading ", Sys.time(), "\n"),logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)

})
}
else{
  showshinyalert(session,"alert","You do not have permission to access this application",styleclass = "info")
  write.table(paste0("Complete: Show alert ", Sys.time(),"\n"), logfilename, append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
}


})
})


