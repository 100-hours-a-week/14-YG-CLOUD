terraform {
  backend "local" {
    path = "./terraform-shared-management.tfstate"
  }
}
