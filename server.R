#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(readxl)
library(ReporteRs)


createExam <- function(df, chosenQuestionsSubject){
  subjects <- unique(df$Area)
  nSubjects <- length(subjects)
  out <- data.frame()
  
  for(i in 1:nSubjects){
    subjectQuestions <- subset(df, Area==subjects[i])
    possibleQuestions <- unique(subjectQuestions$Question)
    
    if(chosenQuestionsSubject[i]<1){
      next
    }
    questions <- sample(possibleQuestions, chosenQuestionsSubject[i])
    examQuestions <- subset(subjectQuestions, Question %in% questions )
    out <- rbind(out,examQuestions)
  }
  out
}

# Define server logic required to draw a histogram
shinyServer(function(input, output) {

  df <- reactive({
    fname <- input$qbank
    if(is.null(fname)){
      return(NULL)
    }
    
    file.rename(fname$datapath, paste(fname$datapath,".xlsx", sep=""))
    
    out <- read_excel(paste(fname$datapath,'.xlsx', sep = ""))
    return(out)
    
  })

  
  output$previewTable <- renderDataTable(head(df()))
  
  output$nQuestionsSelector <- renderUI({
    
  maxQuestions <- length(unique(df()$Question))
  nSubjects <- length(unique(df()$Area))
  subjects <- unique(df()$Area)
  
  sliders <- vector("list", nSubjects)
  
  for(i in 1:nSubjects){
    maxQuestionsSubject <- length(unique(subset(df(),Area==subjects[i])$Question))
    qLabel <- gsub('AREA', subjects[i], 'How many AREA questions will your exam have?')
    sliders[[i]] <- list(sliderInput(inputId = paste0('nQuestionsSubject',i), 
                                     label = qLabel,
                min = 0,max=maxQuestionsSubject, step=1, value=0))
  }
  
  sliders
  
  })
  
  nSubjects <- reactive({length(unique(df()$Area))})
  
  
  exam <- reactive({
    input$goButton
    
    chosenQuestionsSubject <- isolate(unlist(reactiveValuesToList(input)[paste0('nQuestionsSubject',1:nSubjects())]))
    
    out <- createExam(df(), chosenQuestionsSubject)
    out
  })
  

  output$Exam <- renderUI({
    
    out <- isolate(exam())
    ques <- unique(out$Question)
    questions <- vector("list", length(ques))

    for(i in 1:length(ques)){
      qdf <- subset(out,Question==ques[i])

      questions[[i]] <- list(textInput(paste0('examQuestion',i), label = "", 
                                       value=paste(i,ques[i]))
                             ,checkboxGroupInput(paste0('examQuestionChoices',i), label="", 
                                                 choiceNames = qdf$Answer, 
                                                 choiceValues=  rep('nana', length(qdf$Answer)), 
                                                 inline = T) 
                             )
      }
    questions
    
  })
  
  
  output$Answers <- renderUI({
    
    out <- isolate(exam())
    ques <- unique(out$Question)
    questions <- vector("list", length(ques))
  
    for(i in 1:length(ques)){
      qdf <- subset(out,Question==ques[i])
      correct <- subset(qdf, IsCorrect=='y')$Answer
      
      questions[[i]] <- list(textInput(paste0('examQuestionA',i), label = "", 
                                       value=paste(i,ques[i]))
                             ,checkboxGroupInput(paste0('examCorrectChoices',i), label="", 
                                                 selected = correct,
                                                 choiceNames = qdf$Answer, 
                                                 choiceValues=  qdf$Answer, 
                                                 inline = T) 
      )
    }
    questions
    
  })
  

  output$downloadButton <- downloadHandler(

    filename <- "exam.docx"

    ,content <- function(file) {
      
      doc <- docx(title="My exam") 
      
      out <- isolate(exam())
      
      
      ques <- unique(out$Question)

      ## Exam part
      doc <- addParagraph(doc, value = "Exam", stylename='Titre')
      
      for(i in 1:length(ques)){
        qdf <- subset(out,Question==ques[i])
        doc <- addParagraph(doc, value = paste0(i,". ",as.character(ques[i])), stylename='Normal')
        
        for(j in 1:length(qdf$Answer))
        {
          ans <- paste0(letters[j],") ",as.character(qdf[j,"Answer"]))
          doc <- addParagraph(doc, value = ans, stylename='Normal')
        }
        doc <- addParagraph(doc, value="\r\n")
      }
      
      
      doc <- addPageBreak(doc)
      doc <- addParagraph(doc, value = "Answers", stylename='Titre')
      
      ## Answers
      for(i in 1:length(ques)){
        qdf <- subset(out,Question==ques[i])
        doc <- addParagraph(doc, value = paste0(i,". ",as.character(ques[i])), stylename='Normal')
        
        for(j in 1:length(qdf$Answer))
        {
          ans <- pot(paste0(letters[j],") ",as.character(qdf[j,"Answer"]))
                     ,textProperties(font.weight = ifelse(qdf[j,'IsCorrect']=='y', "bold","normal"))
                     )
          doc <- addParagraph(doc, value = ans, stylename='Normal')
        }
        doc <- addParagraph(doc, value="\r\n")
      }
      
      writeDoc(doc,file)
    }
  )
  
})
