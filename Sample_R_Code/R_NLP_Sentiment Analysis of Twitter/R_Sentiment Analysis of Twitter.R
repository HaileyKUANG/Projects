##===========================================================##
##                Sentiment Analysis of Twitter              ##
##===========================================================##


## Install needed packages
Packages <- c("twitteR", "RCurl", "bitops", "tm", "slam", 
              "wordcloud", "NLP", "lavaan", "RCurl", "plyr",
              "glue", "stringr", "tidytext", "tidyr", "dplyr", "tidyverse")

for (BAO in Packages) {
  if (BAO %in% rownames(installed.packages()) == FALSE){
    install.packages(BAO)
  }
  if (BAO %in% (.packages()) == FALSE){
    library(BAO, character.only = TRUE)
  }
}

## set paths
setwd("/Users/.../R_NLP_Sentiment Analysis of Twitter")


## ============================ ##
## 1. Capture Tweets
## ============================ ##

## set twitter API
comsumer_key <- 'PZTkLdQATYhxkOv4nFUnV3YTV'
comsumer_secret <- '3WJJjVIRxuYPCLF8TtiuUx1e1NSsKJH5EqitUhtzyp6jcQ4tIg'
access_token <- '824638349809946624-sUGi4DKMQwd8kGl3nSoUaK0OZZ6mbpS'
access_secret <- 'Q0dpcIm6snk4EKRrtNb5plOHhlg6WBRc3c5GQXH5I4l0D'  

## set API 
setup_twitter_oauth(comsumer_key, 
                    comsumer_secret,
                    access_token, 
                    access_secret)

## Tweets were captured in 2017
## Get tweets which include both UF and FSU for Gainesville 
Tallahassee_tweets21 <- searchTwitter("UF+FSU", n = 1000, lang = "en", since = '2017-11-25',
                           until = '2017-11-26', geocode = '30.444915,-84.281356,30mi')

## Get tweets which include both UF and FSU for Tallahassee
Gainesville_tweets22 <- searchTwitter("UF+FSU", n = 1000, lang = "en", since = '2017-11-25',
                             until = '2017-11-26', geocode = '29.639798,-82.344289,30mi')

## Get tweets which include both UF and FSU for Orlando
Orlando_tweets23 <- searchTwitter("UF+FSU", n = 1000, lang = "en", since = '2017-11-25',
                             until = '2017-11-26', geocode = '28.534346,-81.382840,30mi')

## Get tweets which include both UF and FSU for Jacksonville
Jacksonville_tweets24 <- searchTwitter("UF+FSU", n = 1000, lang = "en", since = '2017-11-25',
                             until = '2017-11-26', geocode = '30.328098,-81.637842,30mi')

## Get tweets which include both UF and FSU for Tempa
Tempa_tweets25 <- searchTwitter("UF+FSU", n = 1000, lang = "en", since = '2017-11-25',
                             until = '2017-11-26', geocode = '27.933248,-82.484548,30mi')

## write data into data frame
Tallahassee <- twListToDF(Tallahassee_tweets21)
Gainesville <- twListToDF(Gainesville_tweets22)
Orlando <- twListToDF(Orlando_tweets23)
Jacksonville <- twListToDF(Jacksonville_tweets24)
Tempa <- twListToDF(Tempa_tweets25)

## save data into csv files
write.csv(Gainesville, file = "Gainesville_tweets.csv", row.names = F)
write.csv(Tallahassee, file = "Tallahassee_tweets.csv", row.names = F)
write.csv(Orlando, file = "Orlando_tweets.csv", row.names = F)
write.csv(Jacksonville, file = "Jacksonville_tweets.csv", row.names = F)
write.csv(Tempa, file = "Tempa_tweets.csv", row.names = F)


## ======================= ##
## 2. Prepare Tweets
## ======================= ##

## Read saved tweets
# Gainesville <- read.csv(file = "Data/Gainesville_tweets.csv")
# Tallahassee <- read.csv(file = "Data/Tallahassee_tweets.csv")
# Jacksonville <- read.csv(file = "Data/Jacksonville_tweets.csv")
# Orlando <- read.csv(file = "Data/Orlando_tweets.csv")
# Tempa <- read.csv(file = "Data/Tempa_tweets.csv")

