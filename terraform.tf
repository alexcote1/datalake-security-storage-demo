provider "aws" {
  region = "us-east-2"
}

# Existing S3 Bucket for Fluent Bit Logs
resource "aws_s3_bucket" "fluentbit_logs" {
  bucket = "lantern4222"
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# S3 Bucket for Athena Query Results
resource "aws_s3_bucket" "athena_results" {
  bucket = "joining59622"
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# Server-Side Encryption for Logs S3 Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "fluentbit_logs_encryption" {
  bucket = aws_s3_bucket.fluentbit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Versioning for Logs Bucket
resource "aws_s3_bucket_versioning" "fluentbit_logs_versioning" {
  bucket = aws_s3_bucket.fluentbit_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for Fluent Bit
resource "aws_iam_role" "fluentbit_role" {
  name = "fluentbit-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy Attachment for S3 Access
resource "aws_iam_role_policy_attachment" "fluentbit_s3_policy_attachment" {
  role       = aws_iam_role.fluentbit_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Glue Database for Fluent Bit Logs
resource "aws_glue_catalog_database" "fluentbit_logs_db" {
  name = "fluentbit_logs_db"
}

# Athena Workgroup with S3 Output Location
resource "aws_athena_workgroup" "fluentbit_workgroup" {
  name = "fluentbit_workgroup"

  configuration {
    enforce_workgroup_configuration = true
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }
  }
}

# Glue Catalog Table for Athena Logs
# Glue Catalog Table for Athena Logs
# Glue Catalog Table for Athena Logs
resource "aws_glue_catalog_table" "fluentbit_logs_table" {
  database_name = aws_glue_catalog_database.fluentbit_logs_db.name
  name          = "fluentbit_logs"

  table_type = "EXTERNAL_TABLE"
  parameters = {
    "classification" = "json"
    "compressionType" = "gzip"
      }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.fluentbit_logs.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters= {
        paths= "service,hostname,year,month,day,hour_minute_second"}
    }

    columns {
      name = "date"
      type = "string"
    }

    columns {
      name = "_BOOT_ID"
      type = "string"
    }

    columns {
      name = "_MACHINE_ID"
      type = "string"
    }

    columns {
      name = "_HOSTNAME"
      type = "string"
    }

    columns {
      name = "_RUNTIME_SCOPE"
      type = "string"
    }

    columns {
      name = "PRIORITY"
      type = "string"
    }

    columns {
      name = "SYSLOG_FACILITY"
      type = "string"
    }

    columns {
      name = "_UID"
      type = "string"
    }

    columns {
      name = "_GID"
      type = "string"
    }

    columns {
      name = "_SYSTEMD_SLICE"
      type = "string"
    }

    columns {
      name = "_TRANSPORT"
      type = "string"
    }

    columns {
      name = "SYSLOG_IDENTIFIER"
      type = "string"
    }

    columns {
      name = "SYSLOG_PID"
      type = "string"
    }

    columns {
      name = "SYSLOG_TIMESTAMP"
      type = "string"
    }

    columns {
      name = "MESSAGE"
      type = "string"
    }

    columns {
      name = "_PID"
      type = "string"
    }

    columns {
      name = "_COMM"
      type = "string"
    }

    columns {
      name = "_EXE"
      type = "string"
    }

    columns {
      name = "_CMDLINE"
      type = "string"
    }

    columns {
      name = "_CAP_EFFECTIVE"
      type = "string"
    }

    columns {
      name = "_SYSTEMD_CGROUP"
      type = "string"
    }

    columns {
      name = "_SYSTEMD_UNIT"
      type = "string"
    }

    columns {
      name = "_SYSTEMD_INVOCATION_ID"
      type = "string"
    }

    columns {
      name = "_SOURCE_REALTIME_TIMESTAMP"
      type = "string"
    }
  }

  partition_keys {
    name = "service"
    type = "string"
  }

  partition_keys {
    name = "hostname"
    type = "string"
  }

  partition_keys {
    name = "year"
    type = "int"
  }

  partition_keys {
    name = "month"
    type = "int"
  }

  partition_keys {
    name = "day"
    type = "int"
  }

  partition_keys {
    name = "hour_minute_second"
    type = "string"
  }
}


# Outputs for Reference
output "s3_bucket_name" {
  value = aws_s3_bucket.fluentbit_logs.bucket
}

output "athena_workgroup_name" {
  value = aws_athena_workgroup.fluentbit_workgroup.name
}

output "glue_table_name" {
  value = aws_glue_catalog_table.fluentbit_logs_table.name
}
