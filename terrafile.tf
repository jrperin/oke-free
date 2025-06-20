module "compartment" {
  source           = "./compartment"
  compartment_name = var.compartment_name
}

module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.6.0"

  compartment_id = module.compartment.compartment_id
  region         = var.region

  internet_gateway_route_rules = null
  local_peering_gateways       = null
  nat_gateway_route_rules      = null

  vcn_name      = var.vcn_name
  vcn_dns_label = var.vcn_dns_label
  vcn_cidrs     = ["10.0.0.0/16"]

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true
}

module "network" {
  source         = "./network"
  compartment_id = module.compartment.compartment_id
  vcn_id         = module.vcn.vcn_id
  nat_route_id   = module.vcn.nat_route_id
  ig_route_id    = module.vcn.ig_route_id
}

module "cluster" {
  source                 = "./cluster"
  compartment_id         = module.compartment.compartment_id
  cluster_name           = var.cluster_name
  k8s_version            = var.k8s_version
  node_size              = var.node_size
  shape                  = var.shape
  memory_in_gbs_per_node = var.memory_in_gbs_per_node
  ocpus_per_node         = var.ocpus_per_node
  image_id               = var.image_id
  ssh_public_key         = var.ssh_public_key
  public_subnet_id       = module.network.public_subnet_id
  vcn_id                 = module.vcn.vcn_id
  vcn_private_subnet_id  = module.network.vcn_private_subnet_id
}

# Load Balancer vai ser criado automaticamente pelo Ngingx Ingress Controller via Helm Chart
# module "loadbalancer" {
#   source                            = "./loadbalancer"
#   depends_on                        = [ module.cluster, module.network, module.compartment, module.vcn ]
#   namespace                         = var.load_balancer_name_space
#   node_pool_id                      = module.cluster.node_pool_id
#   compartment_id                    = module.compartment.compartment_id
#   public_subnet_id                  = module.network.public_subnet_id
#   node_size                         = var.node_size
#   node_port_http                    = var.node_port_http
#   node_port_https                   = var.node_port_https
#   listener_port_http                = var.listener_port_http
#   listener_port_https               = var.listener_port_https
# }

module "kubeconfig" {
  source = "./kubeconfig"
  # depends_on  = [module.loadbalancer]
  cluster_id  = module.cluster.cluster_id
  oci_profile = var.oci_profile
}

# IP publico do Load Balancer, vamos usar o IP reservado no momento de criacao do load balancer pelo Nginx Ingress Controller
# output "public_ip" {
#   value = module.loadbalancer.load_balancer_public_ip
# }


output "compartment_name" {
  value = module.compartment.compartment_name
}

output "compartment_id" {
  value = module.compartment.compartment_id
}

resource "null_resource" "ip_restore" {
  depends_on = [module.compartment]
  provisioner "local-exec" {
    command = "/bin/bash ip_restore.sh \"${module.compartment.compartment_id}\" \"${module.compartment.compartment_name}\" "
  }
}

resource "null_resource" "ip_backup" {
  provisioner "local-exec" {
    when    = destroy
    command = "/bin/bash ip_backupy.sh"
  }
}
