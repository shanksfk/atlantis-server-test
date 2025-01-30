package terraform.analysis

import future.keywords.in
import future.keywords.if

default allow = false

allow if {
    count(violations) == 0
}

violations contains msg if {
    resource := input.configuration.root_module.resources[_]
    valid_name_pattern := "^[a-z0-9-_]+$"

    not regex.match(valid_name_pattern, resource.name)

    msg := sprintf("Resource '%s' has an invalid name '%s'. Names must match the pattern '%s'.", [
        resource.address,
        resource.name,
        valid_name_pattern
    ])
}


violations contains msg if {
    instance := input.configuration.root_module.resources[_]
    instance.type == "aws_instance"
    not instance.expressions.instance_type.constant_value in ["t3.micro", "t3.small"]
#    not instance.expressions.instance_type.constant_value in ["t2.micro", "t3.small"]

    msg := sprintf("Instance '%s' has an invalid instance type '%s'. Allowed types: t3.micro, t3.small", [
        instance.address,
        instance.expressions.instance_type.constant_value
    ])
}

# Rule for S3 bucket tag violation
violations contains msg if {
    bucket := input.configuration.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    not "Team" in object.keys(bucket.expressions.tags.constant_value)
    msg := sprintf("S3 bucket '%s' is missing the 'Team' tag", [bucket.address])
}

# Rule for VPC CIDR block violation
violations contains msg if {
    vpc := input.configuration.root_module.resources[_]
    vpc.type == "aws_vpc"
    cidr := vpc.expressions.cidr_block.constant_value
    cidr_size := to_number(split(cidr, "/")[1])
    cidr_size > 20
    msg := sprintf("VPC '%s' CIDR block '%s' exceeds the allowed range (must be /20 or smaller)", [
        vpc.address,
        cidr
    ])
}

# Rule for subnet public IP mapping violation
violations contains msg if {
    subnet := input.configuration.root_module.resources[_]
    subnet.type == "aws_subnet"
    subnet.expressions.map_public_ip_on_launch.constant_value == true
#    subnet.expressions.map_public_ip_on_launch.constant_value == false

    msg := sprintf("Subnet '%s' allows public IP mapping on launch, which is not allowed", [
        subnet.address
    ])
}
# Rule for database encryption violation
violations contains msg if {
    db := input.configuration.root_module.resources[_]
    db.type == "aws_db_instance"  # Assuming the database is an AWS RDS instance
#    not db.expressions.storage_encrypted.constant_value == true
    not db.expressions.storage_encrypted.constant_value == false
    msg := sprintf("Database '%s' is not encrypted. Encryption must be enabled.", [db.address])
}