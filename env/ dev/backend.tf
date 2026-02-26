terraform {
  backend "s3" {
    bucket         = "cs1-terraform-state-maarten"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}