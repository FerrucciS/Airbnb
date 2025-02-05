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
5. What are the top 10 most common minimum-nights required?
6. What is the average price per bedroom and room type?


## Executive Summary



## Data Source

Data source is obtained from [Melbourne Airbnb | September 2023 Dataset](https://www.kaggle.com/datasets/tauanoliveira/melbourne-airbnb-september-2023-dataset?resource=download). The data has 10708 rows and 75 columns.


## Data Cleaning

We want to clean the data to remove duplicate rows, fix or remove incorrect data, correcting formats, deal with outliers, and generally ensuring data is accurate and complete. 


### 1. Remove Columns

The dataset has 75 columns, of which we only need a subset of these. Create a new dataset - "new_listings" - with the following columns

![Column](Images/Columns.png)


### 2. Remove Duplicate Rows

As the id is unique for each listing, we look for repeated id's to single out duplicate rows and remove them from the new dataset new_listings.


![Duplicates](Images/Duplicates2.png)


We find no duplicates.


### 3. Missing Values

A straight forward querey iforms us of empty, null, or incorrect values - by incorrect here i mean nonsensical inputs e.g. negative pricing. What we find is empty cells in the following columns
1. description - 124 empty
2. neighbourhood - 3010 empty
3. bathrooms_text - 8 empty
4. bedrooms - 2972 empty
5. amenities - 7 empty

The only columns we can look at filling in missing values is for neighbourhood, bathrooms_text, and bedrooms as the name and description column seem to contain information about these.

#### Neighbourhood

A quick inspection of the name column shows that many listings contain the neighbourhood of the listings. The neighbourhoods are specified as "in 'sububrb, Melbourne,...'" and are then ended with "·". With this information we can update our table as follows

![Neighbourhood](Images/Update_neighbourhood.png)


We only want the neighbourhood and not the city and state. Therefore, we need to keep the neighbourhood and discard the rest as now they are of the form "Neighbourhod, City, State" or "Neighbourhod. City. State". This is achieved as follows


![Seperate_city_state](Images/Seperate_city_state.png)

After a quick inspection of the neighbourhood column, we notice two things that need mending and some additional comments.
- A few are left as "suburb/City" or "Suburb/City"
- There are listings of the same neighbourhood such as "St Kilda" and "Saint Kilda".
- To be extra careful we apply the TRIM function to remove any white space before or after the neighbourhood names.
- Don't need to worry about capitalisation as SQL and Tableau where we will analyse the data are not case sensitive.

  The first two issues are mended as follows

  

![Image](Images/stKilda.png)

This concludes the cleaning of the neighbourhood column.


#### Bathrooms_text

Here we have 8 missing values. We first look at the description and name columns as we did earlier to see if these contain information. Running a querey to see if the name or description columns contain the word 'bath' for these empty rows proves ineffective, and demonstrates they do not contain any information about the bathroom.

As There are only 8 of these missing values it is worth visiting the listing_url to set the missing data. 

The following querey explains the findings in the lisitng_url


![Bathrooms](Images/Bathrooms.png)

The listing with Id '38883439' had no information or photos but from the specified 2-bedroom townhouse I guessed 1 bathroom. Furthermore, Id '34046314' was outdated with the url taken down so I removed this row.


#### Bedrooms

There are 2972 empty rows in the bedrooms column. We first begin by checking the name column in each row for the words 'studio', 'bedroom', and 'bedrooms' and fill in the appearing number of bedrooms in the correct column. 

![Bedroomsn](Images/Bedrooms_name.png)

There were 16 rows where the name did not contain information about the bedrooms. Thus, these values for the bedrooms are now Null. When checking these 16 rows, 4 are studios as described in the desciption 


![Bedroomsdesc](Images/Bedrooms_desc.png)


The remaining 12 are filled in by visiting the listing_url. 


![Bedroomsn](Images/Bedrooms_url.png)


When visiting the urls the following listing Id's (22488519, 40377799, 40510306, 46096289) are outdated and are deleted from the dataset.


Lastly, we dont need the word 'bedroom(s)' after the number so we will remove this from each row.

![BedroomsRemove](Images/Remove_bedroom.png)


### 4. Data Type Conversions


We now want to ensure we have correct data types for each column. This is essential when performing analysis of the data. The data types are shown below


![DataTypes](Images/TypeData.png)


We change bedrooms from TEXT to INT and price from TEXT to DOUBLE. Moreover, for the price column we remove the substring '$'.


### 5. Data Quality

We will now look at some of the numerical columns and manually check some of the outliers to see if they represent natural variations or are sources of error.


#### Prices

We will look at price values that lie outside 3 standard deviations. Although, prices usually follow lognormal distributions with long right-tails we can still use the standard deviation as a threshold to check for outliers.

![Pricessted](Images/PricingSTDEV.png)

The result is 252 rows. There are a couple of suspicious listings, specifically 41472650 and 37786374 which are both 1 bedroom apartments in Melbourne. I will leave the two listings above but they raise concern to be flagged. The rest seem fine.


#### Minimum Nights

By following the above method for the required minimum nights stayed, we find 62 rows fall outside 3 standard deviations. There are 14 lisitngs above 365 days; the highest being 1125 days. These are unreasonable and I will put a max cap at 365 days and change these listings. Even 365 days seems unusually high, although this will serve as a cap.


#### Bedrooms

Again following the same method for bedrooms listings, we find the following errors

- Id: 43760603 and 51095353 has 4 bedrooms not 14.
- Id: 21750782 has 3 bedrooms not 11.
- Id: 35821644 has 2 bedrooms not 11.

  These listings are updated to the correct bedrooms.



## Analysis

Here we look at the seven questions stated in the problem statement.

### 1. Who are the top 10 hosts with the highest number of listings?

The data shows that the top 10 hosts with the most listings are led by host 90729398, who has 109 listings (1.02% of the total). The second and third hosts, 279001183 and 1739996, are tied with 63 listings (0.59%). The remaining 7 hosts have fewer than 50 listings making up less than 0.5% of the total listings. The top 10 hosts are displayed in the following graph.


![Top10Hosts](Images/TopHosts.png)



### 2. What are the top 10 neighbourhoods with the most listings?

The data shows the top neighbourhood with the most listings is the suburb of Melbourne with 1763 listings (16.46% of total listings). this is followed by Southbank and St Kilda with 545 (5.09%) and 475 (4.44%) listings respectively. The remaining 7 listings are below 4% of the total listings.


![Top10Suburbs](Images/TopSuburbs.png)



### 3. What is the distribution of listings by the number of bedrooms?

The top bedroom listing frequency is 1 bedroom, making up 51.37% of the total listings. 2 bedrooms comes in second with 29.55%. 3,4,5 and 0 (studios) are each below 10% but above 1%. The frequency of listings with more than 5 bedrooms altogether make up less than 0.7% of the total listings and are outliers in the distribution and represent natural variations.


![Top5Bedrooms](Images/TopBedrooms.png)



### 4. And room type?

The data reveals Entire homes/Apartments make up 75.05% of listings. Private rooms are the second most common with a substantial decrease in listings: 23.38%. Shared rooms and hotel rooms are both less than 1% of listings as seen if the graph.


![Room-Type](Images/Room-Type.png)



### 5. What are the top 10 most common minimum-nights required?


The most common minimum night stay requirement is 2 nights, making a total of 3,531 listings (32.98% of total). Following this is 1 night with 3168 listings (29.56%). The third most common is 3 nights with 1569 (14.65%). The remaining seven are all below 5%. Interestingly, these aren't a linear increase in minimum nights stayed. For example, after the sixth most common - 4 nights - is 14 days (1.65%) which marks a substantial increase in minimum nights requirement. The data shows that at most 6.5% of listings are long-term stays with a minimum night of 14 days or more; In the graph below these make up 3.23%.


![MinNights](Images/MinNights.png)


### 7. What is the average price per bedroom and room type?

The analysis of average and median prices per number of bedrooms reveals an increasing gap between the two as the number of bedrooms rises. This widening gap suggests the presence of high-value outliers, particularly in larger listings, which pull the average price upward while the median remains less affected. Notably, listings with 0 bedrooms (studio apartments) are priced higher than those with 1 bedroom, possibly due to premium locations or luxury studio accommodations and the inclusion of shared accomodation for 1 bedroom listings. Beyond 1 bedroom, prices steadily rise with increasing bedroom count but eventually plateau around 5 bedrooms, indicating a potential diminishing returns in pricing for larger listings.


![AVGPrice](Images/AVGPrice.png)



## Caveats and
