library(shiny);

## ====== READING AND CLEANING THE DATA =====
xLabeled <- read.csv("pml-training.csv")

# Let's make it verbose for better understanding

# 1. X column is just a sequential number. Do not use.
xLabeled <- xLabeled[, !(colnames(xLabeled)=="X")]
N = length(xLabeled[,1])

#2. Timestamp columns should not be used
columnsToDrop <-c("raw_timestamp_part_1","raw_timestamp_part_2","cvtd_timestamp","X","user_name","new_window", "num_window");
xLabeled <- xLabeled[, !(colnames(xLabeled) %in% columnsToDrop)]

#In the report - use first few lines of dataset. Show that we have NAs and empty values.

#3. Remove columns with too many missing values
# In the report - show table with percentage (separate of joint), it will provide good illustration
cutoff_percentage = 0.95 #Let's say, over 95% of NA or empty values means that column should be dropped
# In the report - use "at least 1" cutoff
cutoff_percentage <- 0.95
xLabeled <- xLabeled[, lapply(xLabeled, function(x) (sum(is.na(x) | x=="")) / length(x)) < cutoff_percentage]
xLabeled <- xLabeled[complete.cases(xLabeled), ]

#4. Generate activities list
activitiesListForCheckbox <- as.list(as.character(unique(xLabeled$classe)))
activityFriendlyNames <- c("Sitting down (class A)","Standing up (class B)","Standing (class C)","Walking (class D)","Sitting (class E)");
names(activitiesListForCheckbox) <- activityFriendlyNames

#5. Generate selection parameters out of column names
selectorParameters <- colnames(xLabeled);
selectorParameters <- selectorParameters[1:(length(selectorParameters)-1)]
selectorParametersFriendlyNames <- selectorParameters
toReplace <- c("yaw_", "pitch_", "roll_", "_x", "_y", "_z", "total_accel_", "accel_", "magnet_", "gyros_")
replacement <- c("Yaw - ", "Pitch - ", "Roll - ", " - X-axis", " - Y-axis", " - Z-axis", "Absolute acceleration - ", "Accelerometer - ", "Magnetometer - ", "Gyroscope - ")
for (i in 1:length(selectorParametersFriendlyNames)){
  for (j in 1:length(toReplace)){
      selectorParametersFriendlyNames[i] <- gsub(toReplace[j], replacement[j], selectorParametersFriendlyNames[i])
  }
}
names(selectorParameters) <- selectorParametersFriendlyNames;
## ====== NOW STARTING THE SERVER =====

