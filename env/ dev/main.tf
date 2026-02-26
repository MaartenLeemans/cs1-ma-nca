provider "aws" {
  region = "eu-central-1"
}

module "network" {
  source = "../../terraform/modules/network"
}

module "computer" {
  source            = "../../terraform/modules/computer"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  app_subnet_ids    = module.network.app_subnet_ids
}

module "database" {
  source          = "../../terraform/modules/database"

  vpc_id          = module.network.vpc_id
  db_subnet_ids   = module.network.db_subnet_ids
  ecs_sg_id       = module.computer.ecs_service_security_group_id
  private_zone_id = module.network.private_zone_id

  db_username = var.db_username
  db_password = var.db_password
}