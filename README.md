# **Business Software and Services Reviews Data Analysis**

This project demonstrates how to use AWS S3, Snowflake, and Tableau to analyze software and services reviews data from G2.

The data used in this project is uploaded to S3, from where it is imported into Snowflake. In Snowflake, the data is processed and several tables are created. Finally, the processed data is visualized using Tableau.

Here's a **[link](https://public.tableau.com/app/profile/rickyltwong/viz/BusinessSoftwareandServicesReviewsDatafromG2/VendorDashboard)** to the final dashboard.

## **Project Structure**

1. **Data**: The raw JSON data (**`g2.json`**) is stored in an AWS S3 bucket.
2. **Snowflake Queries**: Snowflake is used to import the data from S3 and process it.
3. **Tableau Visualization**: Tableau is used to visualize the processed data.

## **Setup and Configuration**

### **AWS S3**

The JSON data (**`g2.json`**) is uploaded to an S3 bucket using the **`upload_to_s3.py`** script. To use the script, AWS CLI needs to be configured. Here is an example of how to configure it:

```
$ aws configure
AWS Access Key ID [None]: YOUR_ACCESS_KEY
AWS Secret Access Key [None]: YOUR_SECRET_KEY
Default region name [None]: YOUR_REGION
Default output format [None]: json
```

Please replace **`YOUR_ACCESS_KEY`**, **`YOUR_SECRET_KEY`**, and **`YOUR_REGION`** with your actual AWS Access Key ID, AWS Secret Access Key, and default region respectively.

**Important Note**: Never share your AWS Access Key ID or AWS Secret Access Key in a public forum like GitHub. They should be kept confidential to protect your AWS account.

### **Snowflake**

The Snowflake scripts in the **`snowflake_queries.sql`** file perform the following steps:

1. Create a temporary stage in Snowflake and pull data from S3.
2. Parse and flatten the JSON data.
3. Create a table (**`vendor_rating`**) to hold vendors and their ratings.
4. Create another table (**`vendor_competitor_rating`**) to hold companies and their competitors' ratings.
5. Create a table (**`vendor_category`**) to hold the categories that vendors belong to.
6. Create a table (**`vendor_category_rating`**) to hold the average rating by company category.
7. Create a table (**`vendor_category_comparison`**) to compare the rating of a company with the average rating of its category.

**Note**: The scripts require AWS key ID and secret key for access to the S3 bucket. Please replace them with your own keys in the script.

### **Tableau**

The final step in the pipeline is to visualize the processed data in Tableau. The Tableau workbook connects directly to the Snowflake database to fetch the processed data, and several visualizations are created.

The final dashboard shows the reviews data from G2, including average stars, total reviews, category comparison, and product comparison for each company.
