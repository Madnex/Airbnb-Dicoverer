# Airbnb Discoverer

Discover data from Airbnb. Visually. Dynamically. Simple.

# To-Do
* Per Host Filter/Analysis for map (filter by host) and plots (number of listings by host, prices by host)
* Neighborhoods names when onclick
* Map show available dates for listing when selected
* External data sources (supermarkets etc.)
* Random plots

# Project Structure
## Algorithms

The project is structured into the following files:

* **ui.R**: User interface logic
* **server.R**: Server logic (calculations)
* **global.R**: Globally available variables
* **preprocessing.R**: Used for manuell preprocessing of calendar data, only needed if new data is imported

## Data

All data is contained in the Data folder. It contains three subfolders:

* **Calendar**: Reservations for one year per listing for the given city
* **Listings**: The listings data for one city, e.g. price, host, location, etc.
* **Neighbourhoods**: Neighbourhoods data as geoJSON files. Boundaries of all neighbourhoods in the city

The Calendar folder contains a subfolder **raw**. Here are the raw calendar data sets (unpacked). As it takes a while to process them, each of them has to be preprocessed in order to avoid long waiting times. This can be done within the **preprocessing.R** file with the method *preprocess_calendar*.

If you want to add another city you can simply download the files: **calendar.csv.gz**, **listings.csv**, **neighbourhoods.geojson** for a city from the source below and rename them to the cityname. Then you copy them to the appropriate folders and run the preprocessing. The last step is to add the city's name to the *supportedCities* list in **global.R**.

# App

## Data
This app allows you to interactively discover data from Airbnb. The available data is from the year 2019/2020. The data source is: http://insideairbnb.com/get-the-data.html

It can be easily extended to more cites. The only limitation is your RAM. The only version of this app (https://madnex.shinyapps.io/Airbnb/) is limited to 1GB RAM. This is why some big cities would by themselves demand most of  the RAM here and only some "minor" cities are shown. 

## Structure
### Data Page
Here you can find descriptive statistics visually prepared for your eyes.

### Explore Page
On this page you can explore the data visually on a map and filter it by some extend.