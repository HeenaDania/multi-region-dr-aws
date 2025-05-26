# Primary S3 Bucket
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${var.project_name}-primary-bucket-ncpl"
  
  tags = {
    Name = "${var.project_name}-primary-bucket-ncpl"
  }
}

# Enable versioning on primary bucket
resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Secondary S3 Bucket (for replication)
resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = "${var.project_name}-secondary-bucket-ncpl"
  
  tags = {
    Name = "${var.project_name}-secondary-bucket-ncpl"
  }
}

# Enable versioning on secondary bucket
resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for S3 Replication
resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 Replication
resource "aws_iam_policy" "replication" {
  provider = aws.primary
  name     = "${var.project_name}-s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.secondary.arn}/*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "replication" {
  provider   = aws.primary
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Configure replication
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.primary
  
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.primary]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "entire-bucket-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
    }
  }
}
# SNS Topic for S3 Replication Alerts
resource "aws_sns_topic" "s3_replication_alerts" {
  name = "s3-replication-alerts"
}

resource "aws_sns_topic_subscription" "s3_email" {
  topic_arn = aws_sns_topic.s3_replication_alerts.arn
  protocol  = "email"
  endpoint  = "heena.dania7@gmail.com" 
}

# S3 Event Notification for Replication Failures
resource "aws_s3_bucket_notification" "primary" {
  bucket = aws_s3_bucket.primary.id

  eventbridge = true  # Enable EventBridge for advanced event routing
}

# Use EventBridge to route S3 Replication Failure events to SNS
resource "aws_cloudwatch_event_rule" "s3_replication_failed" {
  name        = "S3ReplicationFailed"
  description = "Alert on S3 replication failure"
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["s3.amazonaws.com"],
      "eventName": ["ReplicationOperationFailed"]
    }
  })
}

resource "aws_cloudwatch_event_target" "s3_replication_failed" {
  rule      = aws_cloudwatch_event_rule.s3_replication_failed.name
  arn       = aws_sns_topic.s3_replication_alerts.arn
}

