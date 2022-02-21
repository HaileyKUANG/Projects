##===========================================================##
##                Sentiment Analysis of Twitter              ##
##===========================================================##

## Install needed packages
Packages <- c("twitteR", "RCurl", "bitops", "tm", "slam", 
              "wordcloud", "NLP", "lavaan", "RCurl", "syuzhet",
              "glue", "stringr", "lubridate", "scales", "reshape2",
              "plyr", "tidyr", "dplyr", "tidytext",  "tidyverse",
              "ggplot2", "Unicode")

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

# ## Get tweets which include both UF and FSU for Orlando
# Orlando_tweets23 <- searchTwitter("UF+FSU", n = 1000, lang = "en", since = '2017-11-25',
#                              until = '2017-11-26', geocode = '28.534346,-81.382840,30mi')

## Get tweets which include both UF and FSU for Jacksonville
Jacksonville_tweets24 <- searchTwitter("UF+FSU", n = 1000, lang = "en", since = '2017-11-25',
                             until = '2017-11-26', geocode = '30.328098,-81.637842,30mi')

## Get tweets which include both UF and FSU for Tempa
Tempa_tweets25 <- searchTwitter("UF+FSU", n = 1000, lang = "en", since = '2017-11-25',
                             until = '2017-11-26', geocode = '27.933248,-82.484548,30mi')

## write data into data frame
Tallahassee <- twListToDF(Tallahassee_tweets21)
Gainesville <- twListToDF(Gainesville_tweets22)
# Orlando <- twListToDF(Orlando_tweets23)
Jacksonville <- twListToDF(Jacksonville_tweets24)
Tempa <- twListToDF(Tempa_tweets25)

## save data into csv files
write.csv(Gainesville, file = "Gainesville_tweets.csv", row.names = F)
write.csv(Tallahassee, file = "Tallahassee_tweets.csv", row.names = F)
# write.csv(Orlando, file = "Orlando_tweets.csv", row.names = F)
write.csv(Jacksonville, file = "Jacksonville_tweets.csv", row.names = F)
write.csv(Tempa, file = "Tempa_tweets.csv", row.names = F)


## ==================================================== ##
## 2. Prepare Term Document Matrix (TDM) and/or DTM
## ==================================================== ##

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
  
  ## Removing all non utf-8 characters
  mytext <- iconv(MyData$text, from = "", to = "utf-8", sub="")
  ## Removing all non-ASCII characters
  mytext <- iconv(mytext, from = "", to = "ASCII", sub="")
  
  ## Create a corpus, which is a collection of text documents
  myCorpus <- Corpus(VectorSource(mytext))
  
  ## Do not use Unicode_alphabetic_tokenizer for now
  ## Unicode_alphabetic_tokenizer will collapse among tweets
  # mytext_unicode <- Unicode_alphabetic_tokenizer(myCorpus)
  # myCorpus <- Corpus(VectorSource(mytext_unicode))
  
  ## Working with "tm" package for corpus transformations 
  ## Convert to lower case
  myCorpus <- tm_map(myCorpus, content_transformer(tolower))
  
  ## Define stopwords
  myStopwords <- c(stopwords('english'), "@", "#")
  
  # ## keep "r"
  # idx <- which(myStopwords == "r")  
  # myStopwords <- myStopwords[-idx]
  
  ## Remove stopwords
  myCorpus <- tm_map(myCorpus, removeWords, myStopwords)
  
  ## Remove punctuation
  myCorpus <- tm_map(myCorpus, removePunctuation)
  
  ## Remove numbers
  myCorpus <- tm_map(myCorpus, removeNumbers)

  ## Strip white space
  myCorpus <- tm_map(myCorpus, stripWhitespace)
  
  ## Remove URL
  removeURL <- function(x) gsub(pattern = "http[[:alnum:]]*", replacement = "", x)
  myCorpus <- tm_map(myCorpus, content_transformer(removeURL))  
  
  ## Stemming
  clean_Text <- tm_map(myCorpus, stemDocument)
  
  ## Term document matrix
  # Term_Text <- TermDocumentMatrix(clean_Text)
  Term_Text <- DocumentTermMatrix(clean_Text)
  Term_Text <- as.matrix(Term_Text)
  
  ## Save cleaned data
  Cleaned_Data[[i]] <- Term_Text
  names(Cleaned_Data)[[i]] <- City_Index$City
  i <- i +1 
}

## =================================================================== ##
## 3. Explore Cleaned DTM (Wordcloud)
## =================================================================== ##

