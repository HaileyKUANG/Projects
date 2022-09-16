# -*- coding: utf-8 -*-

"""
File:   My_Function.py
Author: Hailey 
Date: Sept.16, 2022
Desc: Define the needed functions
"""

## ================================================ ## 
import math
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import kurtosis, skew




## ================================================ ## 
## Function 1: Descriptive Statistics 
## descriptive information (numerical)
def num_descriptive(data, var_list):
    
    '''
    This is a function to return the table of descriptive statistics for numerical variables/features
    Based on numpy
    '''

    
    var_des_list = []
    for nvar in var_list:
        nvar_des = {"Variable": nvar,
                    "Median": np.median(data[nvar]),
                    "Mean": np.average(data[nvar]),
                    "Standard Deviation": np.std(data[nvar]),
                    "Minimum": np.amin(data[nvar]),
                    "Maximum": np.amax(data[nvar]),
                    "Range": np.amax(data[nvar]) - np.amin(data[nvar]), 
                    "Kurtosis": kurtosis(data[nvar]),
                    "Skewness": skew(data[nvar])
                   }
        var_des_list.append(nvar_des)
    return var_des_list





## ================================================ ## 
## Function 2: Distribution Plot Loop over a list of Variables
## distribution plots with kdeplot for numerical variables
## final version
## Note: `displot` is a figure-level function and does not accept the ax= paramter
def num_dist(data, var_list):
    
    '''
    This is a function to return the histogram of numerical variables/features
    Based on matplotlib.pyplot and seaborn
    '''

    ## create a figure and a set of subplots
    nc_init = 2
    nr_init = math.ceil(len(var_list)/nc_init)
    
    if nr_init == 1:
        fig, ax = plt.subplots(nrows = nr_init, ncols = nc_init, figsize = (8, 6))
        fig.tight_layout(pad = 6)
    elif nr_init > 1:
        fig, ax = plt.subplots(nrows = nr_init, ncols = nc_init, figsize = (nr_init*3, nc_init*9))
        fig.tight_layout(pad = 6)

    nr_plot = 0 ## set the location(row) of the subplots
    for i in range(len(var_list)):
        nc_plot = i - (2*nr_plot) ## set the location(colunm) of the subplots
        
        ## if there are less than two subplots
        if nr_init == 1:
            sns.kdeplot(data = data, x = var_list[i], ax = ax[nc_plot])  
            ax[nc_plot].set_xlabel(var_list[i], fontsize = 12)
            ax[nc_plot].set_ylabel('Density', fontsize = 12)
        
        ## if there more less than two subplots   
        elif nr_init > 1:
            sns.kdeplot(data = data, x = var_list[i], ax = ax[nr_plot, nc_plot])  
            ax[nr_plot, nc_plot].set_xlabel(var_list[i], fontsize = 12)
            ax[nr_plot, nc_plot].set_ylabel('Density', fontsize = 12)
    
            ## update the location(row)
            if i%2 == 1 and nc_plot != 0:
                nr_plot += 1
            else : 
                continue

    plt.suptitle('Numerical Data Distribution - Distribution Plot', fontsize = 16)







## ================================================ ## 
## Function 3: Boxplot Loop over a list of Variables
## boxplot numerical variables
## final version
def num_boxplot(data, var_list):
    
    '''
    This is a function to return the boxplot of numerical variables/features
    Based on matplotlib.pyplot and seaborn
    '''
    
    ## create a figure and a set of subplots
    nc_init = 2
#     nr_init = int(len(var_list)/nc_init)
    nr_init = math.ceil(len(var_list)/nc_init) 
    
    if nr_init == 1:
        fig, ax = plt.subplots(nrows = nr_init, ncols = nc_init, figsize = (8, 6))
        fig.tight_layout(pad = 6)
    elif nr_init > 1:
        fig, ax = plt.subplots(nrows = nr_init, ncols = nc_init, figsize = (nr_init*3, nc_init*9))
        fig.tight_layout(pad = 6)

    nr_plot = 0 ## set the location(row) of the subplots
    for i in range(len(var_list)):
        nc_plot = i - (2*nr_plot) ## set the location(colunm) of the subplots
        
        ## if there are less than two subplots
        if nr_init == 1:
            sns.boxplot(data = data, y = var_list[i], ax = ax[nc_plot])  
            ax[nc_plot].set_xlabel(var_list[i], fontsize = 12)
            ax[nc_plot].set_ylabel('Values', fontsize = 12)
        
        ## if there more less than two subplots   
        elif nr_init > 1:
            sns.boxplot(data = data, y = var_list[i], ax = ax[nr_plot, nc_plot])  
            ax[nr_plot, nc_plot].set_xlabel(var_list[i], fontsize = 12)
            ax[nr_plot, nc_plot].set_ylabel('Values', fontsize = 12)
    
            ## update the location(row)
            if i%2 == 1 and nc_plot != 0:
                nr_plot += 1
            else : 
                continue

    plt.suptitle('Numerical Data Distribution - Boxplot', fontsize = 16)





