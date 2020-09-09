# Configure the New Relic provider
provider "newrelic" {
  api_key       = "${var.nr_api_key}"
  admin_api_key = "${var.nr_admin_api_key}"
  account_id    = "${var.nr_account_id}"
  region        = "${var.nr_region}"
  
}

# Configure the New Relic Synthetics Simple monitor
/* resource "newrelic_synthetics_monitor" "bar" {
  name       = "Login Scripts"
  type       = "SIMPLE"
  frequency  = 5
  status     = "ENABLED"
  locations  = ["AWS_US_EAST_1", "AWS_US_EAST_2"]
  uri        = "https://example.com" # Required for type "SIMPLE" and "BROWSER"
  verify_ssl = true                  # Optional for type "SIMPLE" and "BROWSER"
} */

# Configure the New Relic Synthetics API Script
resource "newrelic_synthetics_monitor" "foo" {
  name      ="${var.nr_synthetics_monitor}"
  type      = "SCRIPT_API"
  frequency = 5
  status    = "ENABLED"
  locations = ["AWS_US_EAST_1"]
}

#  the templatefile function offers a built-in mechanism for rendering a template from a file.
data "template_file" "foo_script" {
  template = file("${path.module}/scriptapi.tpl")
}


resource "newrelic_synthetics_monitor_script" "foo_script" {
  monitor_id = newrelic_synthetics_monitor.foo.id
  text       = data.template_file.foo_script.rendered
}

# Configure the New Relic dashboard
resource "newrelic_dashboard" "tf_dashboard_as_code" {
  title    = "Observability: Synthetics"
  editable = "read_only"

 
  widget {
    title         = "Golden Signals Saturation - Database"
    row           = 2
    column        = 3
    visualization = "billboard_comparison"
    nrql          = "SELECT COUNT(*) FROM  SyntheticCheck Where monitorName = '${var.nr_synthetics_monitor}' and  result =  'SUCCESS' since ${var.time} "
  }

  widget {
    title         = "Total Number of Synthetic Checks for ${var.nr_synthetics_monitor} "
    row           = 1
    column        = 2
    visualization = "billboard_comparison"
    nrql          = "SELECT COUNT(*) FROM  SyntheticCheck Where monitorName = '${var.nr_synthetics_monitor}'  since ${var.time} "
  }
 widget {
    title = "Percentage of Unresponsive Checks"
    visualization = "billboard"
    nrql = "SELECT percentage(count(*), WHERE result ='FAILED') FROM SyntheticCheck  where monitorName = '${var.nr_synthetics_monitor}'"
    threshold_red = 2
    threshold_yellow = 1
    row = 1
    column = 2
  }
  widget {
    title = "Number of Unresponsive Checks"
    visualization = "billboard"
    nrql = "SELECT count(*) FROM SyntheticCheck   WHERE result ='FAILED' and monitorName = '${var.nr_synthetics_monitor}'"
    threshold_red = 2
    threshold_yellow = 1
    row = 1
    column = 1
  }
  widget {
    title = "Monitors by  Error Code"
    visualization = "facet_pie_chart"
    nrql = "SELECT count(*) FROM SyntheticCheck  SINCE ${var.time} WHERE result = 'FAILED'  and monitorName = '${var.nr_synthetics_monitor}' FACET error LIMIT 5" 
    row = 2
    column = 1
  }

}



# Create the New Relic alert policy
resource "newrelic_alert_policy" "alert_policy_name" {
  name = "Musement Test"
}

# Add a condition
resource "newrelic_synthetics_alert_condition" "bar" {
  policy_id = "${newrelic_alert_policy.alert_policy_name.id}"

  name        = "Login Scripts"
  monitor_id  = newrelic_synthetics_monitor.foo.id
  runbook_url = "https://www.example.com"
}

# Add a condition
resource "newrelic_nrql_alert_condition" "failure" {
  policy_id = "${newrelic_alert_policy.alert_policy_name.id}"

  name                 = "Synthetics NRQL"
  runbook_url          = "https://docs.example.com/my-runbook"
  enabled              = true
  type                 = "static"
  value_function       = "single_value"
  violation_time_limit = "one_hour"

  critical {
    operator              = "above"
    threshold             = 10
    threshold_duration    = 120
    threshold_occurrences = "at_least_once"
  }

  nrql {
    query             = "SELECT COUNT(*) FROM  SyntheticCheck Where monitorName = '${var.nr_synthetics_monitor}'  and  result =  'SUCCESS' "
    evaluation_offset = 3
  }

}
 // Add a notification channel
resource "newrelic_alert_channel" "tf_alert_email" {
  name = "${var.nr_alert_email}"
  type = "email"

  config {
    recipients              = "${var.nr_alert_email}"
    include_json_attachment = "1"
  }
}

# Link the above notification channel to your policy
resource "newrelic_alert_policy_channel" "tf_alert_email" {
  policy_id   = "${newrelic_alert_policy.alert_policy_name.id}"
  channel_ids = [
    "${newrelic_alert_channel.tf_alert_email.id}"
  ]
}
