# DB Subnet Group - Primary
resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "${var.project_name}-primary-db-subnet-group"
  subnet_ids = aws_subnet.primary_private[*].id
  
  tags = {
    Name = "${var.project_name}-primary-db-subnet-group"
  }
}

# DB Subnet Group - Secondary
resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "${var.project_name}-secondary-db-subnet-group"
  subnet_ids = aws_subnet.secondary_private[*].id
  
  tags = {
    Name = "${var.project_name}-secondary-db-subnet-group"
  }
}

# Primary RDS Instance
resource "aws_db_instance" "primary" {
  provider                = aws.primary
  identifier              = "${var.project_name}-primary"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp2"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.primary.name
  vpc_security_group_ids  = [aws_security_group.primary_db.id]
  multi_az                = true
  backup_retention_period = 7
  skip_final_snapshot     = true
  
  tags = {
    Name = "${var.project_name}-primary-rds"
  }
}

# Create Read Replica in Secondary Region
resource "aws_db_instance" "secondary_replica" {
  provider                    = aws.secondary
  identifier                  = "${var.project_name}-secondary-replica"
  replicate_source_db         = aws_db_instance.primary.arn
  instance_class              = var.db_instance_class
  vpc_security_group_ids      = [aws_security_group.secondary_db.id]
  db_subnet_group_name        = aws_db_subnet_group.secondary.name
  skip_final_snapshot         = true
  backup_retention_period     = 7
  auto_minor_version_upgrade  = true
  
  tags = {
    Name = "${var.project_name}-secondary-rds"
  }
}
# SNS Topic for RDS Replication Alerts
resource "aws_sns_topic" "rds_replication_alerts" {
  name = "rds-replication-alerts"
}

resource "aws_sns_topic_subscription" "rds_email" {
  topic_arn = aws_sns_topic.rds_replication_alerts.arn
  protocol  = "email"
  endpoint  = "heena.dania7@gmail.com"
}

# CloudWatch Alarm for RDS Replica Lag
resource "aws_cloudwatch_metric_alarm" "rds_replica_lag" {
  alarm_name          = "RDSReplicaLagAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm if RDS replica lag is greater than 1 second"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.secondary_replica.id
  }
  alarm_actions = [aws_sns_topic.rds_replication_alerts.arn]
}