## ================================================ ## 
## Function 4: Histogram Loop over a list of Variables
## histplot numerical variables
## final version
def num_hist(data, var_list):
    
    '''
    This is a function to return the histogram of numerical variables/features
    Based on matplotlib.pyplot and seaborn
    '''
    
    ## create a figure and a set of subplots
    nc_init = 2
    nr_init = math.ceil(len(var_list)/nc_init)
    
    if nr_init == 1:
        fig, ax = plt.subplots(nrows = nr_init, ncols = nc_init, figsize = (8, 6))
        fig.tight_layout(pad = 6)
    elif nr_init > 1:
        fig, ax = plt.subplots(nrows = nr_init, ncols = nc_init, figsize = (nr_init*3, nc_init*9))
        fig.tight_layout(pad = 6)

    nr_plot = 0 ## set the location(row) of the subplots
    for i in range(len(var_list)):
        nc_plot = i - (2*nr_plot) ## set the location(colunm) of the subplots
        
        ## if there are less than two subplots
        if nr_init == 1:
            sns.histplot(data = data, x = var_list[i], ax = ax[nc_plot])  
            ax[nc_plot].set_xlabel(var_list[i], fontsize = 12)
            ax[nc_plot].set_ylabel('Density', fontsize = 12)
        
        ## if there more less than two subplots   
        elif nr_init > 1:
            sns.histplot(data = data, x = var_list[i], ax = ax[nr_plot, nc_plot])  
            ax[nr_plot, nc_plot].set_xlabel(var_list[i], fontsize = 12)
            ax[nr_plot, nc_plot].set_ylabel('Density', fontsize = 12)
    
    
            ## update the location(row)
            if i%2 == 1 and nc_plot != 0:
                nr_plot += 1
            else : 
                continue

    plt.suptitle('Numerical Data Distribution - Histograms', fontsize = 16)






## ================================================ ## 
## Function 5: Frequency Statistics
def cate_frequency(data, var):
    
    '''
    This is a function to return the table of descriptive statistics for categorical variables/features
    Used for categorical variables with less than 30 categories
    Based on numpy
    '''
    
    unique, counts = np.unique(data[var], return_counts = True)
    percentages = counts * 100 / len(data[var])
    frequencies = np.asarray((unique, counts, percentages), dtype = object).T
    frequencies = pd.DataFrame(data = frequencies, columns = ["Category", "Count", "Percentage"])
    frequencies = frequencies.sort_values(by = 'Count', ascending = False, na_position = 'first')
    frequencies_table = frequencies.style.set_caption(var).set_table_styles([{
        'selector': 'caption',
        'props': [("text-align", "center"),
                  ('color', 'black'),
                  ('font-size', '16px'),
                  ('font-style','italic'),
                  ('font-weight', 'bold')]}])
    display(frequencies_table)






## ================================================ ## 
## Function 6: Convert k/m/b to Number
## size ---> numerical values
## with identify col_names as a parameter
def transform_kmb(row, var):
    form = row[var][0][-1]
    if form == 'k':
        return float(row[var][0][:-1])*1000
    elif form == 'M':
        return float(row[var][0][:-1])*1000000
    elif form == "B":
        return float(row[var][0][:-1])*1000000000
    else:
        return float(row[var][0])







## ================================================ ## 
## Function 7: Remove "+" sign at the end of the String
## remove "+" sign
def transform_install(row, var):
    fnum = row[var][0][:-1]
    form = int(fnum.replace(',',''))
    return form






## ================================================ ## 
## Function 8: Remove "$" sign at the beginning of the String
## remove "$" sign
def transform_p(row, var):
    fnum = row[var][0]
    if fnum == "0":
        fnum = int(fnum)
        return fnum
    else: 
        fnum = fnum[1:]
        fnum = float(fnum)
        return fnum





## ================================================ ## 
## Function 9: Create Binary Price Variables
def transform_bp(row, var):
    
    '''
    transform category 0 = free, 1 = not free
    '''
    
    fnum = row[var][0]
    if fnum == "0":
        fnum = int(fnum)
        return fnum
    else: 
        return 1





## ================================================ ## 
## Function 10: Create Binary Category Variables
def transform_bc(row, var):
    
    '''
    transform category 0 = other, 1 = FAMILY, 2 = GAME,
                       3 = TOOLS, 4 = MEDICAL, 5 = LIFESTYLE, 
                       6 = HEALTH_AND_FITNESS, 7 = FINANCE
    '''
    
    fcat = row[var][0]
    if fcat == "FAMILY":
        return fcat
    elif fcat == "GAME":
        return fcat
    elif fcat == "TOOLS":
        return fcat
    elif fcat == "MEDICAL":
        return fcat
    elif fcat == "LIFESTYLE":
        return fcat
    elif fcat == "HEALTH_AND_FITNESS":
        return fcat
    elif fcat == "FINANCE":
        return fcat
    else: 
        return 'OTHER'






## ================================================ ## 
## Function 11: Create Binary Category Variables
## keep year
def transform_y(row, var):
    fnum = row[var][0][-4:]
    fnum = int(fnum)
    return fnum






## ================================================ ## 
## Function 12: Version as Single Digit
## keep the first number
def transform_ly(row, var):
#     print(row[var])
#     print(row[var][0][0])

#     print(row[var].fillna("0.0.0"))
    row[var] = row[var].fillna("0.0.0")
    latest_ver = row[var][0][0]
    fnum = str(latest_ver)[0]
    fnum = int(fnum)
    return fnum