shinyServer(
  function(input,output){
    output$activitiesSelectionRed <- renderUI({
      checkboxGroupInput('activitiesCheckboxGroupRed', 'Activities:',
                         activitiesListForCheckbox)
    })
    output$activitiesSelectionBlue <- renderUI({
      checkboxGroupInput('activitiesCheckboxGroupBlue', 'Activities:',
                         activitiesListForCheckbox)
    })

    output$parameterSelection <- renderUI({
      selectInput("parameterChoice", "Parameter Choice", selectorParameters)
    })

    output$parametersHist <- renderPlot({
      redHistExists <- length(input$activitiesCheckboxGroupRed)>0;
      blueHistExists <- length(input$activitiesCheckboxGroupBlue)>0;
      redMin = Inf
      blueMin = Inf
      redMax = -Inf
      blueMax = -Inf
      if (redHistExists){
        redColumn <- xLabeled[xLabeled$classe %in% input$activitiesCheckboxGroupRed, colnames(xLabeled) == input$parameterChoice];
        redMin <- min(redColumn)
        redMax <- max(redColumn)
      }
      if (blueHistExists){
        blueColumn <- xLabeled[xLabeled$classe %in% input$activitiesCheckboxGroupBlue, colnames(xLabeled) == input$parameterChoice];
        blueMin <- min(blueColumn)
        blueMax <- max(blueColumn)
      }

      #For non-existent histograms thewir max and mins should not interfere
      xMin = min(redMin, blueMin)
      xMax = max(redMax, blueMax)

      useFrequencies <- input$freq=="Frequency";

      #friendlyParameterName <- parameter

      #An ugly way to get ylim, but that's the only one I could think of
      redYMin = Inf
      blueYMin = Inf
      redYMax = -Inf
      blueYMax = -Inf
      if (redHistExists){
        #DO NOT PRINT, just get it for ylims
        p1 <- hist(redColumn, breaks = input$numBreaks, xlim = c(xMin, xMax), freq = useFrequencies)
        if (useFrequencies){
          redYMin <- min(p1$counts)
          redYMax <- max(p1$counts)
        }else{
          redYMin <- min(p1$density)
          redYMax <- max(p1$density)
        }
      }
      if (blueHistExists){
        #DO NOT PRINT, just get it for ylims
        p1<- hist(blueColumn, breaks = input$numBreaks, xlim = c(xMin, xMax), freq = useFrequencies)
        if (useFrequencies){
          blueYMin <- min(p1$counts)
          blueYMax <- max(p1$counts)
        }else{
          blueYMin <- min(p1$density)
          blueYMax <- max(p1$density)
        }
      }
      yMin = min(redYMin, blueYMin)
      yMax = max(redYMax, blueYMax)
      legendText <- character(0L);
      legendCol <- character(0L);
      legendPch <- integer(0L);
      legendLwd <- integer(0L);


      par(mar=c(10.1, 4.1, 4.1, 4.1), xpd=TRUE)
      
      if (redHistExists || blueHistExists){
        i <- which(input$parameterChoice == selectorParameters);
        friendlyParameterName <- selectorParametersFriendlyNames[i]
        histTitle = paste("Histogram of", friendlyParameterName);
      }

      if (redHistExists){
        redFriendlyNames <- activityFriendlyNames[which(activitiesListForCheckbox %in% input$activitiesCheckboxGroupRed)]
        redFriendlyNamesStr <- paste(redFriendlyNames, collapse = ", ");
        legendText <- c(legendText, paste("Sensor readings of",friendlyParameterName,"for activities:", redFriendlyNamesStr));
        legendCol <- c(legendCol, "red")
        legendPch <- c(legendPch, 15)
        legendLwd <- c(legendLwd, NA)
        if (input$vline=="mean"){
          legendText <- c(legendText, paste("Mean",friendlyParameterName,"sensor reading for activities: ",redFriendlyNamesStr))
          legendCol <- c(legendCol, "red")
          legendPch <- c(legendPch, NA)
          legendLwd <- c(legendLwd, 2)
        }else if (input$vline=="median"){
          legendText <- c(legendText, paste("Median",friendlyParameterName,"sensor reading for activities: ",redFriendlyNamesStr))
          legendCol <- c(legendCol, "red")
          legendPch <- c(legendPch, NA)
          legendLwd <- c(legendLwd, 2)
        }
      }
      if (blueHistExists){
        blueFriendlyNames <- activityFriendlyNames[which(activitiesListForCheckbox %in% input$activitiesCheckboxGroupBlue)]
        blueFriendlyNamesStr <- paste(blueFriendlyNames, collapse=", ");
        legendText <- c(legendText, paste("Sensor readings of",friendlyParameterName,"for activities:",blueFriendlyNamesStr))
        legendCol <- c(legendCol, "blue")
        legendPch <- c(legendPch, 15)
        legendLwd <- c(legendLwd, NA)
        if (input$vline=="mean"){
          legendText <- c(legendText, paste("Mean",friendlyParameterName,"sensor reading for activities: ",blueFriendlyNamesStr))
          legendCol <- c(legendCol, "blue")
          legendPch <- c(legendPch, NA)
          legendLwd <- c(legendLwd, 2)
        }else if (input$vline=="median"){
          legendText <- c(legendText, paste("Median",friendlyParameterName,"sensor reading for activities: ",blueFriendlyNamesStr))
          legendCol <- c(legendCol, "blue")
          legendPch <- c(legendPch, NA)
          legendLwd <- c(legendLwd, 2)
        }
      }

      if (!redHistExists && !blueHistExists){
        #TODO: For all plots - title, legend, etc.
        plot(NULL, type="h", xlim = c(-100, 100), ylim = c(0,1), main = "Select Activities to Get Started")
      }
      if (redHistExists){
        hist(redColumn, col = rgb(1,0,0,0.25), breaks = input$numBreaks, xlim = c(xMin, xMax), ylim = c(yMin, yMax), freq = useFrequencies, main = histTitle, xlab = friendlyParameterName)
        if (input$vline=="mean"){
          abline(v=mean(redColumn), col = rgb(1,0,0,0.5), lwd=2)
        }else if (input$vline=="median"){
          abline(v=median(redColumn), col = rgb(1,0,0,0.5), lwd=2)
        }
      }
      if (blueHistExists){
        hist(blueColumn, col = rgb(0,0,1,0.25), add = redHistExists, breaks = input$numBreaks, xlim = c(xMin, xMax), ylim = c(yMin, yMax), freq = useFrequencies, main = histTitle, xlab = friendlyParameterName)
        if (input$vline=="mean"){
          abline(v=mean(blueColumn), col = rgb(0,0,1,0.5), lwd=2)
        }else if (input$vline=="median"){
          abline(v=median(blueColumn), col = rgb(0,0,1,0.5), lwd=2)
        }
      }
      if (redHistExists || blueHistExists){
        legend(x="bottomleft", legend = legendText, col = legendCol, pch = legendPch, lwd = legendLwd, inset = c(0,-0.4-0.07*length(legendText)))
      }
    })

    output$meanRed <- renderPrint({
      if (length(input$activitiesCheckboxGroupRed)>0){
        paste("Mean:",mean(xLabeled[xLabeled$classe %in% input$activitiesCheckboxGroupRed, colnames(xLabeled) == input$parameterChoice]))
      }else{
        "Mean: N/A (nothing selected)"
      }
    })

    output$meanBlue <- renderPrint({
      if (length(input$activitiesCheckboxGroupBlue)>0){
        paste("Mean: ",mean(xLabeled[xLabeled$classe %in% input$activitiesCheckboxGroupBlue, colnames(xLabeled) == input$parameterChoice]))
      }else{
        "Mean: N/A (nothing selected)"
      }
    })

    output$medianRed <- renderPrint({
      if (length(input$activitiesCheckboxGroupRed)>0){
        paste("Median:",median(xLabeled[xLabeled$classe %in% input$activitiesCheckboxGroupRed, colnames(xLabeled) == input$parameterChoice]))
      }else{
        "Median: N/A (nothing selected)"
      }
    })

    output$medianBlue <- renderPrint({
      if (length(input$activitiesCheckboxGroupBlue)>0){
        paste("Median: ",median(xLabeled[xLabeled$classe %in% input$activitiesCheckboxGroupBlue, colnames(xLabeled) == input$parameterChoice]))
      }else{
        "Median: N/A (nothing selected)"
      }
    })


    output$stdRed <- renderPrint({
      if (length(input$activitiesCheckboxGroupRed)>0){
        paste("StDev:",sd(xLabeled[xLabeled$classe %in% input$activitiesCheckboxGroupRed, colnames(xLabeled) == input$parameterChoice]))
      }else{
        "StDev: N/A (nothing selected)"
      }
    })

    output$stdBlue <- renderPrint({
      if (length(input$activitiesCheckboxGroupBlue)>0){
        paste("StDev:",sd(xLabeled[xLabeled$classe %in% input$activitiesCheckboxGroupBlue, colnames(xLabeled) == input$parameterChoice]))
      }else{
        "StDev: N/A (nothing selected)"
      }
    })


    output$testResRed <- renderPrint({paste("Selected classes:", paste(input$activitiesCheckboxGroupRed, collapse = ","))})
    output$testResBlue <- renderPrint({paste("Selected classes:", paste(input$activitiesCheckboxGroupBlue, collapse = ","))})
  }
)
