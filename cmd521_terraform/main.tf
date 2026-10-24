module "ecr" {
  source = "./modules/ecr"

  repository_name = var.ecr_repository_name
}

module "ecs" {
  source = "./modules/ecs"

  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  app_image         = var.app_image
}
