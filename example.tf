page {
    name = "API Non-Functional Requirements"

    # Response Time Widget (Performance)
    widget_line {
      title  = "API Response Time"
      row    = 1
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT average(duration) AS 'Avg Response Time', percentile(duration, 95) AS '95th Percentile', percentile(duration, 99) AS '99th Percentile' FROM Transaction WHERE entityName = '${var.api_service_name}' TIMESERIES AUTO"
      }

      # Thresholds for visual indicators
      critical = 1000  # 1 second
      warning  = 500   # 500 ms
    }

    # Throughput Widget
    widget_line {
      title  = "API Throughput"
      row    = 1
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT count(*) AS 'Requests/Minute' FROM Transaction WHERE entityName = '${var.api_service_name}' TIMESERIES 1 minute"
      }
    }

    # Error Rate Widget
    widget_line {
      title  = "API Error Rate"
      row    = 4
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT percentage(count(*), WHERE error IS true) AS 'Error Rate %' FROM Transaction WHERE entityName = '${var.api_service_name}' TIMESERIES AUTO"
      }

      # Thresholds for visual indicators
      critical = 5   # 5% error rate
      warning  = 1   # 1% error rate
    }

    # Service Level Indicators (SLI) Widget
    widget_table {
      title  = "API Service Level Indicators"
      row    = 4
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT percentage(count(*), WHERE duration < 1000) AS 'Responses < 1s', percentage(count(*), WHERE duration < 500) AS 'Responses < 500ms', percentage(count(*), WHERE duration < 200) AS 'Responses < 200ms', percentage(count(*), WHERE error IS false) AS 'Success Rate' FROM Transaction WHERE entityName = '${var.api_service_name}' SINCE 1 hour AGO"
      }
    }

    # API Success Rate by Endpoint Widget
    widget_bar {
      title  = "API Success Rate by Endpoint"
      row    = 7
      column = 1
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT percentage(count(*), WHERE error IS false) AS 'Success Rate %' FROM Transaction WHERE entityName = '${var.api_service_name}' FACET name LIMIT 10"
      }
    }

    # HTTP Status Code Distribution Widget(error rates)
    widget_pie {
      title  = "HTTP Status Code Distribution"
      row    = 7
      column = 7
      width  = 6
      height = 3

      nrql_query {
        query = "SELECT count(*) FROM Transaction WHERE entityName = '${var.api_service_name}' FACET httpResponseCode LIMIT 10"
      }
    }



    # Uptime Widget
    widget_billboard {
      title  = "API Uptime (Last 24h)"
      row    = 10
      column = 5
      width  = 4
      height = 3

      nrql_query {
        query = "SELECT (1 - percentage(count(*), WHERE error IS true AND httpResponseCode >= 500) / 100) * 100 AS 'Uptime %' FROM Transaction WHERE entityName = '${var.api_service_name}' SINCE 24 hours AGO"
      }
    }

    # API Connection Time Widget
    widget_line {
      title  = "API Connection Time"
      row    = 10
      column = 9
      width  = 4
      height = 3

      nrql_query {
        query = "SELECT average(networkDuration) AS 'Avg Connection Time', percentile(networkDuration, 95) AS '95th Percentile' FROM Transaction WHERE entityName = '${var.api_service_name}' TIMESERIES AUTO"
      }
    }
}