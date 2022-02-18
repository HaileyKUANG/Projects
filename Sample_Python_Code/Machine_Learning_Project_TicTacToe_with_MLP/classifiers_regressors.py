# -*- coding: utf-8 -*-
"""
File:   classifiers_regressors.py
Author: Hailey KUANG
Date: Oct.01, 2021
Desc:
        Part 1. Binary Classification Task (Line 62-135)
        Classifiers with 10-fold cross validation on "Final boards classification dataset"
        1. linear SVM, 2. k-nearest neighbors, 3. multilayer perceptron.

        Part 2. Multi-class Classification Task (Line 136-226)
        Classifiers with 10-fold cross validation on "Intermediate boards optimal play (single label)"
        1. linear SVM, 2. k-nearest neighbors, 3. multilayer perceptron.

        Part 3. Multi-label Regressors (Line 227-264)
        Regressors with 10-fold cross validation on "Intermediate boards optimal play (multi label)"
        1. regression, 2. k-nearest neighbors, 3. multilayer perceptron.

"""

""" ==================  Import the needed packages ======================= """
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import pickle
from sklearn import utils
from sklearn import svm
from sklearn import metrics
from sklearn.metrics import confusion_matrix
from sklearn.model_selection import KFold
from sklearn.model_selection import cross_val_score
from sklearn.neighbors import KNeighborsClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.linear_model import LinearRegression
from skmultilearn.problem_transform import BinaryRelevance

##set display option
pd.set_option('display.max_columns', 10)

""" =========================  Read Data ================================= """

## Data for Binary Classification Task
Data_final = np.loadtxt("C:/Users/chena/Desktop/CIS 6930 Deep Learning Comp Graphics/Projects/P1/datasets-part1/tictac_final.txt")
X_final = Data_final[:, :9]
Y_final = Data_final[:, 9:]

## Data for Multi-class Classification Task
Data_single = np.loadtxt("C:/Users/chena/Desktop/CIS 6930 Deep Learning Comp Graphics/Projects/P1/datasets-part1/tictac_single.txt")
X_single = Data_single[:, :9]
Y_single = Data_single[:, 9:]

## Data for Multi-label regressors
Data_multi = np.loadtxt("C:/Users/chena/Desktop/CIS 6930 Deep Learning Comp Graphics/Projects/P1/datasets-part1/tictac_multi.txt")
X_multi = Data_multi[:, :9]
Y_multi = Data_multi[:, 9:]

## Set Cross Validation
kf10 = KFold(n_splits = 10,
             random_state = None,
             shuffle = True)

""" ==================  Binary Classification Task ======================= """
## Support Vector Machines
def SVM_smodel():
    svm_model = svm.SVC(kernel = 'linear', C=1)
    svm_model.fit(X_train, np.ravel(y_train))
    svm_y_pred = svm_model.predict(X_test)
    print("SVM Accuracy (Binary Classification):", metrics.accuracy_score(y_test, svm_y_pred))
    svm_cmatrix = confusion_matrix(y_test, svm_y_pred, normalize='true', labels=[-1, 1])
    svm_cmatrix = np.array(svm_cmatrix)
    print("Confusion matrices for Binary SVM: ")
    print(pd.DataFrame(svm_cmatrix,
                       index=['O_Player_Won', 'X_Player_Won'],
                       columns=['Predicted_O_Player_Won', 'Predicted_X_Player_Won', ]))

## Multilayer Perceptron
def MLP_smodel():
    MLP_model = MLPClassifier(hidden_layer_sizes = (40, 10, 5),
                              activation = 'relu',
                              solver='adam',
                              random_state = 1)
    MLP_model.fit(X_train, np.ravel(y_train))
    MLP_y_pred = MLP_model.predict(X_test)
    print("MLP Accuracy (Binary Classification):", metrics.accuracy_score(y_test, MLP_y_pred))
    MLP_cmatrix = confusion_matrix(y_test, MLP_y_pred, normalize='true', labels=[-1, 1])
    print("Confusion matrices for Binary MLP: ")
    print(pd.DataFrame(MLP_cmatrix,
                       index=['O_Player_Won', 'X_Player_Won'],
                       columns=['Predicted_O_Player_Won', 'Predicted_X_Player_Won', ]))

