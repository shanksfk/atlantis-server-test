terraform init
terraform plan -out=tfplan.json
terraform apply -auto-approve

opa eval --format pretty --data policy.rego --input tfplan.json "data.terraform.analysis.violations"

