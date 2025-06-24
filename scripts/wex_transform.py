# Spark 3 / Glue 4 ETL – reads CSVs, de-dupes, writes to MySQL



import sys, json, boto3
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext

# ------------------------------------------------------------------ #
# 1. Job args: just bucket + connection name
# ------------------------------------------------------------------ #
args = getResolvedOptions(
    sys.argv,
    ["JOB_NAME", "s3_bucket", "connection_name"]
)

# ------------------------------------------------------------------ #
# 2. Look up the Glue connection & the secret
# ------------------------------------------------------------------ #
glue   = boto3.client("glue")
secret = boto3.client("secretsmanager")

conn = glue.get_connection(Name=args["connection_name"])["Connection"]
jdbc_url  = conn["ConnectionProperties"]["JDBC_CONNECTION_URL"]
secret_id = conn["ConnectionProperties"]["SECRET_ID"]

creds = json.loads(
    secret.get_secret_value(SecretId=secret_id)["SecretString"]
)
db_user = creds["username"]
db_pass = creds["password"]

# ------------------------------------------------------------------ #
# 3. Spark / Glue boilerplate
# ------------------------------------------------------------------ #
sc  = SparkContext()
gc  = GlueContext(sc)
spark = gc.spark_session
job = Job(gc)
job.init(args["JOB_NAME"], args)

# ------------------------------------------------------------------ #
# 4. Load, clean, write
# ------------------------------------------------------------------ #
raw_path = f"s3://{args['s3_bucket']}/raw/"


df_raw = spark.read \
         .format("csv") \
         .option("header", "true") \
         .option("inferSchema", "true") \
         .csv(raw_path)
if not df_raw.columns:
    raise RuntimeError("No CSV files found under /raw/, nothing to process")

(
    df_raw.write.format("jdbc")
    .option("url", jdbc_url)
    .option("dbtable", "wex_data")
    .option("user", db_user)
    .option("password", db_pass)
    .option("driver", "com.mysql.cj.jdbc.Driver")
    .mode("overwrite")
    .save()
)

job.commit()
print("✔ Data written to MySQL:", jdbc_url)
