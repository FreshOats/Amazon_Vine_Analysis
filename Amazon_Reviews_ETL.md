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

```

    Get:1 https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/ InRelease [3,626 B]
    Get:2 http://security.ubuntu.com/ubuntu bionic-security InRelease [88.7 kB]
    Get:3 http://ppa.launchpad.net/c2d4u.team/c2d4u4.0+/ubuntu bionic InRelease [15.9 kB]
    Ign:4 https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64  InRelease
    Hit:5 https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64  InRelease
    Hit:6 http://archive.ubuntu.com/ubuntu bionic InRelease
    Hit:7 https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64  Release
    Get:8 http://archive.ubuntu.com/ubuntu bionic-updates InRelease [88.7 kB]
    Hit:9 http://ppa.launchpad.net/cran/libgit2/ubuntu bionic InRelease
    Get:10 https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/ Packages [91.7 kB]
    Get:11 http://archive.ubuntu.com/ubuntu bionic-backports InRelease [74.6 kB]
    Get:12 http://ppa.launchpad.net/deadsnakes/ppa/ubuntu bionic InRelease [15.9 kB]
    Hit:13 http://ppa.launchpad.net/graphics-drivers/ppa/ubuntu bionic InRelease
    Get:15 http://ppa.launchpad.net/c2d4u.team/c2d4u4.0+/ubuntu bionic/main Sources [2,099 kB]
    Get:16 http://security.ubuntu.com/ubuntu bionic-security/main amd64 Packages [2,965 kB]
    Get:17 http://archive.ubuntu.com/ubuntu bionic-updates/restricted amd64 Packages [1,172 kB]
    Get:18 http://security.ubuntu.com/ubuntu bionic-security/restricted amd64 Packages [1,131 kB]
    Get:19 http://security.ubuntu.com/ubuntu bionic-security/universe amd64 Packages [1,540 kB]
    Get:20 http://ppa.launchpad.net/c2d4u.team/c2d4u4.0+/ubuntu bionic/main amd64 Packages [1,076 kB]
    Get:21 http://archive.ubuntu.com/ubuntu bionic-updates/main amd64 Packages [3,396 kB]
    Get:22 http://ppa.launchpad.net/deadsnakes/ppa/ubuntu bionic/main amd64 Packages [45.3 kB]
    Fetched 13.8 MB in 4s (3,572 kB/s)
    Reading package lists... Done
    


```python
# Download the Postgres driver that will allow Spark to interact with Postgres.
!wget https://jdbc.postgresql.org/download/postgresql-42.2.16.jar
```

    --2022-09-07 21:00:51--  https://jdbc.postgresql.org/download/postgresql-42.2.16.jar
    Resolving jdbc.postgresql.org (jdbc.postgresql.org)... 72.32.157.228, 2001:4800:3e1:1::228
    Connecting to jdbc.postgresql.org (jdbc.postgresql.org)|72.32.157.228|:443... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 1002883 (979K) [application/java-archive]
    Saving to: ‘postgresql-42.2.16.jar’
    
    postgresql-42.2.16. 100%[===================>] 979.38K  6.17MB/s    in 0.2s    
    
    2022-09-07 21:00:52 (6.17 MB/s) - ‘postgresql-42.2.16.jar’ saved [1002883/1002883]
    
    


```python
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("M16-Amazon-Challenge").config("spark.driver.extraClassPath","/content/postgresql-42.2.16.jar").getOrCreate()
```

### Load Amazon Data into Spark DataFrame


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
    |         US|   14469895|R3V52EAWLPBFQG|B00DQFZGZ0|     688538603|Dog Seat Cover Wi...|    Pet Products|          3|            0|          0|   N|                Y|Seat belt tugs on...|Didn't quite work...|2015-08-31 00:00:00|
    |         US|   50896354|R3DKO8J1J28QBI|B00DIRF9US|     742358789|The Bird Catcher ...|    Pet Products|          2|            0|          0|   N|                Y|Great Pole, but S...|I had the origina...|2015-08-31 00:00:00|
    |         US|   18440567| R764DBXGRNECG|B00JRCBFUG|     869798483|Cat Bed - Purrfec...|    Pet Products|          5|            1|          1|   N|                N|     My cat loves it|The pad is very s...|2015-08-31 00:00:00|
    |         US|   50502362| RW1853GAT0Z9F|B000L3XYZ4|     501118658|PetSafe Drinkwell...|    Pet Products|          5|            0|          0|   N|                Y|          Five Stars|My cat drinks mor...|2015-08-31 00:00:00|
    |         US|   33930128|R33GITXNUF1AD4|B00BOEXWFG|     454737777|Contech ZenDog Ca...|    Pet Products|          2|            0|          0|   N|                Y|Also had to pull ...|Much smaller than...|2015-08-31 00:00:00|
    |         US|   43534290|R1H7AVM81TAYRV|B001HBBQKY|     420905252|Wellness Crunchy ...|    Pet Products|          1|            2|          2|   N|                Y|DO NOT PURCHASE -...|I used to love th...|2015-08-31 00:00:00|
    |         US|   45555864|R2ZOYAQZNNZZWV|B007O1FHB0|     302588963|Rx Vitamins Essen...|    Pet Products|          5|            0|          0|   N|                Y|          Five Stars|Recommended by my...|2015-08-31 00:00:00|
    |         US|   11147406|R2FN1H3CGW6J8H|B001P3NU30|     525778264|Virbac C.E.T. Enz...|    Pet Products|          1|            0|          0|   N|                Y|Received wrong pr...|Yes I  ordered fo...|2015-08-31 00:00:00|
    |         US|    6495678| RJB41Q575XNG4|B00ZP6HS6S|     414117299|Kitty Shack - 2 i...|    Pet Products|          5|            0|          3|   N|                Y|          Five Stars|      It falls apart|2015-08-31 00:00:00|
    |         US|    2019416|R28W8BM1587CPF|B00IP05CUA|     833937853|Wellness Kittles ...|    Pet Products|          5|            0|          0|   N|                Y|kitty is ravenous...|My cat really lov...|2015-08-31 00:00:00|
    |         US|   40459386|R1II0M01NIG293|B001U8Y598|      85343577|OmniPet Anti-Ant ...|    Pet Products|          2|            0|          0|   N|                N|Maybe other speci...|This bowl is not ...|2015-08-31 00:00:00|
    |         US|   23126800| RMB8N0DBRH34O|B011AY4JWO|     499241195|K9KONNECTION [New...|    Pet Products|          5|            1|          1|   N|                Y|This works, dog n...|I have a small do...|2015-08-31 00:00:00|
    |         US|   30238476|R24WB6A6WVIPU6|B00DDSHE5A|     409532388|SUNSEED COMPANY 3...|    Pet Products|          5|            0|          0|   N|                Y|    Yummy for Bunny!|Bunny loves it! E...|2015-08-31 00:00:00|
    |         US|   35113999| ROCJSH0P9YSRW|B00PJW5OR8|     259271919|CXB1983(TM)Cute P...|    Pet Products|          5|            0|          0|   N|                Y|excellent price, ...|Petfect,,quality ...|2015-08-31 00:00:00|
    +-----------+-----------+--------------+----------+--------------+--------------------+----------------+-----------+-------------+-----------+----+-----------------+--------------------+--------------------+-------------------+
    only showing top 20 rows
    
    

### Create DataFrames to match tables


```python
from pyspark.sql.functions import to_date
# Read in the Review dataset as a DataFrame

