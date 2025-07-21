# Karpenter Terraform Module

A comprehensive Terraform module for deploying and configuring Karpenter on Amazon EKS clusters. This module creates all the necessary AWS resources required by Karpenter for automatic node provisioning and management.

## 📁 Directory Structure

```
karpenter-new/
├── examples/                    # Example configurations
│   ├── backend.tf              # Terraform backend configuration
│   ├── data.tf                 # Data sources for EKS cluster
│   ├── local.tf                # Local variables and configuration
│   ├── main.tf                 # Main example configuration
│   └── versions.tf             # Provider version constraints
├── main.tf                     # Main module resources
├── migrations.tf               # Migration configurations
├── outputs.tf                  # Module outputs
├── policy.tf                   # IAM policy definitions
├── README.md                   # This documentation
├── variables.tf                # Input variables
└── versions.tf                 # Provider version constraints
```

## 🚀 Features

- **IAM Role Management**: Creates controller and node IAM roles with appropriate permissions
- **Pod Identity Support**: Supports both EKS Pod Identity and IRSA (IAM Roles for Service Accounts)
- **Spot Termination Handling**: Configures SQS queues and EventBridge rules for spot instance termination
- **Node IAM Role**: Creates IAM roles for nodes launched by Karpenter
- **Access Entry Support**: Optional EKS access entry creation for node authentication
- **Instance Profile**: Optional IAM instance profile creation
- **Comprehensive Tagging**: Full tagging support for all resources
- **Flexible Configuration**: Extensive customization options through variables

## 📋 Prerequisites

- Terraform >= 1.3.2
- AWS Provider >= 5.83
- An existing EKS cluster
- AWS CLI configured with appropriate permissions

## 🔧 Usage

### Basic Usage

```hcl
module "karpenter" {
  source = "./modules/karpenter-new"

  cluster_name = "my-eks-cluster"
  
  # Enable v1 permissions for Karpenter v1+
  enable_v1_permissions = true
  
  # Configure IRSA
  enable_irsa = true
  irsa_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLE"
  irsa_namespace_service_accounts = ["kube-system:karpenter"]
  
  # Additional node IAM policies
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
    Project     = "karpenter"
  }
}
```

### Advanced Configuration

```hcl
module "karpenter" {
  source = "./modules/karpenter-new"

  cluster_name = "my-eks-cluster"
  
  # Controller IAM Role Configuration
  create_iam_role = true
  iam_role_name   = "KarpenterController"
  iam_role_use_name_prefix = false
  
  # Node IAM Role Configuration
  create_node_iam_role = true
  node_iam_role_name   = "KarpenterNode"
  node_iam_role_use_name_prefix = false
  node_iam_role_attach_cni_policy = true
  
  # Spot Termination Configuration
  enable_spot_termination = true
  queue_name = "Karpenter-Spot-Termination"
  
  # Access Entry Configuration (requires EKS cluster with API authentication mode)
  create_access_entry = false  # Set to false if cluster doesn't support access entries
  
  # Pod Identity Configuration
  enable_pod_identity = true
  namespace = "kube-system"
  service_account = "karpenter"
  
  # Additional IAM policies
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
    Project     = "karpenter"
    Owner       = "platform-team"
  }
}
```

### Using Existing Node IAM Role

