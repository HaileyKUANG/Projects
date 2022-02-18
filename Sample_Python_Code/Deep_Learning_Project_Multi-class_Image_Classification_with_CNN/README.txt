#################################################################################
##  Deep_Learning_Project_Multi-class_Image_Classification_with_CNN
#################################################################################
## Team Members:
Hailey KUANG

##=============================================##
## The following illustrates how to run my code 
##=============================================##
## 1. Dependencies 

* ```math```
* ```random```
* ```panda```
* ```numpy```
* ```matplotlib```

* ```sklearn```
* ```torch```
* ```torchvision```
* ```skimage```

##=============================================##
## 2. train.py 
The "CNN" function defines the has two convolutional layers, two pooling layers, and three fully connected layers in the CNN.(Line 36-89)
The "train_model" function defines the loss function, optimization method, learning rate, epoch, patience, and specifies the training and validation set.(Line 95-169)
The "Setup Mode" section (Line 172-184) checks the availability of GPU.
The "Import data" section (Line 187-214) reads the data, checks the shape, size, etc of the input numpy array, as well as plots the input images.
The "Create training and test sets" section (Line 217-301) splits each class into training and test sets since the five classes had unbalanced sample sizes.
The "Cross Validation" section (Line 357-416) creates cross-validation within the above-mentioned training sets, and trains the CNN with the training data. Learning rate value, etc, can be changed from Line 411-413.

##=============================================##
## 3. test.py 
The "CNN" function is exactly the same as the "CNN" function in "train.py" which defines layers, in the CNN.(Line 29-64)
The "test_model" function predicts the input data based on the saved model and saves the predictions in "prediction.npy". (Line 69-79)
The "Load the trained CNN" section (Line 82- 88) loads the saved parameters for the trained CNN.
The "Load and reshape the test data" section (Line 91-102) asks to ENTER THE PATH WHERE THE TEST DATA IS STORED during the process and transfers the input data to the desired format for the CNN model.
The last section (Line 105-109) allows running the test_model.

##=============================================##
## 4. final_cnn_model_1.pt
The "final_cnn_model_1.pt" file save the trained parameters for the CNN.
It can be found in the GitHub repository.
It is loaded and used in the "test.py" by the following commend "PATH = "final_cnn_model_1.pt"".
Please make sure it is in the same directory as "test.py". Otherwise, you have to specify the PATH in the "test.py"

##=============================================##
## 5. prediction.npy
It will be generated after successfully running "test.py". 
It contains a vector with the predicted class label associated with each input image.
You should be able to find it in the same directory as "test.py".
