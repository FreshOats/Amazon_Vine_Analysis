# Amazon Vine Analysis - Pet Products
***Utilizing Spark, AWS, PostgreSQL, and Python to analyze the Amazon Vine program by evaluating Pet Product Reviews***
#### by Justin R. Papreck
---

## Overview

Amazon Web Services is capable of hosting datasets that exceed the drive space on typical personal computers, allowing for the fast analysis of big data. The Amazon Vine program was a paid user program that promoted Vine users to write good and meaningful reviews. The company, and stakeholder, SellBy is providing such products for review to Amazon Vine users, however it is critical to know whether these reviews will be biased compared to unpaid users. By accessing Amazon's review information collected on a certain category of products, we can ascertain whether there is such a bias. The assumption is that there will be a higher percentage of 5-star ratings by the paid Vine users than of the unpaid users. The findings of this study do not support that assumption, though it is to be noted that this study only represents the data regarding Amazon's Pet Products. 

In order to perform this study, the data were acquired from AWS using PySpark, where they were subsequently cleaned and loaded into a PostgreSQL database. From the database, these data were further analyzed in Python using Pandas, Numpy, SciPy, and Matplotlib. 

---
## AWS/PySpark ETL

The acquisition of data from AWS was performed in Colab Notebooks using Spark version 3.3.0, and then connected to a PostgreSQL to store in a database. The code to set up the Spark session is as follows. 

```python
# Initialize
import os
spark_version = 'spark-3.3.0'
os.environ['SPARK_VERSION']=spark_version

# Install Spark and Java
!apt-get update
!apt-get install openjdk-11-jdk-headless -qq > /dev/null
!wget -q http://www.apache.org/dist/spark/$SPARK_VERSION/$SPARK_VERSION-bin-hadoop3.tgz
!tar xf $SPARK_VERSION-bin-hadoop3.tgz
!pip install -q findspark

# Set Environment Variables
import os
os.environ["JAVA_HOME"] = "/usr/lib/jvm/java-11-openjdk-amd64"
os.environ["SPARK_HOME"] = f"/content/{spark_version}-bin-hadoop3"

# Start a SparkSession
import findspark
findspark.init()

# Download the Postgres driver that will allow Spark to interact with Postgres.
!wget https://jdbc.postgresql.org/download/postgresql-42.2.16.jar


from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("M16-Amazon-Challenge").config("spark.driver.extraClassPath","/content/postgresql-42.2.16.jar").getOrCreate()
```

### Loading Amazon Data into Spark DataFrame

Using PySpark, the US Pet Products information was accessed from the AmazonAWS S3 bucket, saving these data as a .csv dataframe to be transformed to remove and reorganize the data such that they can be separated into different tables for the database.

```python
from pyspark import SparkFiles
url = "https://s3.amazonaws.com/amazon-reviews-pds/tsv/amazon_reviews_us_Pet_Products_v1_00.tsv.gz"
spark.sparkContext.addFile(url)
df = spark.read.option("encoding", "UTF-8").csv(SparkFiles.get("amazon_reviews_us_Pet_Products_v1_00.tsv.gz"), sep="\t", header=True, inferSchema=True)
df.show()
```

    +-----------+-----------+--------------+----------+--------------+--------------------+----------------+-----------+-------------+-----------+----+-----------------+--------------------+--------------------+-------------------+
    |marketplace|customer_id|     review_id|product_id|product_parent|       product_title|product_category|star_rating|helpful_votes|total_votes|vine|verified_purchase|     review_headline|         review_body|        review_date|
    +-----------+-----------+--------------+----------+--------------+--------------------+----------------+-----------+-------------+-----------+----+-----------------+--------------------+--------------------+-------------------+
    |         US|   28794885| REAKC26P07MDN|B00Q0K9604|     510387886|(8-Pack) EZwhelp ...|    Pet Products|          5|            0|          0|   N|                Y|A great purchase ...|Best belly bands ...|2015-08-31 00:00:00|
    |         US|   11488901|R3NU7OMZ4HQIEG|B00MBW5O9W|     912374672|Warren Eckstein's...|    Pet Products|          2|            0|          1|   N|                Y|My dogs love Hugs...|My dogs love Hugs...|2015-08-31 00:00:00|
    |         US|   43214993|R14QJW3XF8QO1P|B0084OHUIO|     902215727|Tyson's True Chew...|    Pet Products|          5|            0|          0|   N|                Y|I have been purch...|I have been purch...|2015-08-31 00:00:00|
    |         US|   12835065|R2HB7AX0394ZGY|B001GS71K2|     568880110|Soft Side Pet Cra...|    Pet Products|          5|            0|          0|   N|                Y|it is easy to ope...|It is extremely w...|2015-08-31 00:00:00|
    |         US|   26334022| RGKMPDQGSAHR3|B004ABH1LG|     692846826|EliteField 3-Door...|    Pet Products|          5|            0|          0|   N|                Y|           Dog crate|Worked really wel...|2015-08-31 00:00:00|
    |         US|   22283621|R1DJCVPQGCV66E|B00AX0LFM4|     590674141|Carlson 68-Inch W...|    Pet Products|          5|            0|          0|   N|                Y|          Five Stars|I love my gates! ...|2015-08-31 00:00:00|
    +-----------+-----------+--------------+----------+--------------+--------------------+----------------+-----------+-------------+-----------+----+-----------------+--------------------+--------------------+-------------------+
   
    
