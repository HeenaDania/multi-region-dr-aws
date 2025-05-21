module "vpc" {
  source = "./vpc.tf"
}
module "s3" {
  source = "./s3.tf"
}
module "rds" {
  source = "./rds.tf"
}
module "ec2" {
  source = "./ec2.tf"
}
module "route53" {
  source = "./route53.tf"
}
