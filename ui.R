#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#
library(shinydashboard)

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Upload Question Bank", tabName = 'upload', icon=icon("upload"))
    ,menuItem("Configure your exam", tabName = "edit", icon=icon("gear"))
    ,menuItem("Preview", tabName = 'preview', icon=icon("file-text"))
    #,menuItem("Download exam", tabName = 'download', icon=icon("download"))
  ))


body <- dashboardBody(
  tabItems(
    tabItem("upload", 
            fluidRow(
              box(title="Upload the question bank", 
                  status = "primary", 
                  solidHeader = T, 
                  fileInput('qbank', "Question bank (Accepted format: xlsx)", 
                            accept = c(".xlsx")))
            )
            ,fluidRow(
              box(title="Preview the questions", 
                  status ='primary', solidHeader = T, 
                  dataTableOutput('previewTable')))
            
            )
  ,tabItem("edit", 
           fluidRow(
             box(title = "Configure" 
                 ,status="primary" 
                 ,solidHeader = T
                 , actionButton("goButton", "Go!")
                 ,uiOutput('nQuestionsSelector')
                 )
           ))
  ,tabItem("preview",
           fluidRow(
             box(title="Exam", 
                 status="primary",
                 solidHeader = T, 
                 uiOutput('Exam')
             )
             ,box(title="Answer Key", 
                  status="primary",
                  solidHeader = T, 
                  uiOutput('Answers')
             )  
           )
           
           ,fluidRow(
             box(downloadButton("downloadButton", "Download"))
           )
           
           )
  )
)


dashboardPage(
  dashboardHeader(title = "Exam Creator"),
  sidebar, 
  body
)
