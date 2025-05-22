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
