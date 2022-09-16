# -*- coding: UTF-8 -*-
"""
File:   Evaluation.py
Author: Hailey
Date: Nov.06, 2021
Desc:   1. This file evaluate the performance of the trained LSTM model
        2. The predicted/generated captions will be provided for an given image by running this script
        3. The BLEU-1 score will be compute based on predicted captions and the original captions
"""

""" ==================  Import the needed packages ======================= """
import numpy as np
import tensorflow as tf

from pickle import load
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras.applications.vgg16 import VGG16, preprocess_input
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from tensorflow.keras.models import Model, load_model
from nltk.translate.bleu_score import corpus_bleu

""" ==================  Check GPU for tensorflow  ======================== """
print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))

""" ==================  Define Needed Functions ========================== """
## Part 1: Extract image features
## function 1: extract_features
## extract features from a specific image
def extract_features(filename):
    model = VGG16() ## load VGG16
    model.layers.pop() ## re-structure the model
    model = Model(inputs=model.inputs, outputs=model.layers[-1].output)
    image = load_img(filename, target_size=(224, 224)) ## load image
    image = img_to_array(image)
    image = image.reshape((1, image.shape[0], image.shape[1], image.shape[2]))
    image = preprocess_input(image)
    feature = model.predict(image, verbose=0) ## get features
    return feature


## Part 2: Generate caption
## function 2: generate_cap
## generate a caption for an input image
def generate_cap(model, tokenizer, photo, index_word, max_length, beam_size=5):
  captions = [['startseq', 0.0]]
  in_text = 'startseq'
  for i in range(max_length):
    all_caps = []
    for cap in captions:
      sentence, score = cap
      if sentence.split()[-1] == 'endseq':
        all_caps.append(cap)
        continue
      sequence = tokenizer.texts_to_sequences([sentence])[0]
      sequence = pad_sequences([sequence], maxlen=max_length)
      y_pred = model.predict([photo,sequence], verbose=0)[0]
      yhats = np.argsort(y_pred)[-beam_size:]

      for j in yhats:
        word = index_word.get(j) ## map integer to word
        if word is None:
          continue
        caption = [sentence + ' ' + word, score + np.log(y_pred[j])]
        all_caps.append(caption)

    ordered = sorted(all_caps, key=lambda tup:tup[1], reverse=True)
    captions = ordered[:beam_size]

  return captions

## function 3: load_docu
## will be used in load_set and load_clean_descriptions
def load_docu(filename):
        file = open(filename, 'r') # open the file as read only
        text = file.read()
        file.close()
        return text

## function 4: load_clean_descriptions
## load the captions originally in the dataset
def load_clean_descriptions(filename, dataset):
    doc = load_docu(filename)
    descriptions = dict()
    for line in doc.split('\n'):
        tokens = line.split()
        image_id, image_desc = tokens[0], tokens[1:]
        if image_id in dataset:
            if image_id not in descriptions:
                descriptions[image_id] = list()
            desc = 'startseq ' + ' '.join(image_desc) + ' endseq'
            descriptions[image_id].append(desc)
    return descriptions

""" ==================  Evaluate Model =================================== """
## load the needed parameters
model = load_model("9. Result/model-ep005-loss2.858-val_loss3.114.h5")
tokenizer = load(open('9. Result/tokenizer.pkl', 'rb'))
image_feature = extract_features("9. Result/2950637275_98f1e30cca.jpg")
index_word = load(open('9. Result/index_word.pkl', 'rb'))
max_length = 34
captions = generate_cap(model, tokenizer, image_feature, index_word, max_length)

## print the predicted/generated captions
for cap in captions:
    seq = cap[0].split()[1:-1]# remove start and end tokens
    desc = ' '.join(seq)
    print('{} [log prob: {:1.2f}]'.format(desc,cap[1]))

## load original captions
or_descriptions = load_clean_descriptions('9. Result/descriptions.txt', "2950637275_98f1e30cca.jpg")

## Compute BLEU
actual = list()
predicted = list()
for key, desc_list in or_descriptions.items():
    pred = generate_cap(model, tokenizer, image_feature, index_word, max_length)[0]
    # print("Predicted", pred[0].split())
    predicted.append(pred[0].split())
    # print("Predicted", predicted)
    references = [d.split() for d in desc_list]
    # print("Originally", references)
    actual.append(references)
    # print("Originally", actual)
    ## calculate BLEU score
print('BLEU-1: %f' % corpus_bleu(actual, predicted, weights=(1.0, 0, 0, 0)))
