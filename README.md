# Analysing Melbourne's Airbnb Market


## Introduction

Airbnb is a global online marketplace that connects travelers with hosts offering short-term rentals, ranging from private rooms to entire homes. Founded in 2008, the platform has revolutionized the hospitality industry by providing flexible accommodation options in cities and remote locations worldwide. 

Airbnb offers a wide variety of listings tailored to consumers' needs, including options based on location, dates, price, property type, and more. With millions of listings, Airbnb's data offers valuable insights into pricing trends, guest preferences, and market dynamics.

Melbourne, known for its vibrant culture, diverse neighborhoods, and strong tourism industry, is a city where Airbnb thrives. With major events, world-class dining, and a high demand for short-term accommodation, the platform plays a significant role in the city’s hospitality landscape. Visitors often choose Airbnb over traditional hotels for its variety of options, from budget-friendly apartments to luxury homes.



## Problem Statement

In this analysis, we will look at Airbnb data to uncover key characteristics of Melbourne’s short-term rental market. By examining factors such as pricing, availability, location trends, and property types, we aim to gain insights into how Airbnb operates within the city and what influences its market dynamics.

With the problem statement established, we can break it down into smaller objectives by answering the following questions:
1. Who are the top 10 hosts with the highest number of listings?
2. What are the top 10 neighbourhoods with the most listings?
3. What is the distribution of listings by the number of bedrooms?
4. And room type?
5. Which room types have the best reviews?
6. What are the most common minimum-nights required?
7. What is the average price per bedroom and room type?


## Executive Summary



## Data Source

Data source is obtained from [Melbourne Airbnb | September 2023 Dataset](https://www.kaggle.com/datasets/tauanoliveira/melbourne-airbnb-september-2023-dataset?resource=download). The data has 10708 rows and 75 columns.


## Data Cleaning

We want to clean the data to remove duplicate rows, fix or remove incorrect data, correcting formats, deal with outliers, and generally ensuring data is accurate and complete. 


### 1. Remove Columns

The dataset has 75 columns, of which we only need a subset of these. Create a new dataset with the following columns

![Column](Images/Columns.png)


### 2. Remove Duplicate Rows

As the id is unique for each listing, we look for repeated id's to single out duplicate rows and remove them from the new dataset new_listings.


![Duplicates](Images/Duplicate.png)

