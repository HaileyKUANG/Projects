# -*- coding: UTF-8 -*-
"""
File:   Project3_Train_LSTM.py
Author: Hailey KUANG
Date: Nov.05, 2021
Desc:   1. This file contains the information about training the LSTM model
        2. A trained model will be saved
"""

""" ==================  Import the needed packages ======================= """
import numpy as np
import tensorflow as tf

from pickle import dump, load

from tensorflow.keras.layers import Input, Concatenate, Dense, LSTM, Embedding, Dropout, RepeatVector
from tensorflow.keras.models import Model
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras.utils import to_categorical
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint

""" ==================  Check GPU for tensorflow  ======================== """
print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))

""" ==================  Define Needed Functions ========================== """
## Part 1: Data Preparation
## function 1: load_docu
## will be used in load_set and load_clean_descriptions
def load_docu(filename):
        file = open(filename, 'r') # open the file as read only
        text = file.read()
        file.close()
        return text


## function 2: load_set
def load_set(filename):
        doc = load_docu(filename)
        dataset = list()
        for line in doc.split('\n'):
                if len(line) < 1:
                        continue
                identifier = line.split('.')[0]
                dataset.append(identifier)
        return set(dataset)


## function 3: load_clean_descriptions
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


## function 4: load_photo_features
def load_photo_features(filename, dataset):
        all_features = load(open(filename, 'rb')) # 'rb' for reading binary file
        features = {k: all_features[k] for k in dataset}
        return features


## Part 2: Generate Model
## function 5: to_lines
## will be used in create_tokenizer and maxlen_words
def to_lines(descriptions):
        all_desc = list()
        for key in descriptions.keys():
                [all_desc.append(d) for d in descriptions[key]]
        return all_desc


## function 6: create_tokenizer
def create_tokenizer(descriptions):
        lines = to_lines(descriptions)
        tokenizer = Tokenizer()
        tokenizer.fit_on_texts(lines)
        return tokenizer


## function 7: maxlen_words
def maxlen_words(descriptions):
        lines = to_lines(descriptions)
        return max(len(d.split()) for d in lines)


## function 8: create_sequences
## create sequences of images, input sequences and output words for an image
## will be unsed in data_generator()
def create_sequences(tokenizer, max_length, desc_list, photo):
        vocab_size = len(tokenizer.word_index) + 1
        X1, X2, y = [], [], []
        for desc in desc_list:
                seq = tokenizer.texts_to_sequences([desc])[0]
                for i in range(1, len(seq)):
                        in_seq, out_seq = seq[:i], seq[i]
                        in_seq = pad_sequences([in_seq], maxlen=max_length)[0]
                        out_seq = to_categorical([out_seq], num_classes=vocab_size)[0]
                        X1.append(photo)
                        X2.append(in_seq)
                        y.append(out_seq)
        return np.array(X1), np.array(X2), np.array(y)


## function 9: data_generator
## Will be used in model.fit()
def data_generator(descriptions, photos, tokenizer, max_length, n_step = 1):
        while 1: # loop over photo identifiers in the dataset
                keys = list(descriptions.keys())
                for i in range(0, len(keys), n_step):
                        Ximages, XSeq, y = list(), list(),list()
                        for j in range(i, min(len(keys), i+n_step)):
                                image_id = keys[j]
                                photo = photos[image_id][0]
                                desc_list = descriptions[image_id]
                                in_img, in_seq, out_word = create_sequences(tokenizer, max_length, desc_list, photo)
                                for k in range(len(in_img)):
                                        Ximages.append(in_img[k])
                                        XSeq.append(in_seq[k])
                                        y.append(out_word[k])
                        yield [np.array(Ximages), np.array(XSeq)], np.array(y)


""" ==================  Prepare Data ===================================== """
# Load train/test elements
train = load_set('Flickr8k_text/Flickr_8k.trainImages.txt') # load training images ID (6K)
train_features = load_photo_features('models/features.pkl', train) # load training images features
train_descriptions = load_clean_descriptions('models/descriptions.txt', train) # load training text/description

test = load_set('Flickr8k_text/Flickr_8k.testImages.txt') # load testing images ID (1K)
test_features = load_photo_features('models/features.pkl', test) # load testing images features
test_descriptions = load_clean_descriptions('models/descriptions.txt', test) # load testing text/description

print('Training Dataset: %d' % len(train))
print('Testing Dataset: %d' % len(test))
print('Descriptions: train=%d, test=%d' % (len(train_descriptions), len(test_descriptions)))
print('Features for Photos: train=%d, test=%d' % (len(train_features), len(test_features)))

max_length = maxlen_words(train_descriptions) # determine the maximum sequence length
print('Description Length: %d' % max_length)

tokenizer = create_tokenizer(train_descriptions)
dump(tokenizer, open('models/tokenizer.pkl', 'wb'))  # save the tokenizer

index_word = {v: k for k, v in tokenizer.word_index.items()} # index_word dict
dump(index_word, open('models/index_word.pkl', 'wb')) # save dict

vocab_size = len(tokenizer.word_index) + 1
print('Vocabulary Size: %d' % vocab_size)

""" ==================  Train Model ====================================== """
## set the random seed
np.random.seed(8)
tf.random.set_seed(8)

## set hyperparameters
embedding_dim = 256

inp1_layer = Input(shape=(1000,)) # feature extractor (encoder)
drop_layer = Dropout(0.3)(inp1_layer)
dense_layer = Dense(embedding_dim, activation='relu')(drop_layer)
repeat_layer = RepeatVector(max_length)(dense_layer)

inp2_layer= Input(shape=(max_length,))
emb_layer = Embedding(vocab_size, embedding_dim, mask_zero=True)(inp2_layer) # embedding

merged_layer = Concatenate()([repeat_layer, emb_layer])
lstm_layer1 = LSTM(500, return_sequences=False)(merged_layer)
#dense_layer = Dense(500, activation='relu')(lstm_layer1)
outp_layer = Dense(vocab_size, activation='softmax')(lstm_layer1)


# tie it together [image, seq] [word]
model = Model(inputs=[inp1_layer, inp2_layer], outputs=outp_layer)
learning_rate = 0.005
optimizer = tf.keras.optimizers.Adam(learning_rate)

model.compile(loss='categorical_crossentropy',
              optimizer=optimizer,
              metrics=['accuracy'])
print(model.summary())

## define checkpoint callback
checkpoint = ModelCheckpoint(
        filepath='model-ep005-loss2.858-val_loss3.114.h5',
        save_best_only=True,
        monitor='val_loss',
        mode='min',
        verbose=1)

## create the data generator
train_generator = data_generator(train_descriptions, train_features, tokenizer, max_length)
val_generator = data_generator(test_descriptions, test_features, tokenizer, max_length)

steps = len(train_descriptions)
val_steps = len(test_descriptions)

## fit model
model.fit(train_generator,
          epochs=100,
          steps_per_epoch=steps,
          verbose=1,
          callbacks=[checkpoint],
          validation_data=val_generator,
          validation_steps=val_steps)

model.save('models/wholeModel_20211213.h5', overwrite=True)
model.save_weights('models/weights_20211213.h5',overwrite=True)



