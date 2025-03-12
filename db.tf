terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.15.0"
    }
  }
}

provider "newrelic" {
  account_id = var.new_relic_account_id
  api_key    = var.new_relic_api_key
  region     = var.new_relic_region # "US" or "EU"
}

# Variables
variable "new_relic_account_id" {
  description = "New Relic Account ID"
  type        = number
}

variable "new_relic_api_key" {
  description = "New Relic API Key"
  type        = string
  sensitive   = true
}

variable "new_relic_region" {
  description = "New Relic region (US or EU)"
  type        = string
  default     = "US"
}

variable "policy_name" {
  description = "Name of the alert policy"
  type        = string
  default     = "Database Monitoring"
}

variable "database_name" {
  description = "Name of the database being monitored"
  type        = string
}

# Alert policy for database monitoring
resource "newrelic_alert_policy" "database_policy" {
  name                = "${var.policy_name} - ${var.database_name}"
  incident_preference = "PER_CONDITION"
}

# 1. Query Response Time Alert Condition
resource "newrelic_nrql_alert_condition" "high_query_response_time" {
  account_id                     = var.new_relic_account_id
  policy_id                      = newrelic_alert_policy.database_policy.id
  type                           = "static"
  name                           = "High Query Response Time"
  description                    = "Alert when query response time exceeds threshold"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  aggregation_method             = "event_timer"
  aggregation_delay              = 120

  nrql {
    query = "SELECT average(duration) FROM Transaction WHERE databaseCallCount > 0 AND entityName = '${var.database_name}' FACET query"
  }

  critical {
    operator              = "above"
    threshold             = 1000 # 1 second in milliseconds
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "above"
    threshold             = 500 # 0.5 seconds in milliseconds
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }
}

# 2. Connection Pool Alert Condition
resource "newrelic_nrql_alert_condition" "connection_pool_saturation" {
  account_id                     = var.new_relic_account_id
  policy_id                      = newrelic_alert_policy.database_policy.id
  type                           = "static"
  name                           = "Connection Pool Saturation"
  description                    = "Alert when connection pool is near capacity"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  aggregation_method             = "event_flow"
  aggregation_delay              = 120

  nrql {
    query = "SELECT latest(activeConnections) / latest(maxConnections) * 100 as 'Pool Utilization %' FROM DatabaseSample WHERE entityName = '${var.database_name}'"
  }

  critical {
    operator              = "above"
    threshold             = 90 # 90% of connection pool used
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "above"
    threshold             = 75 # 75% of connection pool used
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }
}

# 3. Long Running Queries Alert Condition
resource "newrelic_nrql_alert_condition" "long_running_queries" {
  account_id                     = var.new_relic_account_id
  policy_id                      = newrelic_alert_policy.database_policy.id
  type                           = "static"
  name                           = "Long Running Queries"
  description                    = "Alert when queries run longer than threshold"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  aggregation_method             = "event_flow"
  aggregation_delay              = 120

  nrql {
    query = "SELECT count(*) FROM DatabaseQuerySample WHERE entityName = '${var.database_name}' AND duration > 30 FACET query"
  }

  critical {
    operator              = "above"
    threshold             = 5 # 5 or more long-running instances of the same query
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "above"
    threshold             = 3
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }
}

# 4. CPU Utilization Alert Condition
resource "newrelic_nrql_alert_condition" "high_cpu_utilization" {
  account_id                     = var.new_relic_account_id
  policy_id                      = newrelic_alert_policy.database_policy.id
  type                           = "static"
  name                           = "High CPU Utilization"
  description                    = "Alert when database server CPU utilization is high"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  aggregation_method             = "event_flow"
  aggregation_delay              = 120

  nrql {
    query = "SELECT average(cpuPercent) FROM DatabaseSample WHERE entityName = '${var.database_name}'"
  }

  critical {
    operator              = "above"
    threshold             = 90 # 90% CPU utilization
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "above"
    threshold             = 75 # 75% CPU utilization
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }
}

# 5. Memory Utilization Alert Condition
resource "newrelic_nrql_alert_condition" "high_memory_utilization" {
  account_id                     = var.new_relic_account_id
  policy_id                      = newrelic_alert_policy.database_policy.id
  type                           = "static"
  name                           = "High Memory Utilization"
  description                    = "Alert when database server memory utilization is high"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  aggregation_method             = "event_flow"
  aggregation_delay              = 120

  nrql {
    query = "SELECT average(memoryUsedPercent) FROM DatabaseSample WHERE entityName = '${var.database_name}'"
  }

  critical {
    operator              = "above"
    threshold             = 90 # 90% memory used
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "above"
    threshold             = 80 # 80% memory used
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }
}

# 6. Index Usage Alert Condition
resource "newrelic_nrql_alert_condition" "low_index_usage" {
  account_id                     = var.new_relic_account_id
  policy_id                      = newrelic_alert_policy.database_policy.id
  type                           = "static"
  name                           = "Low Index Usage"
  description                    = "Alert when query index usage is low"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  aggregation_method             = "event_flow"
  aggregation_delay              = 120

  nrql {
    query = "SELECT average(indexUsage) FROM DatabaseQuerySample WHERE entityName = '${var.database_name}' FACET query"
  }

  critical {
    operator              = "below"
    threshold             = 20 # Less than 20% index usage
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "below"
    threshold             = 40 # Less than 40% index usage
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }
}

# 7. Disk Space Alert Condition
resource "newrelic_nrql_alert_condition" "disk_space_critical" {
  account_id                     = var.new_relic_account_id
  policy_id                      = newrelic_alert_policy.database_policy.id
  type                           = "static"
  name                           = "Database Disk Space Critical"
  description                    = "Alert when database disk space is running low"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  aggregation_method             = "event_flow"
  aggregation_delay              = 120

  nrql {
    query = "SELECT average(diskUsedPercent) FROM DatabaseSample WHERE entityName = '${var.database_name}'"
  }

  critical {
    operator              = "above"
    threshold             = 90 # 90% disk used
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "above"
    threshold             = 80 # 80% disk used
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }
}

