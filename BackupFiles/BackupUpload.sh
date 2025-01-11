#!/bin/bash
# mysql-backup-tool-bucket

# Set default values
DEFAULT_BUCKET_NAME="mysql-backup-tool-bucket"
DEFAULT_BACKUP_PATH="/tmp/demoDBbackup"
DEFAULT_DB_USER="aayush"
DEFAULT_DB_PASS="1234"  
DEFAULT_DB_NAME="ninja"

# Prompt for user input with default values
read -p "Enter the S3 bucket name [$DEFAULT_BUCKET_NAME]: " BUCKET_NAME
BUCKET_NAME=${BUCKET_NAME:-$DEFAULT_BUCKET_NAME}

read -p "Enter the path to save with name the backup [$DEFAULT_BACKUP_PATH]: " BACKUP_PATH
BACKUP_PATH=${BACKUP_PATH:-$DEFAULT_BACKUP_PATH}

read -p "Enter the MySQL database username [$DEFAULT_DB_USER]: " DB_USER
DB_USER=${DB_USER:-$DEFAULT_DB_USER}

# Prompt for password and use the default if nothing is entered
read -sp "Enter the MySQL database password (press enter to use default password): " DB_PASS
echo

# If no password is entered, use the default password
if [ -z "$DB_PASS" ]; then
  DB_PASS=$DEFAULT_DB_PASS
  echo "Using default password."
fi

read -p "Enter the MySQL database name [$DEFAULT_DB_NAME]: " DB_NAME
DB_NAME=${DB_NAME:-$DEFAULT_DB_NAME}

# MySQL database and gzip the backup
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_PATH.sql"
gzip "$BACKUP_PATH.sql"

# Upload the backup to S3
aws s3 cp "$BACKUP_PATH.sql.gz" s3://"$BUCKET_NAME"/backups/

# After cp remove file
rm -rf "$BACKUP_PATH.sql.gz"

# Verify the backup upload
if [ $? -eq 0 ]; then
  echo "Database backup uploaded to S3 successfully."
else
  echo "Database backup upload to S3 failed."
fi
