/*
provider "aws" {
  alias  = "org_management"
  region = "us-east-1"
  # Assumes you are running this from the management account
  # Otherwise, configure an explicit provider role
}

resource "aws_organizations_policy" "tagging_scp" {
  provider = aws.org_management
  name     = "EnforceEnvironmentTag"
  description = "Ensures EC2 and RDS instances have an Environment tag. Part of the FinOps Guardian project."
  content  = file("${path.module}/policy.json")
}

# Optional: Automatically attach the policy
# Use with caution! This will immediately enforce the policy.
resource "aws_organizations_policy_attachment" "attach_scp" {
  provider   = aws.org_management
  count      = var.organization_root_id != null ? 1 : 0
  policy_id  = aws_organizations_policy.tagging_scp.id
  target_id  = var.organization_root_id
}*/