# Dashboard for Database Monitoring
resource "newrelic_one_dashboard" "database_dashboard" {
  name        = "${var.database_name} Database Performance"
  permissions = "public_read_only"

  page {
    name = "Database Performance Overview"

    # Header with key metrics
    widget_billboard {
      title  = "Average Query Response Time (ms)"
      row    = 1
      column = 1
      width  = 3
      height = 2

      nrql_query {
        query = "SELECT average(duration) FROM Transaction WHERE databaseCallCount > 0 AND entityName = '${var.database_name}'"
      }
    }

    widget_billboard {
      title  = "Connection Pool %"
      row    = 1
      column = 4
      width  = 3
      height = 2

      nrql_query {
        query = "SELECT latest(activeConnections) / latest(maxConnections) * 100 as 'Pool %' FROM DatabaseSample WHERE entityName = '${var.database_name}'"
      }
    }

    widget_billboard {
      title  = "CPU %"
      row    = 1
      column = 7
      width  = 2
      height = 2

      nrql_query {
        query = "SELECT latest(cpuPercent) FROM DatabaseSample WHERE entityName = '${var.database_name}'"
      }
    }

    widget_billboard {
      title  = "Memory %"
      row    = 1
      column = 9
      width  = 2
      height = 2

      nrql_query {
        query = "SELECT latest(memoryUsedPercent) FROM DatabaseSample WHERE entityName = '${var.database_name}'"
      }
    }

    widget_billboard {
      title  = "Disk %"
      row    = 1
      column = 11
      width  = 2
      height = 2

      nrql_query {
        query = "SELECT latest(diskUsedPercent) FROM DatabaseSample WHERE entityName = '${var.database_name}'"
      }
    }

    # Query Performance Section
    widget_markdown {
      title  = ""
      row    = 3
      column = 1
      width  = 12
      height = 1
      text   = "## Query Performance"
    }

    widget_line {
      title  = "Query Response Time Trends"
      row    = 4
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(duration) FROM Transaction WHERE databaseCallCount > 0 AND entityName = '${var.database_name}' TIMESERIES AUTO"
      }
    }

    widget_line {
      title  = "Top 5 Slowest Queries"
      row    = 4
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(duration) FROM Transaction WHERE databaseCallCount > 0 AND entityName = '${var.database_name}' TIMESERIES AUTO FACET query LIMIT 5"
      }
    }

    widget_table {
      title  = "Long Running Queries"
      row    = 7
      column = 1
      width  = 12
      height = 3

      nrql_query {
        query = "SELECT count(*) as count, max(duration) as 'Max Duration (s)', average(duration) as 'Avg Duration (s)' FROM DatabaseQuerySample WHERE entityName = '${var.database_name}' AND duration > 5 FACET query LIMIT 10"
      }
    }

    # Connection Pool Section
    widget_markdown {
      title  = ""
      row    = 10
      column = 1
      width  = 12
      height = 1
      text   = "## Connection Pool"
    }

    widget_area {
      title  = "Connection Pool Usage Trend"
      row    = 11
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT latest(activeConnections) as 'Active', latest(maxConnections) as 'Max' FROM DatabaseSample WHERE entityName = '${var.database_name}' TIMESERIES AUTO"
      }
    }

    widget_line {
      title  = "Connection Pool Utilization %"
      row    = 11
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT latest(activeConnections) / latest(maxConnections) * 100 as 'Pool Utilization %' FROM DatabaseSample WHERE entityName = '${var.database_name}' TIMESERIES AUTO"
      }
    }

    # Resource Utilization Section
    widget_markdown {
      title  = ""
      row    = 14
      column = 1
      width  = 12
      height = 1
      text   = "## Resource Utilization"
    }

    widget_line {
      title  = "Resource Utilization Trends"
      row    = 15
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(cpuPercent) as 'CPU', average(memoryUsedPercent) as 'Memory', average(diskUsedPercent) as 'Disk' FROM DatabaseSample WHERE entityName = '${var.database_name}' TIMESERIES AUTO"
      }
    }

    widget_bar {
      title  = "Current Resource Utilization"
      row    = 15
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT latest(cpuPercent) as 'CPU', latest(memoryUsedPercent) as 'Memory', latest(diskUsedPercent) as 'Disk' FROM DatabaseSample WHERE entityName = '${var.database_name}' FACET entityName"
      }
    }

    # Index Performance Section
    widget_markdown {
      title  = ""
      row    = 18
      column = 1
      width  = 12
      height = 1
      text   = "## Index Performance"
    }

    widget_bar {
      title  = "Index Usage by Query"
      row    = 19
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(indexUsage) as 'Index Usage %' FROM DatabaseQuerySample WHERE entityName = '${var.database_name}' FACET query LIMIT 10"
      }
    }

    widget_line {
      title  = "Index Usage Trend"
      row    = 19
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(indexUsage) as 'Avg Index Usage %' FROM DatabaseQuerySample WHERE entityName = '${var.database_name}' TIMESERIES AUTO"
      }
    }
  }
}

# Output for dashboard URL
output "dashboard_url" {
  value = "https://one.newrelic.com/launcher/dashboards.launcher?pane=eyJuZXJkbGV0SWQiOiJkYXNoYm9hcmRzLmRhc2hib2FyZCJ9&dashboard=${newrelic_one_dashboard.database_dashboard.guid}"
  description = "URL to the created dashboard"
}