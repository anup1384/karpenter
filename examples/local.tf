locals {
  region             = "ap-south-1"
  cluster_name       = "cluster-eks-dev"
  namespace          = "kube-system"
  name               = "karpenter"
  repository         = "oci://public.ecr.aws/karpenter"
  node_iam_role_name = "karpenter-node"
  version            = "1.3.3"
  values = [
    <<-EOT
    nodeSelector:
      nodegroup: "infra"
    tolerations:
      - effect: NoExecute
        key: nodegroup
        operator: Equal
        value: infra
    dnsPolicy: Default
    settings:
      clusterName: ${data.aws_eks_cluster.cluster.name}
      clusterEndpoint: ${data.aws_eks_cluster.cluster.endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      name: karpenter
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    EOT
  ]

}