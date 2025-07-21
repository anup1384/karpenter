
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    }
  }
}

locals {
  oidc_provider_arn = replace(replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "/^(.*provider/)/", ""), "https://", "")
}


################################################################################
# Karpenter
################################################################################

module "karpenter" {
  source                          = "../modules/"
  cluster_name                    = data.aws_eks_cluster.cluster.name
  enable_v1_permissions           = true
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = local.node_iam_role_name
  enable_irsa                     = true
  irsa_namespace_service_accounts = ["${local.namespace}:${local.name}"]
  irsa_oidc_provider_arn          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider_arn}"
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}


################################################################################
# Karpenter Helm chart & manifests
# Not required; just to demonstrate functionality of the sub-module
################################################################################

resource "helm_release" "karpenter" {
  namespace  = local.namespace
  name       = local.name
  repository = local.repository
  chart      = "karpenter"
  version    = local.version
  wait       = false
  values     = local.values
}