---
### Cleaning the Data

The initial cleaning just removed the data includig NA values, which removed 350 entires out of the 2.6 million reviews. At this point the data were separated into 4 different tables, providing tables for customer information, product information, review attributes, and the final for Vine users, only holding the review ID, star rating, whether the review was flagged as helpful, the total votes, whether the user was paid or not, and whether it was a verified purchase. Only the processes for the Vine table are shown below, since this is the table that was used for the Analysis of Bias. 


```python
vine_df = df.select(["review_id", "star_rating", "helpful_votes", "total_votes", "vine", "verified_purchase"])
```
---
### Connecting to the AWS RDS instance 

Using the driver and passwords set up with PgAdmin for the PostgreSQL RDMS, the tables were written to the AWS RDS instance for analysis in PgAdmin. 

```python
# Write vine_df to table in RDS
# 11 minutes
vine_df.write.jdbc(url=jdbc_url, table='vine_table', mode=mode, properties=config)
```

---
## Analyzing Bias in the Pet Products Reviews

The Vine Information database from AWS was saved locally for analysis using Pandas in Python. 


```python
vine_table.head()
```

<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>review_id</th>
      <th>star_rating</th>
      <th>helpful_votes</th>
      <th>total_votes</th>
      <th>vine</th>
      <th>verified_purchase</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>REAKC26P07MDN</td>
      <td>5</td>
      <td>0</td>
      <td>0</td>
      <td>N</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>1</th>
      <td>R3NU7OMZ4HQIEG</td>
      <td>2</td>
      <td>0</td>
      <td>1</td>
      <td>N</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>2</th>
      <td>R14QJW3XF8QO1P</td>
      <td>5</td>
      <td>0</td>
      <td>0</td>
      <td>N</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>3</th>
      <td>R2HB7AX0394ZGY</td>
      <td>5</td>
      <td>0</td>
      <td>0</td>
      <td>N</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>4</th>
      <td>RGKMPDQGSAHR3</td>
      <td>5</td>
      <td>0</td>
      <td>0</td>
      <td>N</td>
      <td>Y</td>
    </tr>
  </tbody>
</table>
</div>


To further clean the data, the reviews with fewer than 20 votes were removed, since they are potentially new or unreliable reviews. Furthermore, any reviews with no votes would also result in zero division errors.  

```python
# First filter for 20 or more votes
vine_df = vine_table[vine_table.total_votes >= 20]
vine_df.head()
```

<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>review_id</th>
      <th>star_rating</th>
      <th>helpful_votes</th>
      <th>total_votes</th>
      <th>vine</th>
      <th>verified_purchase</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>128</th>
      <td>R21KC552Y6HL8X</td>
      <td>1</td>
      <td>27</td>
      <td>31</td>
      <td>N</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>161</th>
      <td>RX9WC9FTIR1XR</td>
      <td>5</td>
      <td>25</td>
      <td>25</td>
      <td>N</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>256</th>
      <td>RGDCOU1KBHMNG</td>
      <td>3</td>
      <td>29</td>
      <td>31</td>
      <td>N</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>267</th>
      <td>RVTYWID2TPMMY</td>
      <td>2</td>
      <td>35</td>
      <td>42</td>
      <td>N</td>
      <td>Y</td>
    </tr>
    <tr>
      <th>719</th>
      <td>R2CMPZ5VESGRLY</td>
      <td>4</td>
      <td>27</td>
      <td>28</td>
      <td>N</td>
      <td>Y</td>
    </tr>
  </tbody>