dirty = df.count()
df = df.dropna()
clean = df.count()

print(dirty, clean)  
# Removed about 350 entries out of 2.6 million

```

    2643619 2643241
    


```python
# Create the customers_table DataFrame
# customers_table: customer_id, customer_count
from pyspark.sql.functions import count
customers_df = df.groupby("customer_id").agg(count("customer_id")).withColumnRenamed("count(customer_id)", "customer_count")
```


```python
# Create the products_table DataFrame and drop duplicates. 
# products_table: product_id, product_title

products_df = df.select(["product_id", "product_title"]).drop_duplicates()
```


```python
# Create the review_id_table DataFrame. 
# Convert the 'review_date' column to a date datatype with to_date("review_date", 'yyyy-MM-dd').alias("review_date")
# review_id_table:  review_id, customer_id, product_id, product_parent, review_date

review_id_df = df.select(["review_id", "customer_id", "product_id", "product_parent", to_date("review_date", 'yyyy-MM-dd').alias("review_date")])
```


```python
# Create the vine_table. DataFrame
# vine_table: review_id, star_rating, helpful_votes, total_votes, vine, verified_purchase

vine_df = df.select(["review_id", "star_rating", "helpful_votes", "total_votes", "vine", "verified_purchase"])
```

### Connect to the AWS RDS instance and write each DataFrame to its table. 


```python
# Configure settings for RDS
from getpass import getpass

password = getpass('Enter Database Password')

mode = "append"
jdbc_url="jdbc:postgresql://vines.czvld1hbpoa9.us-west-1.rds.amazonaws.com:5432/vines_db"
config = {"user":"postgres", 
          "password": password, 
          "driver":"org.postgresql.Driver"}
```


```python
# Write review_id_df to table in RDS
review_id_df.write.jdbc(url=jdbc_url, table='review_id_table', mode=mode, properties=config)
```


```python
# Write products_df to table in RDS
# about 3 min
products_df.write.jdbc(url=jdbc_url, table='products_table', mode=mode, properties=config)
```


```python
# Write customers_df to table in RDS
# 5 min 14 s
customers_df.write.jdbc(url=jdbc_url, table='customers_table', mode=mode, properties=config)
```


```python
# Write vine_df to table in RDS
# 11 minutes
vine_df.write.jdbc(url=jdbc_url, table='vine_table', mode=mode, properties=config)
```


```python

```
