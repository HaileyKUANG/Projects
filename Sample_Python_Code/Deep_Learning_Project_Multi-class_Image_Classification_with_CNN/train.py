# -*- coding: utf-8 -*-
"""
File:   train.py
Author: Hailey
Date: Nov.30, 2020  
Desc: Train the CNN model  
	
"""

""" ==================  Import the needed packages ======================= """
import math 
import random 
import pandas as pd

import numpy as np
import matplotlib.pyplot as plt
import collections

import torch
from torch.autograd import Variable
from sklearn.model_selection import KFold
from sklearn.model_selection import train_test_split
from sklearn.linear_model import SGDClassifier

import torchvision
from torchvision import transforms

from skimage.color import rgb2grey
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import f1_score, recall_score, precision_score

""" ======================  Function definitions ========================== """
##################################
## Define function 1: the CNN function
class CNN(torch.nn.Module):
	def __init__(self, batch_size = 16, channel = 64, k_size_cov = (4, 4), step = 2, k_size_pool = 2, cnn_out = 64, fc_out = 512, class_num = 5):
		super(CNN, self).__init__()

		self.channel = channel
		self.cnn_out = cnn_out
		self.batch_size = batch_size

		self.layer_1 = torch.nn.Sequential(
			torch.nn.Conv2d(3, channel, k_size_cov, stride = step),
			torch.nn.ReLU(),
			torch.nn.MaxPool2d(k_size_pool, stride = 2, padding = 0)
			) ## the first convolution layer + ReLU + max pooling layer

		self.layer_2 = torch.nn.Sequential(
			torch.nn.Conv2d(channel, cnn_out, k_size_cov, stride = step),
			torch.nn.ReLU(),
			torch.nn.MaxPool2d(k_size_pool, stride = 2, padding = 0)
			) ## the second convolution layer + ReLU + max pooling layer

		self.dropout_1 = torch.nn.Dropout(0.2) ## the first dropout layer
		self.fc_1 = torch.nn.Linear(cnn_out*11*11, fc_out) ## the first FC layer

		self.dropout_2 = torch.nn.Dropout(0.2) ## the second dropout layer
		self.fc_2 = torch.nn.Linear(fc_out, 64) ## the second FC layer

		self.fc_3 = torch.nn.Linear(64, class_num) ## the output layer



	def forward(self, x):
		out = self.layer_1(x)
		# print("Layer_1 out size:", out.shape)
		out = self.layer_2(out)	
		# print("Layer_2 out size:", out.shape)
		
		# out = self.dropout_1(out)

		out = torch.flatten(out, 1)
		# print("Flatten out size:", out.shape)
# 
		out = self.fc_1(out)
		# print("FC_1 out size:", out.shape)

		out = self.dropout_2(out)
		# print("FC_1 after drop out size:", out.shape)

		out = self.fc_2(out)
		# print("FC_2 out size:", out.shape)

		out = self.fc_3(out)
		# print("FC_3 out size:", out.shape)

		return out



##################################
## Define function 2: the train_model function
def train_model(model, train, valid, fold, learning_rate = 0.001, epoch = 100, patience = 3):

	loss_fnc = torch.nn.CrossEntropyLoss()
	optimizer = torch.optim.Adam(model.parameters(), learning_rate)

	old_valid_loss = 1000 ## A number larger than any loss

	train_size = len(train)
	valid_size = len(valid)

	counter = 0

	print("Training......")

	for _ in range(epoch):

		train_loss = 0 ## for this epoch, the initial values for train set
		for img, label in train:

			img, label = Variable(img).to(device), Variable(label).to(device)

			optimizer.zero_grad()
			output = model(img)
			# print(output.shape)

			loss = loss_fnc(output, label)
			train_loss += loss.item()

			loss.backward()
			optimizer.step()

			if torch.isnan(loss):
				print(img)
				print(img.size())

		print("Train loss = {:.2f}".format(train_loss/train_size))
		

		# print(f"Train loss = {loss}")

		val_loss = 0 ## for this epoch, the initial values for validation set
		for img, label in valid:
			# img, label = img.to(device), label.to(device)
			img, label = Variable(img).to(device), Variable(label).to(device)	 
			output = model(img)

			val_loss += loss_fnc(output, label).item()

		print("validation loss = {:.2f}".format(val_loss/valid_size))
		

		## set stop criteria
		if old_valid_loss - val_loss < 1e-2:
			counter += 1
			if(counter > patience):
				break
		else:
			old_valid_loss = val_loss
			torch.save(model.state_dict(), './cnn_model_'+str(fold)+'.pt')
			counter = 0


	## calculate accuracy
	correct = 0
	total = 0

	for img, label in valid:
		img, label = Variable(img).to(device), Variable(label).to(device)
		outputs = model(img)
		_, predicted = torch.max(outputs.data, 1)	
		total += label.size(0)
		correct += (predicted == label).sum().item()
		# cmatrix = confusion_matrix(label, predicted)
	print('Accuracy of the network on validation set: %d %%' % (100 * correct / total))
	# print("Confusion matrix on validation data:", cmatrix)