</table>
</div>



The second step of cleaning was to remove reviews that weren't flagged as 'Helpful' by at least 50% of the total reviews for that product. 

```python
# Second filter to find products where helpful votes are at least 50% of total
helpful = vine_df[(vine_df.helpful_votes/vine_df.total_votes) >= 0.5]
```

The dataframe was separated into two, with one used to represent the paid Vine users, and the other to represent the unpaid users. 

```python
# Filter the data into 2 dfs with paid vine users and unpaid users
paid = helpful[helpful.vine == 'Y']
unpaid = helpful[helpful.vine == 'N']
```

The initial hypothesis that this is testing was that there would be a bias in the paid user population, with an inflated representation of 5-star reviews. To analyze this, a function was defined to find the total number of reviews, five-star reviews, and the percent of 5-star reviews for the given product. (This function was later modified for further analysis, allowing for observing 'unhelpful' reviews and different star ratings; see further analysis) 

```python
def calculate_reviews(df, rating=5, helpful='helpful'):
    total = df.review_id.count()
    fives = df.star_rating[df.star_rating == rating].count()
    percent = fives/total * 100
    
    if df.iloc[0,4] == "N":
        payment = "unpaid"
    else:
        payment = "paid vine"
     
    return (f'Out of {total:,} reviews, there were {fives:,} {rating}-star reviews. The percent of {helpful} {rating}-star reviews by {payment} users was {percent:.2f}%')
```


```python
# Display the vine users for pet products
calculate_reviews(paid)
```
Out of 170 reviews, there were 65 5-star reviews. The percent of helpful 5-star reviews by paid vine users was 38.24%

```python
# Display the unpaid users for pet products
calculate_reviews(unpaid)
```
Out of 37,823 reviews, there were 20,605 5-star reviews. The percent of helpful 5-star reviews by unpaid users was 54.48%

---
### Analysis

The hypothesis that there would be a bias toward higher ratings with the paid Vine users is not supported with these findings. From the paid Vine users, only 38% of the users provided 5-star reviews, 16% less than the 54% of unpaid users giving 5-star reviews. While the hypothesis is rejected regarding the positive bias, there is a substantial difference between the two groups, which definitely warrants further investigation. Since fewer than 50% of the Vine votes were 5-star reviews, it is important to know how the other votes are distributed, and likewise with the unpaid users. Amazon customers often complain that the 5-star reviews and the 1-star reviews are not always reliable because customers that have any tiny problem will give a 1-star rating, and other users have found certain vendors give incentives to provide 5-star reviews on their products despite the product's performance. Because these reviews are analyzing the same population of products, the distributions should ideally be similar, though it is unlikely given the 16% difference in 5-star ratings alone. 


---
## Further Analysis

### Unhelpful Reviews

The first condition further investigated are the reviews that were not over 50% helpful by the total number of votes. Looking at this could give insight as to how many of the reviews were considered unhelpful compared to those that were helpful between the paid and unpaid users.  
```python
# Further Analysis
# unhelpful reviewers
unhelpful = vine_df[(vine_df.helpful_votes/vine_df.total_votes) < 0.5]
u_paid = unhelpful[unhelpful.vine == 'Y']
u_unpaid = unhelpful[unhelpful.vine == 'N']
(calculate_reviews(u_paid, helpful='unhelpful'),
 calculate_reviews(u_unpaid, helpful='unhelpful'))
```
Out of 2 reviews, there were 0 5-star reviews. The percent of unhelpful 5-star reviews by paid vine users was 0.00%
Out of 1,364 reviews, there were 120 5-star reviews. The percent of unhelpful 5-star reviews by unpaid users was 8.80%

