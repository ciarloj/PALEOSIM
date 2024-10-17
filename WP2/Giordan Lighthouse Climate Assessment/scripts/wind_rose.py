"""
Script tha generates monthly and seasonal windrose plots
from Giordan data based on daily means from 1997 to 2022.

Author: Ryan Vella
Last modified: 20.04.2024
"""
#%%

# Loading libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from windrose import WindroseAxes
from matplotlib.patches import Patch
import matplotlib.cm as cm
from matplotlib.projections import register_projection

#%% ANNUAL MEAN -----------------------------------------------------------------------------------------------


# Load the CSV data into a DataFrame
csv_file = "/Users/ryanvella/Documents/20_projects/climate_assessment/data/Giordan_data_hr.csv"
df = pd.read_csv(csv_file)

# Replace '#N/A' with NaN
df.replace('#N/A', np.nan, inplace=True)

# Convert the 'Date' column to datetime with format "DD/MM/YYYY"
df['Date'] = pd.to_datetime(df['Date'], format='%d/%m/%Y')

# Convert wind direction and wind speed columns to numeric
df['WD [o]'] = pd.to_numeric(df['WD [o]'], errors='coerce')
df['WS [m/s]'] = pd.to_numeric(df['WS [m/s]'], errors='coerce')

# Drop rows with NaN values
df.dropna(subset=['WD [o]', 'WS [m/s]'], inplace=True)

# Plot wind rose

fig, ax = plt.subplots(figsize=(8, 8), subplot_kw=dict(projection="windrose"))

bins = [0, 5, 10, 15, 20]
colors = ['#ffffcc', '#a1dab4', '#41b6c4', '#2c7fb8', '#253494']

ax.bar(df['WD [o]'], df['WS [m/s]'], normed=True, opening=0.8, edgecolor='white', bins=bins, colors=colors)

# Set y-axis limits and ticks
ax.set_ylim(0, 20)
ax.set_yticks(np.arange(0, 21, 5))
ax.set_yticklabels(['{:g}%'.format(x) for x in ax.get_yticks()])

# Define wind speed categories and labels
wind_speed_categories = [0, 5, 10, 15, 20, np.inf]
legend_labels = ['0-5', '5-10', '10-15', '15-20', '>20']

# Create legend elements with black border
legend_elements = [
    Patch(facecolor=colors[i], edgecolor='black', label=legend_labels[i]) 
    for i in range(len(legend_labels))
]

fig.legend(handles=legend_elements, title="Wind Speed (m s$^{-1}$)", loc='upper center', bbox_to_anchor=(0.51, 0.32), ncol=1, fancybox=True, facecolor='white', framealpha=1.0)

plt.title('Annual mean (1997-2022)')
plt.savefig('/Users/ryanvella/Documents/20_projects/climate_assessment/plots/wind_rose_annual_mean.pdf', dpi=300)

plt.show()



#%% SEASONAL PLOTS -----------------------------------------------------------------------------------------------




# Register WindroseAxes as a projection in matplotlib
register_projection(WindroseAxes)

# Load the CSV data into a DataFrame
csv_file = "/Users/ryanvella/Documents/20_projects/climate_assessment/data/Giordan_data_hr.csv"
df = pd.read_csv(csv_file)

# Replace '#N/A' with NaN
df.replace('#N/A', np.nan, inplace=True)

# Convert the 'Date' column to datetime with format "DD/MM/YYYY"
df['Date'] = pd.to_datetime(df['Date'], format='%d/%m/%Y')

# Convert wind direction and wind speed columns to numeric
df['WD [o]'] = pd.to_numeric(df['WD [o]'], errors='coerce')
df['WS [m/s]'] = pd.to_numeric(df['WS [m/s]'], errors='coerce')

# Drop rows with NaN values
df.dropna(subset=['WD [o]', 'WS [m/s]'], inplace=True)

# Define seasons based on months
seasons = {
    'MAM': [3, 4, 5],    # March, April, May
    'JJA': [6, 7, 8],    # June, July, August
    'SON': [9, 10, 11],  # September, October, November
    'DJF': [12, 1, 2]    # December, January, February
}


# Create a figure and subplots for each season
fig, axes = plt.subplots(2, 2, figsize=(12, 10), subplot_kw=dict(projection="windrose"))


bins = [0, 5, 10, 15, 20]
colors = ['#ffffcc', '#a1dab4', '#41b6c4', '#2c7fb8', '#253494']
legend_labels = ['0-5 m/s', '5-10 m/s', '10-15 m/s', '15-20 m/s']

# Plot wind rose for each season
for season, ax in zip(seasons.keys(), axes.flatten()):
    season_months = seasons[season]
    season_df = df[df['Date'].dt.month.isin(season_months)]

    bar = ax.bar(season_df['WD [o]'], season_df['WS [m/s]'], normed=True, opening=0.8, edgecolor='white', bins=bins, colors=colors)
    ax.set_yticklabels(['{:g}%'.format(x*5) for x in range(5)])  # Adjusting y-axis labels to range from 0 to 20%
    ax.set_title(f'{season}')

    # Set y-axis limits and ticks
    ax.set_ylim(0, 20)
    ax.set_yticks(np.arange(0, 21, 5))
    ax.set_yticklabels(['{:g}%'.format(x) for x in ax.get_yticks()])


# Define wind speed categories and labels
wind_speed_categories = [0, 5, 10, 15, 20, np.inf]
legend_labels = ['0-5', '5-10', '10-15', '15-20', '>20']

# Create legend elements with black border
legend_elements = [
    Patch(facecolor=colors[i], edgecolor='black', label=legend_labels[i]) 
    for i in range(len(legend_labels))
]

# Create legend
fig.legend(handles=legend_elements, title="Wind Speed (m s$^{-1}$)", loc='upper center', bbox_to_anchor=(0.5, 0.5), ncol=1, fancybox=True)

fig.suptitle("Seasonal mean (1997-2022)", fontsize=16)

plt.tight_layout()
plt.savefig('/Users/ryanvella/Documents/20_projects/climate_assessment/plots/wind_rose_seasonal_mean.pdf', dpi=300)
plt.show()
















