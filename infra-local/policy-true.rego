package terraform.aws

import future.keywords.in
import future.keywords.if

# Main evaluation result that contains all checks
evaluation_result := {
    "compliant": is_compliant,
    "resource_findings": resource_findings,
    "resource_counts": resource_counts,
    "security_findings": security_findings,
    "tag_findings": tag_findings
}

# Overall compliance check
is_compliant := count(all_findings) == 0

# Aggregate all findings
# Aggregate all findings
all_findings := array.concat(
    array.concat([x | x := resource_findings[_]], [x | x := security_findings[_]]),
    [x | x := tag_findings[_]]
)


# Resource-specific findings
resource_findings[msg] if {
    vpc := input.configuration.root_module.resources[_]
    vpc.type == "aws_vpc"
    not startswith(vpc.values.cidr_block, "10.0.")
    msg := sprintf("VPC '%s' CIDR %s is not in allowed range (must start with 10.0)", [
        vpc.values.tags.Name,
        vpc.values.cidr_block
    ])
}

resource_findings[msg] if {
    instance := input.planned_values.root_module.resources[_]
    instance.type == "aws_instance"
    not instance.values.instance_type in ["t2.micro", "t2.small", "t3.micro", "t3.small"]
    msg := sprintf("Instance '%s' type %s is not allowed", [
        instance.values.tags.Name,
        instance.values.instance_type
    ])
}

# Security-related findings
security_findings[msg] if {
    instance := input.planned_values.root_module.resources[_]
    instance.type == "aws_instance"
    not instance.values.root_block_device[0].encrypted
    msg := sprintf("Instance '%s' root volume is not encrypted", [
        instance.values.tags.Name
    ])
}

security_findings[msg] if {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    not has_encryption(bucket.bucket)
    msg := sprintf("S3 bucket '%s' is missing server-side encryption", [
        bucket.values.bucket
    ])
}

# Tag compliance findings
tag_findings[msg] if {
    resource := input.planned_values.root_module.resources[_]
    required_tags := {"Name", "Environment"}
    missing_tags := required_tags - object.keys(resource.values.tags)
    count(missing_tags) > 0
    msg := sprintf("Resource '%s' (%s) is missing required tags: %s", [
        resource.address,
        resource.type,
        concat(", ", missing_tags)
    ])
}

# Resource count summary
resource_counts := {
    "vpc_count": count([r | r := input.planned_values.root_module.resources[_]; r.type == "aws_vpc"]),
    "subnet_count": count([r | r := input.planned_values.root_module.resources[_]; r.type == "aws_subnet"]),
    "instance_count": count([r | r := input.planned_values.root_module.resources[_]; r.type == "aws_instance"]),
    "s3_bucket_count": count([r | r := input.planned_values.root_module.resources[_]; r.type == "aws_s3_bucket"])
}

# Helper function to check if a bucket has encryption enabled
has_encryption(bucket_name) if {
    encryption := input.planned_values.root_module.resources[_]
    encryption.type == "aws_s3_bucket_server_side_encryption_configuration"
    encryption.values.rule[0].apply_server_side_encryption_by_default.sse_algorithm == "AES256"
}
