package terraform.analysis

import future.keywords.in
import future.keywords.if

default allow = false

allow if {
    count(violations_lists) == 0
}

violations_lists[msg] if {
    resource := input.planned_values.root_module.resources[_]
    valid_name_pattern := "^[a-z0-9-_]+$"

    not regex.match(valid_name_pattern, resource.name)

    msg := sprintf("Resource '%s' has an invalid name '%s'. Names must match the pattern '%s'.", [
        resource.address,
        resource.name,
        valid_name_pattern
    ])
}

violations_lists[msg] if {
    resource := input.planned_values.root_module.resources[_]
    required_tags := {"kin-billing-agency", "operations-owner", "product-owner", "technical-contact"}

    not resource.tags

    msg := sprintf("Resource '%s' is missing required tags. Expected tags: %v.", [
        resource.address,
        required_tags
    ])
}

violations_lists[msg] if {
    resource := input.configurations.root_module.resources[_]
    required_tags := {"kin-billing-agency", "operations-owner", "product-owner", "technical-contact"}

    missing_tags := {tag | some tag in required_tags; not resource.tags[tag]}

    count(missing_tags) > 0

    msg := sprintf("Resource '%s' is missing the following required tags: %v.", [
        resource.address,
        missing_tags
    ])
}

violations := [msg | msg := key; data.terraform.analysis.violations_lists[key]]
