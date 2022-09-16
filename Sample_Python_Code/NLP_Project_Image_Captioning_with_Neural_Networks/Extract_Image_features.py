# -*- coding: UTF-8 -*-
"""
File:   Extract_Image_features.py
Author: Hailey
Date: Nov.05, 2021
Desc:   1. This file extract image feature via VGG16
        2. The predicted features will be saved
        3. The cleaned original captions will be saved
"""

""" ==================  Import the needed packages ======================= """
import numpy as np
import string
import tensorflow as tf

from os import listdir
from pickle import dump
from progressbar import progressbar
from tensorflow.keras.applications.vgg16 import VGG16, preprocess_input
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from tensorflow.keras.layers import Reshape
from tensorflow.keras.models import Model

""" ==================  Check GPU for tensorflow  ======================== """
print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))

""" ==================  Define Needed Functions ========================== """
## Part 1: Image Preparation
## function 1: load_image
## load an image from filepath
def load_image(path):
    img = load_img(path, target_size=(224,224))
    img = img_to_array(img)
    img = np.expand_dims(img, axis=0)
    img = preprocess_input(img)
    return np.asarray(img)


## function 2: extract_features
## extract features from each iamges i
def extract_features(directory):
  model = VGG16()  ## load VGG16
  model.layers.pop()  ## re-structure the model
  model = Model(inputs=model.inputs, outputs=model.layers[-1].output)
  print(model.summary())
  features = dict()
  for name in progressbar(listdir(directory)):
    filename = directory + '/' + name
    image = load_image(filename)  ## load image
    feature = model.predict(image, verbose=0)  ## get features
    image_id = name.split('.')[0]
    features[image_id] = feature
    print('>%s' % name)
  return feature


## Part 2: Original Caption Clean
## function 3: load_docu
## load original captions
def load_docu(filename):
  file = open(filename, 'r')
  text = file.read()
  file.close()
  return text


## function 4: load_cap
## Identify the corresponding captions for a given images (via image_id)
def load_cap(doc):
  mapping = dict()
  for line in doc.split('\n'):
    tokens = line.split()
    if len(line) < 2:
      continue
    image_id, image_desc = tokens[0], tokens[1:]
    image_id = image_id.split('.')[0]
    image_desc = ' '.join(image_desc)
    if image_id not in mapping:
      mapping[image_id] = list()
    mapping[image_id].append(image_desc)
  return mapping


## function 5: clean_cap
## Clean the captions by removing useless components
def clean_cap(descriptions):
  table = str.maketrans('', '', string.punctuation)
  for key, desc_list in descriptions.items():
    for i in range(len(desc_list)):
      desc = desc_list[i]
      desc = desc.split()  ## tokenize
      desc = [word.lower() for word in desc] ## convert to lower case
      desc = [w.translate(table) for w in desc] ## remove punctuation from each token
      desc = [word for word in desc if len(word)>1] ## remove hanging 's' and 'a'
      desc = [word for word in desc if word.isalpha()] ## remove tokens with numbers in them
      desc_list[i] =  ' '.join(desc)


## function 6: to_vocabulary
## convert captions into words
def to_vocabulary(descriptions):
  all_desc = set()
  for key in descriptions.keys():
    [all_desc.update(d.split()) for d in descriptions[key]]
  return all_desc


## function 7: save_cap
## save cleaned captions to file, one per line
def save_cap(descriptions, filename):
  lines = list()
  for key, desc_list in descriptions.items():
    for desc in desc_list:
      lines.append(key + ' ' + desc)
  data = '\n'.join(lines)
  file = open(filename, 'w')
  file.write(data)
  file.close()


""" =============== Extract Features from all Images ===================== """
directory = 'Flickr8k_Dataset'
features = extract_features(directory)
print('Extracted Features: %d' % len(features))
dump(features, open('models/features.pkl', 'wb')) ## save to file


""" =============== Clean Original Caption  ============================== """
filename = 'Flickr8k_text/Flickr8k.token.txt'
doc = load_docu(filename) ## load original captions
descriptions = load_cap(doc)
print('Loaded: %d ' % len(descriptions))
clean_cap(descriptions)
vocabulary = to_vocabulary(descriptions)
print('Vocabulary Size: %d' % len(vocabulary))
save_cap(descriptions, 'models/descriptions.txt')
