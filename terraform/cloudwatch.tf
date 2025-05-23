# CloudWatch Log Group for EC2
resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/aws/ec2/jenkins"
  retention_in_days = 30
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 30
}
