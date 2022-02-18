# -*- coding: utf-8 -*-
"""
File:   train.py
Author: Huan KUANG
Date: Nov.30, 2020  
Desc: Test the performance of the trained CNN model  
	
"""

""" ==================  Import the needed packages ======================= """

import math 
import random 
import numpy as np
import pandas as pd
import collections
import matplotlib.pyplot as plt
import torch
from torch.autograd import Variable
import torchvision
from torchvision import transforms
from sklearn.metrics import confusion_matrix
from sklearn.metrics import accuracy_score


""" ======================  Function definitions ========================== """
##################################
## Define function 1: the CNN function
class CNN(torch.nn.Module):
	"""docstring for CNN"""
	def __init__(self, batch_size = 16, channel = 64, k_size_cov = (4, 4), step = 2, k_size_pool = 2, cnn_out = 64, fc_out = 512, class_num = 5):
		super(CNN, self).__init__()

		self.channel = channel
		self.cnn_out = cnn_out
		self.batch_size = batch_size

		self.layer_1 = torch.nn.Sequential(
			torch.nn.Conv2d(3, channel, k_size_cov, stride = step),
			torch.nn.ReLU(),
			torch.nn.MaxPool2d(k_size_pool, stride = 2, padding = 0)
			)

		self.layer_2 = torch.nn.Sequential(
			torch.nn.Conv2d(channel, cnn_out, k_size_cov, stride = step),
			torch.nn.ReLU(),
			torch.nn.MaxPool2d(k_size_pool, stride = 2, padding = 0)
			)

		self.dropout_1 = torch.nn.Dropout(0.2)
		self.fc_1 = torch.nn.Linear(cnn_out*11*11, fc_out)
		self.dropout_2 = torch.nn.Dropout(0.2)
		self.fc_2 = torch.nn.Linear(fc_out, 64)
		self.fc_3 = torch.nn.Linear(64, class_num)

	def forward(self, x):
		out = self.layer_1(x)
		out = self.layer_2(out)		
		out = torch.flatten(out, 1)
		out = self.fc_1(out)
		out = self.dropout_2(out)
		out = self.fc_2(out)
		out = self.fc_3(out)
		return out


##################################
## Define function 2: the test_model function
def test_model(model, test_x):
	predictions = np.array([])

	for img in test_x:
		img = Variable(img[0])
		outputs = model(img)
		_, predicted = torch.max(outputs.data, 1)
		predictions = np.concatenate((predictions, predicted.numpy()), axis = None)

	## save the predicted labels
	np.save("prediction.npy", predictions) 


""" ======================  Load the tained CNN  ========================== """
## This file has the trained parameters
## It can be found in the repo
PATH = "final_cnn_model_1.pt"
b_s = 32
cnn_cls = CNN(batch_size = b_s)
cnn_cls.load_state_dict(torch.load(PATH))


""" =================  Load and reshape the test data  ==================== """
print ("===========================================================")
print('IMPORTANT! Please enter the path where the test data is stored!')
print ("===========================================================")
Images = np.load(input("[Enter the test data path name]:\n"))

cx_test_np = Images/255 ## Normalization (range 0~1)

transform = transforms.ToTensor() ## reshape the data
cx_test = torch.reshape(torch.from_numpy(cx_test_np), (-1, 3, 200, 200))
test_data_set = torch.utils.data.TensorDataset(cx_test)
test_data = torch.utils.data.DataLoader(test_data_set, batch_size = b_s)


""" ==========  Test and Evaluate the performance of the trained CNN ======== """
print("Running")
test_model(cnn_cls, test_data)
print ("===========================================================")
print('IMPORTANT! A vector with the class label associated with each input image has been generated. Please see in "prediction.npy".')
print ("===========================================================")