From these outcomes, it is shown that only 2 out of the 170 paid users were considered unhelpful - 1.2% of paid reviews. Meanwhile, 1364 of the 37,823 reviews were considered unhelpful from the unpaid users. While the percentage is higher, at 3.6%, it's still a very low percentage of unhelpful reviews. The big difference is that neither of the two paid reviews were 5-star reviews, yet 8.8% of the unpaid unhelpful reviews were 5-star reviews. Regardless, with only 2 unhelpful reviews from the Vine users, these data will change drastically with even one unhelpful view in the 5-star category, potentially raising it from 0% to 33%, and without a larger sample size, these aren't particularly useful statistics. 

---
### Distribution of Star Ratings

After the initial analysis, noting the difference between the 5-star reviews in the paid and unpaid users, it is worth looking into how each group distributes their star-ratings. 

```python
(calculate_reviews(paid, 4), calculate_reviews(unpaid, 4))
(calculate_reviews(paid, 3), calculate_reviews(unpaid, 3))
(calculate_reviews(paid, 2), calculate_reviews(unpaid, 2))
(calculate_reviews(paid, 1), calculate_reviews(unpaid, 1))
```
Four Star Reviews:
Out of 170 reviews, there were 56 4-star reviews. The percent of helpful 4-star reviews by paid vine users was 32.94%'
Out of 37,823 reviews, there were 4,897 4-star reviews. The percent of helpful 4-star reviews by unpaid users was 12.95%'

Three Star Reviews: 
Out of 170 reviews, there were 27 3-star reviews. The percent of helpful 3-star reviews by paid vine users was 15.88%'
Out of 37,823 reviews, there were 2,710 3-star reviews. The percent of helpful 3-star reviews by unpaid users was 7.16%'

Two Star Reviews
Out of 170 reviews, there were 16 2-star reviews. The percent of helpful 5-star reviews by paid vine users was 9.41%'
Out of 37,823 reviews, there were 2,048 2-star reviews. The percent of helpful 5-star reviews by unpaid users was 5.41%


One Star Reviews: 
Out of 170 reviews, there were 6 1-star reviews. The percent of helpful 5-star reviews by paid vine users was 3.53%'
Out of 37,823 reviews, there were 7,563 1-star reviews. The percent of helpful 5-star reviews by unpaid users was 20.00%


In comparing the paid and unpaid groups, the paid group has a higher percentage of reviews in the 4, 3, and 2 star categories than the unpaid users. However, there is a massive difference between the 1-star reviews in the paid and unpaid users, with the paid Vine reviewers only representing 3.5% of products with 1-star, yet the unpaid users rated 20% of their products as 1-star. Ultimately, while the Amazon Vine reviewers distributed 42% of their reviews between 5 and 1 star reviews, nearly 75% of the unpaid users gave one of those two ratings, leaving a very small proportion of ratings in the 2-4 star categories. 

To visualize this distribution, another function that returns percentages of ratings for each input was used, and the returned data were plotted in a bar plot using matplotlib.


```python
def distribute_reviews(df, helpful='helpful'):
    total = df.review_id.count()
    fives = df.star_rating[df.star_rating == 5].count()
    fours = df.star_rating[df.star_rating == 4].count()
    threes = df.star_rating[df.star_rating == 3].count()
    twos = df.star_rating[df.star_rating == 2].count()
    ones = df.star_rating[df.star_rating == 1].count()

    return [fives/total, fours/total, threes/total, twos/total, ones/total]
```


```python
paid_dist = distribute_reviews(paid)
unpaid_dist = distribute_reviews(unpaid)
x_labels = ["5", "4", "3", "2", "1"]
```

```python
plt.subplots(figsize=(10,6))

x_axis = np.arange(len(x_labels))
plt.bar(x_axis + 0.8, paid_dist, 0.4, label = "Paid")
plt.bar(x_axis + 1.2, unpaid_dist, 0.4, label = "Unpaid")

plt.title("Star Distribution of Paid Vine Users")
plt.xlabel("Rating")
plt.xticks([1, 2, 3, 4, 5], x_labels)
plt.ylabel("Percent of Total")
plt.legend()
plt.show()
```


