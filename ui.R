library(shiny)

# I need customized layout, so let's go in depth of fluidPage
shinyUI(fluidPage(

    titlePanel("Human Activity Recognition - Dataset Exploration"),
    fluidRow(
      p("This is the HAR dataset used for Practical Machine Learning course.
        Feel free to explore it, this might help you in Practical Machine Learning course."),
      p("Just pick activity(ies) of interest, compare sensor reading patterns, and find out
        if there are any features that help to distinguish one activity from another."),
      p("Use controls to fine-tune the histograms and don't forget the summary statistics calculated below.
        Click any of the activities to get started.")
    ),
    fluidRow(
      column(6,
        h3("Activity Set - Red"), #TODO Change it
        uiOutput('activitiesSelectionRed'),
        verbatimTextOutput('testResRed')
      ),
      column(6,
        h3("Activity Set - Blue"), #TODO Change it
        uiOutput('activitiesSelectionBlue'),
        verbatimTextOutput('testResBlue')
      )
    ),
    fluidRow(
      uiOutput('parameterSelection')
    ),
    fluidRow(
        column(4, sliderInput('numBreaks', 'Bins of histogram', 20, min = 10, max = 50, step = 5)),
        column(4, radioButtons('freq', "Show:", c("Density"="Density", "Frequency"="Frequency"))),
        column(4, radioButtons('vline', "Vertical line:", c("None"="none", "Mean"="mean", "Median"="median")))
    ),
    fluidRow(
      h3('Parameter Histogram'), #TODO Use better words
      plotOutput('parametersHist')
    ),
    fluidRow(
      #TODO better & adaptive titles
      column(6,
          h3("Activity group - Red:"),
          verbatimTextOutput('meanRed'),
          verbatimTextOutput('medianRed'),
          verbatimTextOutput('stdRed')
      ),
      column(6,
          h3("Activity group - Blue:"),
          verbatimTextOutput('meanBlue'),
          verbatimTextOutput('medianBlue'),
          verbatimTextOutput('stdBlue')
      )
    ),
    fluidRow(
      h3("References:"),
      p("[1] Velloso, E.; Bulling, A.; Gellersen, H.; Ugulino, W.; Fuks, H. Qualitative Activity Recognition of Weight Lifting Exercises. Proceedings of 4th International Conference in Cooperation with SIGCHI (Augmented Human '13) . Stuttgart, Germany: ACM SIGCHI, 2013."),
      p("Read more: http://groupware.les.inf.puc-rio.br/har#dataset#ixzz3vNMqhEud"),
      p("Dataset is available under the terms of Creating Commons license (CC-BY-SA)")
    )
  )
)
