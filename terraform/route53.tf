# # Hosted Zone (use existing or create new)
# data "aws_route53_zone" "main" {
#   provider = aws.primary
#   name     = var.domain_name
# }

# # Health Check for Primary ALB
# resource "aws_route53_health_check" "primary" {
#   provider          = aws.primary
#   fqdn              = aws_lb.primary.dns_name
#   port              = 80
#   type              = "HTTP"
#   resource_path     = "/"
#   failure_threshold = 3
#   request_interval  = 30
  
#   tags = {
#     Name = "${var.project_name}-primary-health-check"
#   }
# }

# # Primary Record - Active
# resource "aws_route53_record" "primary" {
#   provider = aws.primary
#   zone_id  = data.aws_route53_zone.main.zone_id
#   name     = "app.${var.domain_name}"
#   type     = "A"
  
#   failover_routing_policy {
#     type = "PRIMARY"
#   }
  
#   set_identifier = "primary"
#   health_check_id = aws_route53_health_check.primary.id
  
#   alias {
#     name                   = aws_lb.primary.dns_name
#     zone_id                = aws_lb.primary.zone_id
#     evaluate_target_health = true
#   }
# }

# # Secondary Record - Passive (DR)
# resource "aws_route53_record" "secondary" {
#   provider = aws.primary
#   zone_id  = data.aws_route53_zone.main.zone_id
#   name     = "app.${var.domain_name}"
#   type     = "A"
  
#   failover_routing_policy {
#     type = "SECONDARY"
#   }
  
#   set_identifier = "secondary"
  
#   alias {
#     name                   = aws_lb.secondary.dns_name
#     zone_id                = aws_lb.secondary.zone_id
#     evaluate_target_health = true
#   }
# }
# SNS Topic for Route 53 Health Alerts
# resource "aws_sns_topic" "route53_health_alerts" {
#   name = "route53-health-alerts"
# }

# resource "aws_sns_topic_subscription" "route53_email" {
#   topic_arn = aws_sns_topic.route53_health_alerts.arn
#   protocol  = "email"
#   endpoint  = "heena.dania7@gmail.com"
# }

# # CloudWatch Alarm for Route 53 Health Check
# resource "aws_cloudwatch_metric_alarm" "route53_health_check" {
#   alarm_name          = "Route53HealthCheckAlarm"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "HealthCheckStatus"
#   namespace           = "AWS/Route53"
#   period              = 60
#   statistic           = "Minimum"
#   threshold           = 1
#   alarm_description   = "Alarm if Route 53 health check fails"
#   dimensions = {
#     HealthCheckId = aws_route53_health_check.primary.id
#   }
#   alarm_actions = [aws_sns_topic.route53_health_alerts.arn]
# }