![Vine_Readme_16_0](https://user-images.githubusercontent.com/33167541/189448050-7f82be04-8050-4641-9b86-254803c1df00.png)


    

The graph clearly shows that there is a tiered rating in place with the Vine reviewers, with the highest group in the 5-star category, and each subsequent star-rating representing a smaller group down to the 3.5% in the 1-star category. On the other hand, the unpaid users have very high proportions in the 5 and 1 star groups, with very few reviewers giving anything between. 

---
### Comparing the Distributions

Qualitatively, the paid and unpaid ratings look like very distributions. In order to statistically show that the groups are indeed different, a 2-sample Kolmogorov-Smirnov (KS) Test was performed. The KS Test shows the equality of continuous or discontinuous 1-D probability distributions to compare (in this case) 2 samples, answering whether the 2 samples could have come from the same data distribution. In this case, the data do come from the same distribution, though the samples look very different. The null hypothesis of the KS test is that both groups were sampled from populations with identical distributions. 


```python
from scipy.stats import ks_2samp
ks_2samp(paid_dist, unpaid_dist)
```
 KstestResult(statistic=0.8, pvalue=0.079)

In interpreting the KS test results, a high KS-statistic indicates that the Null hypothesis can be rejected if the p-value is low enough. however, the p-value remains above the 0.05 threshold, and, thus, it confirms that despite the different appearances of the distributions from the graph, the data do come from the same population of data and cannot be considered significantly different.

---
### Unhelpful 1-Star Ratings

The final analysis was to determine the percent of 1-star reviews from the paid and unpaid users. 
```python
(calculate_reviews(u_paid, 1, helpful="unhelpful"), calculate_reviews(u_unpaid, 1, helpful="unhelpful"))
```
Out of 2 reviews, there were 2 1-star reviews. The percent of unhelpful 1-star reviews by paid vine users was 100.00%
Out of 1,364 reviews, there were 1,010 1-star reviews. The percent of unhelpful 1-star reviews by unpaid users was 74.05%

```python
paid_dist = distribute_reviews(paid)
unpaid_dist = distribute_reviews(unpaid)
x_labels = ["5", "4", "3", "2", "1"]
```

```python
plt.subplots(figsize=(10,6))

x_axis = np.arange(len(x_labels))
plt.bar(x_axis + 1, unpaid_dist, 0.4, label = "Unpaid")

plt.title("Star Distribution of Paid Vine Users")
plt.xlabel("Rating")
plt.xticks([1, 2, 3, 4, 5], x_labels)
plt.ylabel("Percent of Total")
plt.legend()
plt.show()
```

![Vine_Readme_19_0](https://user-images.githubusercontent.com/33167541/189448156-941a58f9-d237-4779-bfdf-b5b8cb226e86.png)


Considering what was presented earlier in the paid Vine reviewer population, the only 2 reviews that were considered unhelpful by the Vine reviewers were these two 1-star reviews. This is not to discount all of the 1-star reviews by the paid reviewers, as there were 6 reviews that were considered helpful with this rating. With the unpaid users, 74% of unhelpful reviews were 1-star reviews. The distribution for these is below. While these are not represented in the first distribution, it shows that there is, if anything, a negative bias in the paid reviewers to provide 1-star reviews in general, and provide more helpful reviews than the high percentages of seemingly unfounded 1-star reviews given by the unpaid group.

---
## Summary

The ultimate question is "What does this mean for our stakeholder?" 
If the initial hypothesis held true, that there was a positive bias with the Amazon Vine users, the service would not provide reliable reviews. Contrarily, these findings show that not only isn't there a positive bias from the paid Vine reviewers, but there is much less of a negative bias than the unpaid users. The aforementioned anecdotal evidence of users only giving 5-star or 1-star ratings is supported by the data from the unpaid reviewers. 

As consumers are looking to make informed decisions about Pet Products to purchase, it is important to consider the ratings of such products. Unfortunately, many product ratings are affected by biases by the reviewers. The assumption that paid reviewers would have a higher bias toward 5-star reviews was not supported by the data, though there was a skew with their highest percentage of reviews being 5-star. The high percentage of 5-star reviews is consistent with the unpaid reviewers. The biggest differences between the groups is in how carefully the products were rated. There were clear tiers from the paid users, suggesting that they spent more time considering the plusses and minuses of the products that they were rating, and didn't just provide an 'all or none' review. This is, however, what the unpaid group suggests - supported by the 74% of helpful reviews being either a 1-star or 5-star review. 

The Amazon Vine program provides a better way for consumers to compare similar products than trusting the unpaid users, as many of those 5-star ratings are likely not 5-star quality products, and conversely many of the 1-star products are probably of a higher quality than is being represented.  
 
