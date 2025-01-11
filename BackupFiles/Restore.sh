#!/bin/bash

aws s3 ls

# Prompt user for input
read -p "Enter the S3 bucket name: " BUCKET_NAME

aws s3 ls s3://$BUCKET_NAME/

# Prompt user for input
read -p "Enter the S3 backup folder name: " FOLDER_NAME

aws s3 ls s3://$BUCKET_NAME/$FOLDER_NAME/

# Prompt user for input
read -p "Enter the S3 backup file name without only .gz extensions: " FILE_NAME
read -p "Enter the path to download the backup: " BACKUP_PATH
read -p "Enter the MySQL database username: " DB_USER
read -sp "Enter the MySQL database password: " DB_PASS
echo
read -p "Enter the MySQL database name: " DB_NAME

# Download from S3
aws s3 cp s3://$BUCKET_NAME/$FOLDER_NAME/$FILE_NAME.gz $BACKUP_PATH

# Unzip the file
gunzip $BACKUP_PATH/$FILE_NAME.gz

# Restore the MySQL database
mysql -u $DB_USER -p$DB_PASS $DB_NAME < $BACKUP_PATH/$FILE_NAME

#remove backup file

rm -rf $BACKUP_PATH/$FILE_NAME

# Verify the restore
if [ $? -eq 0 ]; then
  echo "Database restore successful."
else
  echo "Database restore failed."
fi
