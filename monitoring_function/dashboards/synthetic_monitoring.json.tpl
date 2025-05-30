{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 15,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 5,
      "panels": [],
      "title": "SYNTETIC Monitoring Platform Dashboard",
      "type": "row"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 1
      },
      "id": 3,
      "panels": [],
      "title": "Certificate Expiration",
      "type": "row"
    },
    {
      "datasource": {
        "default": false,
        "type": "grafana-azure-monitor-datasource",
        "uid": "azure-monitor-oob"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "max": 60,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": null
              },
              {
                "color": "yellow",
                "value": 7
              },
              {
                "color": "green",
                "value": 15
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 11,
        "w": 24,
        "x": 0,
        "y": 2
      },
      "id": 2,
      "options": {
        "displayMode": "lcd",
        "maxVizHeight": 300,
        "minVizHeight": 0,
        "minVizWidth": 8,
        "namePlacement": "top",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": true
        },
        "showUnfilled": true,
        "sizing": "auto",
        "valueMode": "color"
      },
      "pluginVersion": "11.2.8+security-01",
      "targets": [
        {
          "azureLogAnalytics": {
            "dashboardTime": false,
            "query": "customEvents\n| project Domain = tostring(customDimensions.domain), Expire = tostring(unixtime_milliseconds_todatetime(tolong(customMeasurements.targetExpirationTimestamp))), DayToExpire = toint(customMeasurements.targetExpireInDays), Status = toint(customMeasurements.targetStatus), TLSVersion = customMeasurements.targetTlsVersion, checkssl = customDimensions.checkCert, Duration = customMeasurements.duration, timestamp\n| where checkssl == \"true\"\n| summarize arg_max(timestamp, *) by Domain\n| project Domain, DayToExpire\n",
            "resources": [
              "/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers/Microsoft.Insights/components/${application_insights_name}"
            ],
            "resultFormat": "table"
          },
          "azureMonitor": {
            "allowedTimeGrainsMs": [],
            "timeGrain": "auto"
          },
          "datasource": {
            "type": "grafana-azure-monitor-datasource",
            "uid": "azure-monitor-oob"
          },
          "queryType": "Azure Log Analytics",
          "refId": "A"
        }
      ],
      "title": "DAY by Gauge",
      "transformations": [
        {
          "id": "sortBy",
          "options": {
            "fields": {},
            "sort": [
              {
                "desc": true,
                "field": "Domain"
              }
            ]
          }
        },
        {
          "id": "filterByValue",
          "options": {
            "filters": [
              {
                "config": {
                  "id": "isNull",
                  "options": {}
                },
                "fieldName": "DayToExpire"
              }
            ],
            "match": "any",
            "type": "exclude"
          }
        }
      ],
      "transparent": true,
      "type": "bargauge"
    },
    {
      "datasource": {
        "default": false,
        "type": "grafana-azure-monitor-datasource",
        "uid": "azure-monitor-oob"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "custom": {
            "fillOpacity": 60,
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "lineWidth": 3
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": null
              },
              {
                "color": "green",
                "value": 100
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 16,
        "w": 16,
        "x": 0,
        "y": 13
      },
      "id": 6,
      "options": {
        "colWidth": 0.42,
        "legend": {
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "rowHeight": 0.3,
        "showValue": "never",
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "9.5.6",
      "targets": [
        {
          "azureMonitor": {
            "aggregation": "Average",
            "alias": "{{dimensionvalue}}",
            "allowedTimeGrainsMs": [
              60000,
              300000,
              900000,
              1800000,
              3600000,
              21600000,
              43200000,
              86400000
            ],
            "dimensionFilters": [
              {
                "dimension": "availabilityResult/name",
                "filters": [],
                "operator": "eq"
              }
            ],
            "metricName": "availabilityResults/availabilityPercentage",
            "metricNamespace": "microsoft.insights/components",
            "region": "${location_display_name}",
            "resources": [
              {
                "metricNamespace": "microsoft.insights/components",
                "region": "${location_display_name}",
                "resourceGroup": "${resource_group_name}",
                "resourceName": "${application_insights_name}",
                "subscription": "${subscription_id}"
              }
            ],
            "timeGrain": "auto",
            "top": "100"
          },
          "datasource": {
            "type": "grafana-azure-monitor-datasource",
            "uid": "azure-monitor-oob"
          },
          "queryType": "Azure Monitor",
          "refId": "A",
          "subscription": "${subscription_id}"
        }
      ],
      "title": "Availability",
      "type": "status-history"
    },
    {
      "datasource": {
        "default": false,
        "type": "grafana-azure-monitor-datasource",
        "uid": "azure-monitor-oob"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "custom": {
            "align": "auto",
            "cellOptions": {
              "mode": "basic",
              "type": "color-background"
            },
            "filterable": true,
            "inspect": false
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "transparent",
                "value": null
              }
            ]
          }
        },
        "overrides": [
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*/"
            },
            "properties": [
              {
                "id": "links"
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "Domain"
            },
            "properties": [
              {
                "id": "custom.width",
                "value": 407
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "Expire"
            },
            "properties": [
              {
                "id": "custom.width",
                "value": 80
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 16,
        "w": 8,
        "x": 16,
        "y": 13
      },
      "id": 1,
      "options": {
        "cellHeight": "sm",
        "footer": {
          "countRows": false,
          "enablePagination": true,
          "fields": "",
          "reducer": [
            "sum"
          ],
          "show": false
        },
        "showHeader": true,
        "sortBy": []
      },
      "pluginVersion": "11.2.8+security-01",
      "targets": [
        {
          "azureLogAnalytics": {
            "dashboardTime": false,
            "query": "customEvents\n| project Domain = tostring(customDimensions.domain), Expire = unixtime_milliseconds_todatetime(tolong(customMeasurements.targetExpirationTimestamp)), DayToExpire = toint(customMeasurements.targetExpireInDays), Status = toint(customMeasurements.certSuccess), TLS = customMeasurements.targetTlsVersion, checkssl = customDimensions.checkCert, Duration = customMeasurements.duration, timestamp\n| where checkssl == \"true\"\n| summarize arg_max(timestamp, *) by Domain\n| project Domain, format_datetime(Expire,'dd-MM-yy'), TLS",
            "resources": [
              "/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers/Microsoft.Insights/components/${application_insights_name}"
            ],
            "resultFormat": "logs"
          },
          "azureMonitor": {
            "allowedTimeGrainsMs": [],
            "timeGrain": "auto"
          },
          "datasource": {
            "type": "grafana-azure-monitor-datasource",
            "uid": "azure-monitor-oob"
          },
          "queryType": "Azure Log Analytics",
          "refId": "A"
        }
      ],
      "title": "TLS version",
      "type": "table"
    },
    {
      "datasource": {
        "default": false,
        "type": "grafana-azure-monitor-datasource",
        "uid": "azure-monitor-oob"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "custom": {
            "align": "auto",
            "cellOptions": {
              "type": "color-background"
            },
            "filterable": true,
            "inspect": false
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "transparent",
                "value": null
              }
            ]
          }
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "Status"
            },
            "properties": [
              {
                "id": "thresholds",
                "value": {
                  "mode": "absolute",
                  "steps": [
                    {
                      "color": "dark-red",
                      "value": null
                    },
                    {
                      "color": "semi-dark-red",
                      "value": 0
                    },
                    {
                      "color": "semi-dark-green",
                      "value": 1
                    }
                  ]
                }
              },
              {
                "id": "custom.width",
                "value": 112
              },
              {
                "id": "mappings",
                "value": [
                  {
                    "options": {
                      "0": {
                        "index": 0,
                        "text": "KO"
                      },
                      "1": {
                        "index": 1,
                        "text": "OK"
                      }
                    },
                    "type": "value"
                  }
                ]
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*/"
            },
            "properties": [
              {
                "id": "links"
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "DayToExpire"
            },
            "properties": [
              {
                "id": "thresholds",
                "value": {
                  "mode": "absolute",
                  "steps": [
                    {
                      "color": "red",
                      "value": null
                    },
                    {
                      "color": "yellow",
                      "value": 7
                    },
                    {
                      "color": "transparent",
                      "value": 15
                    }
                  ]
                }
              },
              {
                "id": "custom.width",
                "value": 129
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "Domain"
            },
            "properties": [
              {
                "id": "custom.width",
                "value": 910
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "Name"
            },
            "properties": [
              {
                "id": "custom.width",
                "value": 466
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 15,
        "w": 24,
        "x": 0,
        "y": 29
      },
      "id": 4,
      "options": {
        "cellHeight": "sm",
        "footer": {
          "countRows": false,
          "enablePagination": true,
          "fields": "",
          "reducer": [
            "sum"
          ],
          "show": false
        },
        "showHeader": true,
        "sortBy": [
          {
            "desc": false,
            "displayName": "Status"
          }
        ]
      },
      "pluginVersion": "11.2.8+security-01",
      "targets": [
        {
          "azureLogAnalytics": {
            "dashboardTime": false,
            "query": "customEvents\n| project Name = tostring(name), Domain = tostring(customDimensions.endpoint), Expire = unixtime_milliseconds_todatetime(tolong(customMeasurements.targetExpirationTimestamp)), DayToExpire = toint(customMeasurements.targetExpireInDays), Status = toint(customMeasurements.targetStatus), TLSVersion = customMeasurements.targetTlsVersion, checkssl = customDimensions.checkCert, Duration = customMeasurements.duration, timestamp\n| summarize arg_max(timestamp, *) by Domain\n| project Name, Domain, Duration, Status \n",
            "resources": [
              "/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/providers/Microsoft.Insights/components/${application_insights_name}"
            ],
            "resultFormat": "logs"
          },
          "azureMonitor": {
            "allowedTimeGrainsMs": [],
            "timeGrain": "auto"
          },
          "datasource": {
            "type": "grafana-azure-monitor-datasource",
            "uid": "azure-monitor-oob"
          },
          "queryType": "Azure Log Analytics",
          "refId": "A"
        }
      ],
      "title": "HTTP Syntetic Client",
      "type": "table"
    }
  ],
  "refresh": "",
  "schemaVersion": 39,
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "",
  "title": "SYNTETIC Monitoring Platform Dashboard",
  "uid": "fd990b23-14ba-4ed1-a43e-506de880fbc3",
  "weekStart": ""
}
