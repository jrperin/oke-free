# ----------> Compartment <----------

variable "compartment_name" {
  type    = string
  default = "k8s"
}

variable "region" {
  type    = string
  default = "sa-saopaulo-1"
}

# ---------->VM's----------

variable "shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "ocpus_per_node" {
  type    = number
  default = 1
}

variable "memory_in_gbs_per_node" {
  type    = number
  default = 6
}

# ----------> Image <----------
#
# Ir até esse link:
# https://docs.oracle.com/en-us/iaas/images/ 
# Procurar pela versao mais recente do OKE ex: "OKE Worker Node Oracle Linux 8.x" -> Latest Image: Oracle-Linux-Cloud-Developer-8.10-aarch64-2025.01.31-0
# ATENTAR para ser OKE e do tipo = aarch64 <--
# Entrar no diretorio de imagens e pegar a imagem na regiao correta
# https://docs.oracle.com/en-us/iaas/images/oke-worker-node-oracle-linux-8x/oracle-linux-8.10-aarch64-2024.09.30-0-oke-1.31.1-748.htm
# Brasil:
# - sa-saopaulo-1	ocid1.image.oc1.sa-saopaulo-1.aaaaaaaa4juemojd7gbcragpbbxfvfc4nofosi2xkw7skdbsc7ws434awrma
# - sa-valparaiso-1	ocid1.image.oc1.sa-valparaiso-1.aaaaaaaalbtbofaf2bt24sa7wg4yg2vujpsxn5ndwgfylpc5txxdeo4zv26a
# - sa-vinhedo-1	ocid1.image.oc1.sa-vinhedo-1.aaaaaaaac57ksuk5qpki2mkkhh3sp5b2feinjvbtxki43wlclitk325aor6a
# ATENCAO: O K8s_version precisa estar na mesma versao = 1.31.1
#
variable "image_id" {
  type = string
  # saopaulo-1
  default = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaa4juemojd7gbcragpbbxfvfc4nofosi2xkw7skdbsc7ws434awrma"
}


# ----------> Cluster <----------
variable "k8s_version" {
  type = string
  # Precisa estar na mesma versao do image_id
  default = "v1.31.1"
}

variable "node_size" {
  type    = string
  default = "4"
}

variable "cluster_name" {
  type    = string
  default = "k8s-cluster"
}

# ----------> Network <----------

variable "vcn_name" {
  type    = string
  default = "k8s-vcn"
}

variable "vcn_dns_label" {
  type    = string
  default = "k8svcn"
}

# ----------> Load Balancer <----------

variable "load_balancer_name_space" {
  type    = string
  default = "loadbalancer"
}

variable "node_port_http" {
  type    = number
  default = 30080
}

variable "node_port_https" {
  type    = number
  default = 30443
}

variable "listener_port_http" {
  type    = number
  default = 80
}

variable "listener_port_https" {
  type    = number
  default = 443
}

# ----------> Auth <----------

variable "ssh_public_key" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "private_key_path" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "oci_profile" {
  type = string
}
