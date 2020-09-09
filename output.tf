output "synthetics_id" {

  # newrelic_application Terraform reference 
  # Link : https://www.terraform.io/docs/providers/newrelic/d/application.html
  value = "${newrelic_synthetics_monitor.foo.id}"
}

output "synthetics_dashboard_id" {

  # newrelic_dashboard Terraform reference
  # Link : https://www.terraform.io/docs/providers/newrelic/r/dashboard.html
  value = "${newrelic_dashboard.tf_dashboard_as_code.id}"
}

output "alert_policy_id" {

  # newrelic_alert_policy Terraform reference
  # Link : https://www.terraform.io/docs/providers/newrelic/r/alert_policy.html
  value = "${newrelic_alert_policy.alert_policy_name.id}"
}