""" =========================   Setup Mode  =============================== """
print ("===========================================================")
print ("Part 0: Detect GPU")

dtype = torch.float
# device = torch.device("cpu")
if torch.cuda.is_available():
    device = torch.device("cuda:0") 
    print("Running on the GPU")
else:
    device = torch.device("cpu")
    print("Running on the CPU")
# torch.backends.cuda.matmul.allow_tf32 = False  # Uncomment this to run on GPU


""" =========================  Import data =============================== """
print ("===========================================================")
print ("Part 1: Import Data")

Labels = np.load('C:/Users/chena/Desktop/EEL 5840/2. Assignments/Project/Labels_32.npy')
# print ("here are the Labels", Labels)
print("The number of images in each class:", collections.Counter(Labels))
## C0: 1949; 
## C1: 2112;
## C2: 2575;
## C3: 3420;
## C4: 1327;
## Total: 11383

Images = np.load('C:/Users/chena/Desktop/EEL 5840/2. Assignments/Project/Images_32.npy')
# print("here is the image size", Images.size)
print("The shape of the image set:", Images.shape)
# print(Images[1])
# print(Images[1].shape)

# # plot image
# i = 0
# for image in Images:
# 	if i%500 == 0:
# 		print("here is image", i)
# 		plt.imshow(image/255)	
# 		plt.show()
# 	i = i + 1


""" ================  Create training and test sets ======================== """
print ("===========================================================")
print ("Part 2: Create training and test sets")


##################################
# Identify the images in each of the five classes
Images_gp1 = []
Images_gp2 = []
Images_gp3 = []
Images_gp4 = []
Images_gp5 = []

label_gp1 = []
label_gp2 = []
label_gp3 = []
label_gp4 = []
label_gp5 = []

##################################
## Split five groups
for i in range(len(Images)):
	if Labels[i] == 0:
		Images_gp1.append(Images[i])
		label_gp1.append(0)
	elif Labels[i] == 1:
		Images_gp2.append(Images[i])
		label_gp2.append(1)
	elif Labels[i] == 2:
		Images_gp3.append(Images[i])
		label_gp3.append(2)
	elif Labels[i] == 3:
		Images_gp4.append(Images[i])
		label_gp4.append(3)
	else:
		Images_gp5.append(Images[i])
		label_gp5.append(4)


Images_gp1 = np.array(Images_gp1)
Images_gp2 = np.array(Images_gp2)
Images_gp3 = np.array(Images_gp3)
Images_gp4 = np.array(Images_gp4)
Images_gp5 = np.array(Images_gp5)

label_gp1 = np.array(label_gp1)
label_gp2 = np.array(label_gp2)
label_gp3 = np.array(label_gp3)
label_gp4 = np.array(label_gp4)
label_gp5 = np.array(label_gp5)

img_train = np.array([])
label_train = np.array([])
img_test = np.array([])
label_test = np.array([])

img_list = [Images_gp1, Images_gp2, Images_gp3, Images_gp4, Images_gp5]
lbs_list = [label_gp1, label_gp2, label_gp3, label_gp4, label_gp5]