## K-Nearest Neighbors
def KNN_smodel():
    ## For k : loop from 1 to 10
    my_KNN_y = {}
    accuracy_list = []

    for k in range(1, 11):
        knn_model = KNeighborsClassifier(n_neighbors = k)
        knn_model.fit(X_train, np.ravel(y_train))
        KNN_y_pred = knn_model.predict(X_test)
        my_KNN_y[k] = KNN_y_pred
        accuracy_list.append(metrics.accuracy_score(y_test, KNN_y_pred))

    print("KNN (k=1) Accuracy (Binary Classification):", metrics.accuracy_score(y_test, my_KNN_y[1]))
    KNN_cmatrix = confusion_matrix(y_test, my_KNN_y[1], normalize='true', labels=[-1, 1])
    print("Confusion matrices for Binary KNN: ")
    print(pd.DataFrame(KNN_cmatrix,
                       index=['O_Player_Won', 'X_Player_Won'],
                       columns=['Predicted_O_Player_Won', 'Predicted_X_Player_Won', ]))

    plt.plot(range(1, 11, 1),
             accuracy_list,
             color='mediumblue',
             linestyle='dashed',
             markerfacecolor='darkblue',
             marker='o',
             markersize=5)
    plt.title("Accuracy Rate for KNN with different k values for Binary Classification")
    plt.yticks(np.arange(0.5, 1.045, 0.05))
    plt.xticks(np.arange(1, 10.5, 1))
    plt.xlabel('k Values')
    plt.ylabel('Accuracy')
    plt.show()

## Train and Evaluate the Classifiers
i = 1
for train_index, test_index in kf10.split(X_final):
    print("This is the", i, "th fold")
    X_train, X_test, y_train, y_test = X_final[train_index], X_final[test_index], Y_final[train_index], Y_final[test_index]
    SVM_smodel()
    MLP_smodel()
    KNN_smodel()
    i = i + 1


""" =================  Multi-class Classification Task =================== """
## Support Vector Machines
def SVM_mmodel():
    svm_model = svm.SVC(kernel = 'rbf', C = 1, decision_function_shape = 'ovo')
    svm_model.fit(X_train, np.ravel(y_train))
    svm_y_pred = svm_model.predict(X_test)
    print("SVM Accuracy (Multi-class):", metrics.accuracy_score(y_test, svm_y_pred))
    svm_cmatrix = confusion_matrix(y_test, svm_y_pred, normalize='true')
    svm_cmatrix = pd.DataFrame(svm_cmatrix,
                               index=['Upper_Left', 'Upper_Middle', 'Upper_Right',
                                      'Middle_Left', 'Center', 'Middle_Right',
                                      'Bottom_Left', 'Bottom_Middle', 'Bottom_Right'],
                               columns=['PUL', 'PUM', 'PUR',
                                        'PML', 'PCenter', 'PMR',
                                        'PBL', 'PBM', 'PBR'])
    print("Confusion matrices for Multi-class SVM : ")
    print(svm_cmatrix.round(3))



## Multilayer Perceptron
def MLP_mmodel():
    MLP_model = MLPClassifier(hidden_layer_sizes = (60, 45, 30),
                              activation='relu',
                              solver='adam',
                              random_state=1,
                              max_iter=500)
    MLP_model.fit(X_train, np.ravel(y_train))
    MLP_y_pred = MLP_model.predict(X_test)
    print("MLP Accuracy (Multi-class):", metrics.accuracy_score(y_test, MLP_y_pred))
    MLP_cmatrix = confusion_matrix(y_test, MLP_y_pred, normalize='true')
    MLP_cmatrix = pd.DataFrame(MLP_cmatrix,
                               index=['Upper_Left', 'Upper_Middle', 'Upper_Right',
                                      'Middle_Left', 'Center', 'Middle_Right',
                                      'Bottom_Left', 'Bottom_Middle', 'Bottom_Right'],
                               columns=['PUL', 'PUM', 'PUR',
                                        'PML', 'PCenter', 'PMR',
                                        'PBL', 'PBM', 'PBR'])
    print("Confusion matrices for Multi-class MLP: ")
    print(MLP_cmatrix.round(3))
    # pickle.dump(MLP_mmodel, open('Trained_MLP_mmodel.sav', 'wb'), protocol = 4)


