import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load the data (assuming you've exported the views to CSV files)
price_trends = pd.read_csv('vw_PriceTrends.csv')
property_chars = pd.read_csv('vw_PropertyCharacteristics.csv')
location_analysis = pd.read_csv('vw_LocationAnalysis.csv')
age_value = pd.read_csv('vw_AgeValueRelation.csv')
vacant_sales = pd.read_csv('vw_VacantPropertySales.csv')
price_comparison = pd.read_csv('vw_PropertyPriceComparison.csv')

# 1. Price Trends Analysis
price_trends['Date'] = pd.to_datetime(price_trends[['SaleYear', 'SaleMonth']].assign(day=1))

plt.figure(figsize=(12, 6))
plt.plot(price_trends['Date'], price_trends['AvgSalePrice'])
plt.title('Average Sale Price Over Time')
plt.xlabel('Date')
plt.ylabel('Average Sale Price')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# 2. Property Characteristics Analysis
plt.figure(figsize=(12, 6))
sns.barplot(x='LandUse', y='AvgSalePrice', data=property_chars)
plt.title('Average Sale Price by Land Use')
plt.xlabel('Land Use')
plt.ylabel('Average Sale Price')
plt.xticks(rotation=90)
plt.tight_layout()
plt.show()

# 3. Location Analysis
top_10_cities = location_analysis.nlargest(10, 'AvgSalePrice')

plt.figure(figsize=(12, 6))
sns.barplot(x='PropertySplitCity', y='AvgSalePrice', data=top_10_cities)
plt.title('Top 10 Cities by Average Sale Price')
plt.xlabel('City')
plt.ylabel('Average Sale Price')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# 4. Age-Value Relation Analysis
plt.figure(figsize=(12, 6))
sns.scatterplot(x='OldestProperty', y='AvgSalePrice', size='PropertyCount', data=age_value)
plt.title('Average Sale Price vs. Property Age')
plt.xlabel('Oldest Property in Group')
plt.ylabel('Average Sale Price')
plt.tight_layout()
plt.show()

# 5. Vacant Property Sales Analysis
plt.figure(figsize=(8, 6))
sns.barplot(x='SoldAsVacant', y='AvgSalePrice', data=vacant_sales)
plt.title('Average Sale Price: Vacant vs. Non-Vacant Properties')
plt.xlabel('Sold As Vacant')
plt.ylabel('Average Sale Price')
plt.tight_layout()
plt.show()

# 6. Property Price Comparison
land_use_avg = price_comparison.groupby('LandUse')['SalePrice'].mean().sort_values(ascending=False)
top_5_land_use = land_use_avg.head()

plt.figure(figsize=(12, 6))
sns.boxplot(x='LandUse', y='SalePrice', data=price_comparison[price_comparison['LandUse'].isin(top_5_land_use.index)])
plt.title('Sale Price Distribution for Top 5 Land Use Categories')
plt.xlabel('Land Use')
plt.ylabel('Sale Price')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# Correlation heatmap
numeric_columns = price_comparison.select_dtypes(include=[np.number]).columns
correlation_matrix = price_comparison[numeric_columns].corr()

plt.figure(figsize=(12, 10))
sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', linewidths=0.5)
plt.title('Correlation Heatmap of Numeric Variables')
plt.tight_layout()
plt.show()