```hcl
module "karpenter" {
  source = "./modules/karpenter-new"

  cluster_name = "my-eks-cluster"
  
  # Use existing node IAM role
  create_node_iam_role = false
  node_iam_role_arn    = "arn:aws:iam::123456789012:role/existing-node-role"
  
  # Disable access entry since existing role may already have permissions
  create_access_entry = false
  
  enable_v1_permissions = true
  enable_irsa = true
  irsa_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.region.amazonaws.com/id/EXAMPLE"
  irsa_namespace_service_accounts = ["kube-system:karpenter"]

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

## 📖 Example Configuration

The `examples/` directory contains a complete working example:

### Example Structure
- `examples/main.tf` - Main module configuration with Helm chart deployment
- `examples/local.tf` - Local variables and Karpenter configuration
- `examples/data.tf` - Data sources for EKS cluster information
- `examples/backend.tf` - Terraform backend configuration
- `examples/versions.tf` - Provider version constraints

### Running the Example

```bash
cd examples
terraform init
terraform plan
terraform apply
```

## 🔑 Key Resources Created

### IAM Resources
- **Controller IAM Role**: Role for Karpenter controller with necessary permissions
- **Node IAM Role**: Role for nodes launched by Karpenter
- **IAM Policies**: Scoped policies for controller and node operations
- **Instance Profile**: Optional instance profile for node IAM role

### AWS Services
- **SQS Queue**: For handling spot termination events
- **EventBridge Rules**: For monitoring EC2 events (spot interruption, health events, etc.)
- **Access Entry**: Optional EKS access entry for node authentication
- **Pod Identity Association**: For EKS Pod Identity support

## ⚙️ Configuration Options

### Authentication Methods

#### EKS Pod Identity (Recommended)
```hcl
enable_pod_identity = true
namespace = "kube-system"
service_account = "karpenter"
```

#### IRSA (IAM Roles for Service Accounts)
```hcl
enable_irsa = true
irsa_oidc_provider_arn = "arn:aws:iam::ACCOUNT:oidc-provider/oidc.eks.REGION.amazonaws.com/id/EXAMPLE"
irsa_namespace_service_accounts = ["kube-system:karpenter"]
```

### Spot Termination Handling
```hcl
enable_spot_termination = true
queue_name = "Karpenter-Spot-Termination"
```

### Node IAM Role Configuration
```hcl
create_node_iam_role = true
node_iam_role_name = "KarpenterNode"
node_iam_role_attach_cni_policy = true
node_iam_role_additional_policies = {
  AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

## 🔧 Troubleshooting

### Access Entry Error
If you encounter an error like:
```
InvalidRequestException: The cluster's authentication mode must be set to one of [API, API_AND_CONFIG_MAP] to perform this operation.
```

Set `create_access_entry = false` in your module configuration.

### Helm Provider Configuration
For newer versions of the Helm provider, use this syntax:
```hcl
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    }
  }
}
```

## 📊 Outputs

The module provides the following outputs:

- `iam_role_arn` - Controller IAM role ARN
- `iam_role_name` - Controller IAM role name
- `node_iam_role_arn` - Node IAM role ARN
- `node_iam_role_name` - Node IAM role name
- `queue_arn` - SQS queue ARN
- `queue_name` - SQS queue name
- `queue_url` - SQS queue URL
- `event_rules` - Map of EventBridge rules
- `instance_profile_arn` - Instance profile ARN (if created)
- `node_access_entry_arn` - Access entry ARN (if created)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This module is licensed under the MIT License.

## 🔗 References

- [Karpenter Documentation](https://karpenter.sh/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.83 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.83 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_eks_access_entry.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_pod_identity_association.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.controller_additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_sqs_queue.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.controller_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.node_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.v033](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.v1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_entry_type"></a> [access\_entry\_type](#input\_access\_entry\_type) | Type of the access entry. `EC2_LINUX`, `FARGATE_LINUX`, or `EC2_WINDOWS`; defaults to `EC2_LINUX` | `string` | `"EC2_LINUX"` | no |
| <a name="input_ami_id_ssm_parameter_arns"></a> [ami\_id\_ssm\_parameter\_arns](#input\_ami\_id\_ssm\_parameter\_arns) | List of SSM Parameter ARNs that Karpenter controller is allowed read access (for retrieving AMI IDs) | `list(string)` | `[]` | no |
| <a name="input_cluster_ip_family"></a> [cluster\_ip\_family](#input\_cluster\_ip\_family) | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. Note: If `ipv6` is specified, the `AmazonEKS_CNI_IPv6_Policy` must exist in the account. This policy is created by the EKS module with `create_cni_ipv6_iam_policy = true` | `string` | `"ipv4"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the EKS cluster | `string` | `""` | no |
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created (affects nearly all resources) | `bool` | `true` | no |
| <a name="input_create_access_entry"></a> [create\_access\_entry](#input\_create\_access\_entry) | Determines whether an access entry is created for the IAM role used by the node IAM role | `bool` | `true` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Determines whether an IAM role is created | `bool` | `true` | no |
| <a name="input_create_instance_profile"></a> [create\_instance\_profile](#input\_create\_instance\_profile) | Whether to create an IAM instance profile | `bool` | `false` | no |
| <a name="input_create_node_iam_role"></a> [create\_node\_iam\_role](#input\_create\_node\_iam\_role) | Determines whether an IAM role is created or to use an existing IAM role | `bool` | `true` | no |
| <a name="input_create_pod_identity_association"></a> [create\_pod\_identity\_association](#input\_create\_pod\_identity\_association) | Determines whether to create pod identity association | `bool` | `false` | no |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | Determines whether to enable support for IAM role for service accounts | `bool` | `false` | no |
| <a name="input_enable_pod_identity"></a> [enable\_pod\_identity](#input\_enable\_pod\_identity) | Determines whether to enable support for EKS pod identity | `bool` | `true` | no |
| <a name="input_enable_spot_termination"></a> [enable\_spot\_termination](#input\_enable\_spot\_termination) | Determines whether to enable native spot termination handling | `bool` | `true` | no |
| <a name="input_enable_v1_permissions"></a> [enable\_v1\_permissions](#input\_enable\_v1\_permissions) | Determines whether to enable permissions suitable for v1+ (`true`) or for v0.33.x-v0.37.x (`false`) | `bool` | `false` | no |
| <a name="input_iam_policy_description"></a> [iam\_policy\_description](#input\_iam\_policy\_description) | IAM policy description | `string` | `"Karpenter controller IAM policy"` | no |
| <a name="input_iam_policy_name"></a> [iam\_policy\_name](#input\_iam\_policy\_name) | Name of the IAM policy | `string` | `"KarpenterController"` | no |
| <a name="input_iam_policy_path"></a> [iam\_policy\_path](#input\_iam\_policy\_path) | Path of the IAM policy | `string` | `"/"` | no |
| <a name="input_iam_policy_statements"></a> [iam\_policy\_statements](#input\_iam\_policy\_statements) | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) - used for adding specific IAM permissions as needed | `any` | `[]` | no |
| <a name="input_iam_policy_use_name_prefix"></a> [iam\_policy\_use\_name\_prefix](#input\_iam\_policy\_use\_name\_prefix) | Determines whether the name of the IAM policy (`iam_policy_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | IAM role description | `string` | `"Karpenter controller IAM role"` | no |
| <a name="input_iam_role_max_session_duration"></a> [iam\_role\_max\_session\_duration](#input\_iam\_role\_max\_session\_duration) | Maximum API session duration in seconds between 3600 and 43200 | `number` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name of the IAM role | `string` | `"KarpenterController"` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Path of the IAM role | `string` | `"/"` | no |
| <a name="input_iam_role_permissions_boundary_arn"></a> [iam\_role\_permissions\_boundary\_arn](#input\_iam\_role\_permissions\_boundary\_arn) | Permissions boundary ARN to use for the IAM role | `string` | `null` | no |
| <a name="input_iam_role_policies"></a> [iam\_role\_policies](#input\_iam\_role\_policies) | Policies to attach to the IAM role in `{'static_name' = 'policy_arn'}` format | `map(string)` | `{}` | no |
| <a name="input_iam_role_tags"></a> [iam\_role\_tags](#input\_iam\_role\_tags) | A map of additional tags to add the the IAM role | `map(any)` | `{}` | no |
| <a name="input_iam_role_use_name_prefix"></a> [iam\_role\_use\_name\_prefix](#input\_iam\_role\_use\_name\_prefix) | Determines whether the name of the IAM role (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_irsa_assume_role_condition_test"></a> [irsa\_assume\_role\_condition\_test](#input\_irsa\_assume\_role\_condition\_test) | Name of the [IAM condition operator](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition_operators.html) to evaluate when assuming the role | `string` | `"StringEquals"` | no |
| <a name="input_irsa_namespace_service_accounts"></a> [irsa\_namespace\_service\_accounts](#input\_irsa\_namespace\_service\_accounts) | List of `namespace:serviceaccount`pairs to use in trust policy for IAM role for service accounts | `list(string)` | <pre>[<br/>  "karpenter:karpenter"<br/>]</pre> | no |
| <a name="input_irsa_oidc_provider_arn"></a> [irsa\_oidc\_provider\_arn](#input\_irsa\_oidc\_provider\_arn) | OIDC provider arn used in trust policy for IAM role for service accounts | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace to associate with the Karpenter Pod Identity | `string` | `"kube-system"` | no |
| <a name="input_node_iam_role_additional_policies"></a> [node\_iam\_role\_additional\_policies](#input\_node\_iam\_role\_additional\_policies) | Additional policies to be added to the IAM role | `map(string)` | `{}` | no |
| <a name="input_node_iam_role_arn"></a> [node\_iam\_role\_arn](#input\_node\_iam\_role\_arn) | Existing IAM role ARN for the IAM instance profile. Required if `create_iam_role` is set to `false` | `string` | `null` | no |
| <a name="input_node_iam_role_attach_cni_policy"></a> [node\_iam\_role\_attach\_cni\_policy](#input\_node\_iam\_role\_attach\_cni\_policy) | Whether to attach the `AmazonEKS_CNI_Policy`/`AmazonEKS_CNI_IPv6_Policy` IAM policy to the IAM IAM role. WARNING: If set `false` the permissions must be assigned to the `aws-node` DaemonSet pods via another method or nodes will not be able to join the cluster | `bool` | `true` | no |
| <a name="input_node_iam_role_description"></a> [node\_iam\_role\_description](#input\_node\_iam\_role\_description) | Description of the role | `string` | `null` | no |
| <a name="input_node_iam_role_max_session_duration"></a> [node\_iam\_role\_max\_session\_duration](#input\_node\_iam\_role\_max\_session\_duration) | Maximum API session duration in seconds between 3600 and 43200 | `number` | `null` | no |
| <a name="input_node_iam_role_name"></a> [node\_iam\_role\_name](#input\_node\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_node_iam_role_path"></a> [node\_iam\_role\_path](#input\_node\_iam\_role\_path) | IAM role path | `string` | `"/"` | no |
| <a name="input_node_iam_role_permissions_boundary"></a> [node\_iam\_role\_permissions\_boundary](#input\_node\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_node_iam_role_tags"></a> [node\_iam\_role\_tags](#input\_node\_iam\_role\_tags) | A map of additional tags to add to the IAM role created | `map(string)` | `{}` | no |
| <a name="input_node_iam_role_use_name_prefix"></a> [node\_iam\_role\_use\_name\_prefix](#input\_node\_iam\_role\_use\_name\_prefix) | Determines whether the Node IAM role name (`node_iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_queue_kms_data_key_reuse_period_seconds"></a> [queue\_kms\_data\_key\_reuse\_period\_seconds](#input\_queue\_kms\_data\_key\_reuse\_period\_seconds) | The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again | `number` | `null` | no |
| <a name="input_queue_kms_master_key_id"></a> [queue\_kms\_master\_key\_id](#input\_queue\_kms\_master\_key\_id) | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK | `string` | `null` | no |
| <a name="input_queue_managed_sse_enabled"></a> [queue\_managed\_sse\_enabled](#input\_queue\_managed\_sse\_enabled) | Boolean to enable server-side encryption (SSE) of message content with SQS-owned encryption keys | `bool` | `true` | no |
| <a name="input_queue_name"></a> [queue\_name](#input\_queue\_name) | Name of the SQS queue | `string` | `null` | no |
| <a name="input_rule_name_prefix"></a> [rule\_name\_prefix](#input\_rule\_name\_prefix) | Prefix used for all event bridge rules | `string` | `"Karpenter"` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Service account to associate with the Karpenter Pod Identity | `string` | `"karpenter"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_event_rules"></a> [event\_rules](#output\_event\_rules) | Map of the event rules created and their attributes |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the controller IAM role |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | The name of the controller IAM role |
| <a name="output_iam_role_unique_id"></a> [iam\_role\_unique\_id](#output\_iam\_role\_unique\_id) | Stable and unique string identifying the controller IAM role |
| <a name="output_instance_profile_arn"></a> [instance\_profile\_arn](#output\_instance\_profile\_arn) | ARN assigned by AWS to the instance profile |
| <a name="output_instance_profile_id"></a> [instance\_profile\_id](#output\_instance\_profile\_id) | Instance profile's ID |
| <a name="output_instance_profile_name"></a> [instance\_profile\_name](#output\_instance\_profile\_name) | Name of the instance profile |
| <a name="output_instance_profile_unique"></a> [instance\_profile\_unique](#output\_instance\_profile\_unique) | Stable and unique string identifying the IAM instance profile |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace associated with the Karpenter Pod Identity |
| <a name="output_node_access_entry_arn"></a> [node\_access\_entry\_arn](#output\_node\_access\_entry\_arn) | Amazon Resource Name (ARN) of the node Access Entry |
| <a name="output_node_iam_role_arn"></a> [node\_iam\_role\_arn](#output\_node\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the node IAM role |
| <a name="output_node_iam_role_name"></a> [node\_iam\_role\_name](#output\_node\_iam\_role\_name) | The name of the node IAM role |
| <a name="output_node_iam_role_unique_id"></a> [node\_iam\_role\_unique\_id](#output\_node\_iam\_role\_unique\_id) | Stable and unique string identifying the node IAM role |
| <a name="output_queue_arn"></a> [queue\_arn](#output\_queue\_arn) | The ARN of the SQS queue |
| <a name="output_queue_name"></a> [queue\_name](#output\_queue\_name) | The name of the created Amazon SQS queue |
| <a name="output_queue_url"></a> [queue\_url](#output\_queue\_url) | The URL for the created Amazon SQS queue |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | Service Account associated with the Karpenter Pod Identity |
<!-- END_TF_DOCS -->
