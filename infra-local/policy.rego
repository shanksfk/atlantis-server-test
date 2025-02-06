package terraform.analysis

import future.keywords.in
import future.keywords.if

default allow = false

allow if {
    count(violations) == 0
}

violations contains msg if {
    resource := input.planned_values.root_module.resources[_]  # Changed to use planned_values
    valid_name_pattern := "^[a-z0-9-_]+$"

    not regex.match(valid_name_pattern, resource.name)

    msg := sprintf("Resource '%s' has an invalid name '%s'. Names must match the pattern '%s'.", [
        resource.address,
        resource.name,
        valid_name_pattern
    ])
}
