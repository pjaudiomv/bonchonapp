terraform {
  backend "s3" {
    bucket  = "tomato-terraform-state-patrick"
    key     = "service/bonchon.tfstate"
    region  = "us-east-1"
    profile = "pjaudiomv"
  }
}