def KNN_mmodel():
    ## For k : loop from 1 to 20
    my_KNN_y = {}
    accuracy_list = []
    for k in range(1, 20, 2):
        knn_model = KNeighborsClassifier(n_neighbors = k)
        knn_model.fit(X_train, np.ravel(y_train))
        KNN_y_pred = knn_model.predict(X_test)
        my_KNN_y[k] = KNN_y_pred
        accuracy_list.append(metrics.accuracy_score(y_test, KNN_y_pred))

    print("KNN (k=1) Accuracy (Multi-class):", metrics.accuracy_score(y_test, my_KNN_y[1]))
    KNN_cmatrix = confusion_matrix(y_test, my_KNN_y[1], normalize='true')
    KNN_cmatrix = pd.DataFrame(KNN_cmatrix,
                               index=['Upper_Left', 'Upper_Middle', 'Upper_Right',
                                      'Middle_Left', 'Center', 'Middle_Right',
                                      'Bottom_Left', 'Bottom_Middle', 'Bottom_Right'],
                               columns=['PUL', 'PUM', 'PUR',
                                        'PML', 'PCenter', 'PMR',
                                        'PBL', 'PBM', 'PBR'])

    print("Confusion matrices for Multi-class KNN : ")
    print(KNN_cmatrix.round(3))

    plt.plot(range(1, 20, 2),
             accuracy_list,
             color='mediumblue',
             linestyle='dashed',
             markerfacecolor='darkblue',
             marker='o',
             markersize=5)
    plt.title("Accuracy Rate for KNN with different k values for Multi-class Classification")
    plt.yticks(np.arange(0.5, 1.045, 0.05))
    plt.xticks(np.arange(1, 20.5, 2))
    plt.xlabel('k Values')
    plt.ylabel('Accuracy')
    plt.show()

## Train and Evaluate the Classifiers
i = 1
for train_index, test_index in kf10.split(X_single):
    print("This is the", i, "th fold")
    X_train, X_test, y_train, y_test = X_single[train_index], X_single[test_index], Y_single[train_index], Y_single[test_index]
    SVM_mmodel()
    MLP_mmodel()
    KNN_mmodel()
    i = i + 1

""" =====================  Multi-label Regressors ======================== """
## Regression
def LR_mulmodel():
    LR_model = LinearRegression()
    LR_model.fit(X_train, y_train)
    LR_y_pred = LR_model.predict(X_test)
    SQ = (LR_y_pred == LR_y_pred.max(axis=1)[:, None]).astype(int)
    print("Multi-label LR Accuracy:", metrics.accuracy_score(y_test, SQ))

## KNN
def KNN_mulmodel():
    knn_model = KNeighborsClassifier(n_neighbors = 1)
    knn_model.fit(X_train, y_train)
    KNN_y_pred = knn_model.predict(X_test)
    print("Multi-label KNN (k = 1) Accuracy:", metrics.accuracy_score(y_test, KNN_y_pred))

## MLP
def MLP_mulmodel ():
    MLP_model = MLPClassifier(hidden_layer_sizes = (300, 100, 50),
                              activation='relu',
                              solver='adam',
                              random_state=1,
                              max_iter=500)
    MLP_model.fit(X_train, y_train)
    MLP_y_pred = MLP_model.predict(X_test)
    print("Multi-label MLP Accuracy:", metrics.accuracy_score(y_test, MLP_y_pred))

## Train and Evaluate the Regressors
## index
i = 1
for train_index, test_index in kf10.split(X_multi):
    print("This is the", i, "th fold")
    X_train, X_test, y_train, y_test = X_multi[train_index], X_multi[test_index], Y_multi[train_index], Y_multi[test_index]
    KNN_mulmodel()
    LR_mulmodel()
    MLP_mulmodel()
    i = i + 1