# Check clearned data
for (i in 1:4) {
  mydata <- Cleaned_Data[[i]]
  
  # print(str(mydata))
  # print(row.names(mydata))
  
  ## Determine the High Frequency Words
  mydata_t <- as.data.frame(t(mydata))
  mydata_t$weights <- rowSums(mydata_t)
  
  # HF_word <- subset(mydata_t, weights >= 10)
  # print(barplot(HF_word,
  #         las = 2,
  #         col = rainbow(50)))
  
  ## Wordcloud
  set.seed(222)
  wordcloud(words = row.names(mydata_t),
            freq = mydata_t$weights,
            max.words = 100,
            random.order = F,
            min.freq = 3,
            colors = brewer.pal(8, "Dark2"),
            scale = c(4, 0.5))
}

## ============================================== ##
## 4.Sentiment Analysis with "syuzhet" package
## ============================================== ##
SA_tweets <- list()
i <- 1

for (data in Data_files) {
  MyData <- read.csv(file = data, header = T)
  
  data <- as.data.frame(data)
  City_Index <- data %>% separate(data, into = c('useless1', 'City', "useless2"), sep = c(5, -11))
  
  ## Removing all non utf-8 characters
  mytext <- iconv(MyData$text, from = "", to = "utf-8", sub="")
  
  ## Removing all non-ASCII characters
  mytext <- iconv(mytext, from = "", to = "ASCII", sub="")
  
  ## Convert to lower case
  mytext <- tolower(mytext)
  
  ## Remove "RT @ ..." which indicates a retweet
  mytext <- gsub("(rt|via)((?:\\b\\W*@\\w+)+)", "", mytext) 
  
  ## Remove ": viewer email:" which indicates @people
  mytext <- gsub("\\viewer email", "", mytext)
  
  ## Remove URL
  mytext <- gsub('http\\S*', "", mytext)
  
  ## Remove punctuations
  mytext <- gsub('[[:punct:]]', '', mytext)
  
  ## Remove control characters, such as \n or \r , [\x00-\x1F\x7F] 
  mytext <- gsub('[[:cntrl:]]', '', mytext)
  
  ## Remove digit characters
  mytext <- gsub('\\d+', '', mytext)
  
  ## Obtain sentiment scores on 10 dimensions
  ## 1) anger 
  ## 2) anticipation 
  ## 3) disgust 
  ## 4) fear 
  ## 5) joy 
  ## 6) sadness 
  ## 7) surprise 
  ## 8) trust 
  ## 9) negative 
  ## 10) positive
  SA_output <- get_nrc_sentiment(mytext)
  
  SA_tweets[[i]] <- SA_output
  names(SA_tweets)[[i]] <- City_Index$City
  i <- i +1 
}


## ===================================================== ##
## 5.Sentiment Analysis with "score.sentiment" Function 
## ===================================================== ##

## Dictionary for "score.sentiment" 
## Download from http://www.cs.uic.edu/~liub/FBS/sentiment-analysis.html
## It is a dictionary for Opinion Mining, Sentiment Analysis, and Opinion Spam Detection 

## load dictionary 
Neg <- scan(file ="Dict/negative-words.txt", what = "character", comment.char = ";" )
Pos <- scan(file ="Dict/positive-words.txt", what = "character", comment.char = ";" )

## Simple version:
## Return one indicator (Total Positive - Total Negative) for each tweet 
## Define "score.sentiment" function  to prepare tweets

score.sentiment <- function(sentences, pos.words, neg.words, .progress='none'){
 
  require(plyr)# plyr will handle a list or a vector 
  require(stringr)

  scores <- laply(sentences, function(sentence, pos.words, neg.words) {
    
    ## Removing all non utf-8 characters
    sentences <- iconv(sentences, from = "", to = "utf-8", sub="")
    
    ## Removing all non-ASCII characters
    sentences <- iconv(sentences, from = "", to = "ASCII", sub="")
    
    ## Convert to lower case
    sentences <- tolower(sentences)
    
    ## Clean up sentences with gsub()
    ## Remove "RT @ ..." which indicates a retweet
    sentences <- gsub("(rt|via)((?:\\b\\W*@\\w+)+)", "", sentences)
    
    ## Remove ": viewer email:" which indicates @people
    sentences <- gsub("\\viewer email", "", sentences)
    
    ## Remove URL
    sentences <- gsub('http\\S*', "", sentences)
    
    ## Remove punctuations
    sentence <- gsub('[[:punct:]]', '', sentence)
    
    ## Remove control characters, such as \n or \r , [\x00-\x1F\x7F]
    sentence <- gsub('[[:cntrl:]]', '', sentence)
    
    ## Remove digit characters
    sentence <- gsub('\\d+', '', sentence)
    
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