Data_files <- list.files(path = "Data", pattern = "csv", full.names = TRUE)

Cleaned_Data <- list()
i <- 1

## Remove the emoji and stopwords
for (data in Data_files) {
  MyData <- read.csv(file = data, header = T)
  
  data <- as.data.frame(data)
  City_Index <- data %>% separate(data, into = c('useless1', 'City', "useless2"), sep = c(5, -11))
  
  ## Create a corpus, which is a collection of text documents
  myCorpus <- Corpus(VectorSource(MyData$text))
  myCorpus <- tm_map(myCorpus, tolower)
  
  ## remove punctuation
  myCorpus <- tm_map(myCorpus, removePunctuation)
  
  ## remove numbers
  myCorpus <- tm_map(myCorpus, removeNumbers)
  
  ## define stopwords
  myStopwords <- c(stopwords('english'), "@", "#")
  
  ## keep "r"
  idx <- which(myStopwords == "r")  
  
  ## remove stopwords
  myStopwords <- myStopwords[-idx]
  
  myCorpus <- tm_map(myCorpus, removeWords, myStopwords)
  
  Cleaned_Data[[i]] <- myCorpus
  names(Cleaned_Data)[[i]] <- City_Index$City
  i <- i +1 
}

## ============================================ ##
## 3. Define Function for Sentiment Analysis
## ============================================ ##

## install dictionary 
Neg <- scan(file ="Dict/negative-words.txt", what = "character", comment.char = ";" )
Pos <- scan(file ="Dict/positive-words.txt", what = "character", comment.char = ";" )

## write function score.sentiment to prepare tweets
score.sentiment <- function(sentences, pos.words, neg.words, .progress='none'){
 
  require(plyr)# plyr will handle a list or a vector 
  require(stringr)

  scores <- laply(sentences, function(sentence, pos.words, neg.words) {
  ## Clean up sentences with R's regex-driven global substitute, gsub():
  sentence <- gsub('[[:punct:]]', '', sentence)
  sentence <- gsub('[[:cntrl:]]', '', sentence)
  sentence <- gsub('\\d+', '', sentence)
  
  ## Convert to lower case:
  sentence <- tolower(sentence)
  
  ## Tokenization: split into words
  ## Use str_split function from the stringr package
  word.list <- str_split(sentence, '\\s+')
  
  ## unlist the word.list
  words <- unlist(word.list)
  
  ## Match the extracted words to the dictionaries to determine positive & negative terms
  pos.matches <- match(words, pos.words)
  neg.matches <- match(words, neg.words)
  
  ## Change the output to TRUE/FALSE
  ## Since match() returns the position of the matched term or NA
  pos.matches <- !is.na(pos.matches)
  neg.matches <- !is.na(neg.matches)
  
  ## Conveniently enough, convert TRUE/FALSE to 1/0 and sum 
  score <- sum(pos.matches) - sum(neg.matches)
  return(score)}, 
  
  pos.words,
  neg.words,
  .progress = .progress)
  
  scores.df <- data.frame(score = scores, 
                          text = sentences)
  return(scores.df)
}



## =================================================================== ##
## 4. Sentiment Analysis with Self-defined Function "score.sentiment"
## =================================================================== ##

## Check clearned data 
# for (i in 1:5) {
#   Mydata <- Cleaned_Data[[i]]
#   print(names(Mydata))
#   print(str(Mydata))
# }

## Sentiment Analysis with Self-defined Function "score.sentiment"
Scored_tweets <- list()
i <- 1

for (data in Data_files) {
  MyData <- read.csv(file = data, header = T)
  
  data <- as.data.frame(data)
  City_Index <- data %>% separate(data, into = c('useless1', 'City', "useless2"), sep = c(5, -11))
  
  MyData_text <- MyData$text
  MyData_scores <- score.sentiment(MyData_text, Pos, Neg, .progress = "text")
  
  Scored_tweets[[i]] <-MyData_scores
  names(Scored_tweets)[[i]] <- City_Index$City
  i <- i +1 
}


