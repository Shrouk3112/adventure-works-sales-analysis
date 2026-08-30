import pandas as pd

# Load the sales data
sales_2020 = pd.read_csv("Raw_Data/Sales Data 2020.csv")
sales_2021 = pd.read_csv("Raw_Data/Sales Data 2021.csv")
sales_2022 = pd.read_csv("Raw_Data/Sales Data 2022.csv")

# Combine all years
sales = pd.concat([sales_2020, sales_2021, sales_2022])

# Show basic info
print("Total rows:", len(sales))
print("Columns:", sales.columns.tolist())
print(sales.head())

# ==============================
# Basic Analysis
# ==============================

# Total Quantity Sold
total_quantity = sales['OrderQuantity'].sum()
print("\nTotal Quantity Sold:", total_quantity)

# Top 10 Products by Quantity
top_products = sales.groupby('ProductKey')['OrderQuantity'].sum().sort_values(ascending=False).head(10)
print("\nTop 10 Products by Quantity:")
print(top_products)

# Sales by Year
sales['OrderDate'] = pd.to_datetime(sales['OrderDate'])
sales['Year'] = sales['OrderDate'].dt.year

sales_by_year = sales.groupby('Year')['OrderQuantity'].sum()
print("\nSales Quantity by Year:")
print(sales_by_year)

# ==============================
# Simple Visualization
# ==============================
import matplotlib.pyplot as plt

sales_by_year.plot(kind='bar', color='steelblue')
plt.title('Sales Quantity by Year')
plt.xlabel('Year')
plt.ylabel('Quantity Sold')
plt.xticks(rotation=0)
plt.tight_layout()
plt.savefig('sales_by_year.png', dpi=150, bbox_inches='tight')
plt.show()
