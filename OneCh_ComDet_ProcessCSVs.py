#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Purpose: C
"""


# USER INPUTS ####################

# Provide file path to analysed data:
path = r'/Volumes/RSaleeb_2TB/2023-09-26_EV-Pulldown_BuckLab/OneCh/Analysis/'


# MAIN CODE ######################

# Import required libraries
import csv
import pandas as pd
import os


# Initialise empty dataframes to contain compiled data
dataSummary = pd.DataFrame()
descriptorAnalysis = pd.DataFrame()

# Iterate over folders and files
for folder in os.listdir(path):

    if not folder == '.DS_Store':
        for file in os.listdir(path + folder):

            # Identify data associated with a single FOV
            if file.endswith('ComDet-Results.csv') and not file.startswith('._'):
                print(folder + file)

                # Initialise CSV readers to read the CSV files
                with open(path + folder + '/' + file) as f:
                    freader = csv.reader(f)


                    # Check the number of rows in each CSV
                    f_row_count = sum(1 for row in freader)
                    
                    # Reset the CSV readers to read the first row after the column headers
                    f.seek(0)
                    next(freader)

                    # Skip the FOV if the CSV row count does not equal 2 in each case (indicates erroneous data)
                    if (f_row_count == 2):
                        for row in freader:
                            
                            # Check if the FOV produced no detections (5 column data) or at least one detection (7 column data)
                            if len(row) == 4:
                                appendRow = pd.DataFrame(row).transpose()
                                appendRow.columns=['Channel', 'Slice', 'Frame', 'Detections']

                                
                                # Add and populate file/folder name columns
                                appendRow.insert(0, 'File', [file])
                                appendRow.insert(0, 'Folder', [folder])

                                
                                # Add the row on to the bottom of the summary data table
                                dataSummary = pd.concat((dataSummary, appendRow), axis = 0)
                           

                            else:
                                print("ERROR - Incorrect table size, data excluded.")
                                

                    # Import all descriptor data for the current FOV into a dataframe, use existing column names
                    try:
                        col_names = pd.read_csv(path + folder + '/' + file[0 : file.index("ComDet-Results.csv")] + "descriptors.csv", nrows=0).columns.tolist()
                        events = pd.read_table(path + folder + '/' + file[0 : file.index("ComDet-Results.csv")] + "descriptors.csv", sep=",", header=None, skiprows=[0])
                        events.columns = col_names

                        
                        # Insert columns with relevant file/folder names
                        events.insert(0, 'File', [file] * events.shape[0])
                        events.insert(0, 'Folder', [folder] * events.shape[0])
                        
                        # Append new rows to the descriptor dataframe
                        descriptorAnalysis = pd.concat((descriptorAnalysis, events), axis=0) 
                    except:
                        print("No detections to report from file")


# Rename column headers in data summary
dataSummary.columns=['Folder', 'File', 'Channel', 'Slice', 'Frame', 'Detections']

# Convert datatype of numberic columns to float
dataSummary[['Detections']].apply(pd.to_numeric, errors='coerce')


# Save dataframes as CSVs
dataSummary.to_csv(path + 'All_Data.csv', index=False)
descriptorAnalysis.to_csv(path + 'furtherdescriptors.csv', index=False)