##################################
## assign data into train or test sets
for i in range(5):
	imgs = img_list[i]
	lbs = lbs_list[i]

	myindex = np.random.permutation(len(imgs))
	train_index = myindex[:int(len(imgs)*0.6)] 
	# print("The location index for training set:", train_index)

	test_index = myindex[int(len(imgs)*0.6):]


	if img_train.size == 0:
		img_train = imgs[train_index]
		label_train = lbs[train_index]
	else:
		img_train = np.append(img_train, imgs[train_index])
		label_train = np.append(label_train, lbs[train_index])

	if img_test.size == 0:
		img_test = imgs[test_index]
		label_test = lbs[test_index]
	else:
		img_test = np.append(img_test, imgs[test_index])
		label_test = np.append(label_test, lbs[test_index])


##################################
print("Here is the shape of the training label:", label_train.shape)
# print("Here is the training label:", label_train)

mydtrain = int(len(img_train)/120000)
# print("Compute the number of images in training set", mydtrain)
img_train = np.reshape(img_train, (mydtrain, 200, 200, 3))
# print(img_train)

# plot image in my train
# i = 0
# for image in img_train:
# 	if i%500 == 0:
# 		print("here is image", i)
# 		plt.imshow(image/255)	
# 		plt.show()
# 	i = i + 1

print("Here is the shape of the training image:", img_train.shape)
# print("Here is the training image:", img_train)


##################################
print("Here is the shape of the test label:", label_test.shape)
# print("Here is the test label:", label_test)

# l = 0
# for label in label_test:
# 	if l%500 == 0:
# 		print("Here is lable for", l, label)
# 	l = l + 1

mydtest = int(len(img_test)/120000)
# print("Compute the number of images in training set", mydtest)
img_test = np.reshape(img_test, (mydtest, 200, 200, 3))

## plot image in my test
# i = 0
# for image in img_test:
# 	if i%500 == 0:
# 		print("here is image", i)
# 		plt.imshow(image/255)	
# 		plt.show()
# 	i = i + 1

print("Here is the shape of the test image:", img_test.shape)
# print("Here is the test image:", img_test)

##################################
## save the test set
np.save('img_test', img_test)
np.save('label_test', label_test)

""" ========================  Cross Validation ============================= """
print ("===========================================================")
print ("Part 3: Train the CNN")
print("Cross-validation was used, and the training data was split into 10 folds.")

kf10 = KFold(n_splits = 3, shuffle = True, random_state = None)

b_s = 32

fold = 0

for ctrain_index, ctest_index in kf10.split(img_train):
	cx_train_np, cx_test_np = img_train[ctrain_index], img_train[ctest_index] 
	cy_train_np, cy_test_np = label_train[ctrain_index], label_train[ctest_index]

	## Normalization (range 0~1)
	cx_train_np = cx_train_np/255
	cx_test_np = cx_test_np/255


	## Normalization (range -1~1)
	# cx_train_np = (cx_train_np - 127)/128
	# cx_test_np = (cx_test_np -127)/128

	# check for Nan
	# print(np.any(np.isnan(cx_train_np)))
	# print(np.any(np.isnan(cx_test_np)))

	
	## reshape the data
	train_label = torch.from_numpy(cy_train_np).type(torch.LongTensor)
	cx_train = torch.reshape(torch.from_numpy(cx_train_np), (-1, 3, 200, 200))
	# print(cx_train)

	test_label = torch.from_numpy(cy_test_np).type(torch.LongTensor)
	cx_test = torch.reshape(torch.from_numpy(cx_test_np), (-1, 3, 200, 200))

	train_data_set = torch.utils.data.TensorDataset(cx_train, train_label) ##.to(device)
	test_data_set = torch.utils.data.TensorDataset(cx_test, test_label) ##.to(device)
	
	train_set = torch.utils.data.DataLoader(train_data_set, batch_size = b_s, drop_last = True) ##.to(device)
	valid_set = torch.utils.data.DataLoader(test_data_set, batch_size = b_s, drop_last = True) ##.to(device)

	print("Creating model....")
	
	cnn_cls = CNN(batch_size = b_s)

	print("Move model to device....")
	cnn_cls.to(device)

	train_model(cnn_cls,
		train_set,
		valid_set,
		fold,
		epoch = 1000,
		learning_rate = 0.0001,
		patience = 10
		)

	fold += 1