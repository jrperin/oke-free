terraform {
  backend "http" {
    update_method = "PUT"
    # Arquivo especifico:
    address = "https://objectstorage.sa-saopaulo-1.oraclecloud.com/_SEU_PATH_/oke-free-terraform_state/o/terraform.tfstate"
  }
}
