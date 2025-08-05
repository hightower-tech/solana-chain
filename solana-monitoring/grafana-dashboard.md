{
  "__inputs": [
    {
      "name": "DS_PROMETHEUS",
      "label": "prometheus",
      "description": "",
      "type": "datasource",
      "pluginId": "prometheus",
      "pluginName": "Prometheus"
    }
  ],
  "__elements": {},
  "__requires": [
    {
      "type": "panel",
      "id": "bargauge",
      "name": "Bar gauge",
      "version": ""
    },
    {
      "type": "grafana",
      "id": "grafana",
      "name": "Grafana",
      "version": "11.6.1"
    },
    {
      "type": "datasource",
      "id": "prometheus",
      "name": "Prometheus",
      "version": "1.0.0"
    },
    {
      "type": "panel",
      "id": "stat",
      "name": "Stat",
      "version": ""
    },
    {
      "type": "panel",
      "id": "text",
      "name": "Text",
      "version": ""
    },
    {
      "type": "panel",
      "id": "timeseries",
      "name": "Time series",
      "version": ""
    }
  ],
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "datasource",
          "uid": "grafana"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "description": "This dashboard can help you run a Solana validator. All metrics are fetched from RPC using the solana cli. Please check our github https://github.com/htwtech/solana-monitoring . You are free to change this dashboard as you wish. ",
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 1,
  "id": null,
  "links": [],
  "liveNow": true,
  "panels": [
    {
      "gridPos": {
        "h": 3,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 153,
      "options": {
        "code": {
          "language": "plaintext",
          "showLineNumbers": false,
          "showMiniMap": false
        },
        "content": "<div style=\"display: flex; align-items: flex-start; gap: 12px;\">\r\n  <img \r\n    src=\"https://brand-kit.htw.tech/logo/logo_solana_style_64x64.png\"\r\n    style=\"height: 60px; width: auto; align-self: flex-start; margin-top: 0px;\">\r\n\r\n  <div style=\"flex: 1;\">\r\n    <div>\r\n      <b>Independence is in the code. Strength is in the consensus. Reliability is in our nodes.</b>\r\n      <p style=\"margin: 2px 0;\">\r\n        This dashboard can help you run a Solana validator. All metrics are fetched from RPC using the solana cli. Please check our <a href=\"https://github.com/htwtech/solana-monitoring\" target=\"_blank\">GitHub\r\n        </a>. You are free to change this dashboard as you wish.\r\n      </p>\r\n    </div>\r\n    <div style=\"text-align: right;\">\r\n      Best regards, <a href=\"https://htw.tech/\" target=\"_blank\">Hightower team</a>.\r\n    </div>\r\n  </div>\r\n</div>\r\n\r\n",
        "mode": "html"
      },
      "pluginVersion": "11.6.1",
      "transparent": true,
      "type": "text"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 3
      },
      "id": 115,
      "panels": [],
      "repeat": "server",
      "title": "Quick stats",
      "type": "row"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 0,
          "mappings": [
            {
              "options": {
                "0": {
                  "text": "Validating"
                },
                "1": {
                  "text": "Up"
                },
                "2": {
                  "text": "Error"
                },
                "3": {
                  "text": "Delinquent"
                }
              },
              "type": "value"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              },
              {
                "color": "purple",
                "value": 1
              },
              {
                "color": "#d936ff",
                "value": 2
              },
              {
                "color": "#ff44fb",
                "value": 3
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 0,
        "y": 4
      },
      "id": 54,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_status{instance=\"${instance}\",job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Status",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "description": "",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 2,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 2,
        "y": 4
      },
      "id": 147,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "solana_validator_epochCredits{instance=\"${instance}\" ,job=\"${job}\"} / (solana_validator_slotIndex{instance=\"${instance}\" ,job=\"${job}\"} * 16)  * 100",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Vote %",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "description": "Sometime shows more then 100%",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 2,
          "fieldMinMax": false,
          "mappings": [],
          "max": 100,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 4,
        "y": 4
      },
      "id": 143,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "delta(solana_validator_credits{instance=\"${instance}\" ,job=\"${job}\"}[5m]) / (delta(solana_validator_slotIndex{instance=\"${instance}\" ,job=\"${job}\"}[5m]) * 16) * 100",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Momentary Vote %",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 2,
          "displayName": "Skiprate",
          "mappings": [],
          "max": 100,
          "min": 0,
          "noValue": "0",
          "thresholds": {
            "mode": "percentage",
            "steps": [
              {
                "color": "semi-dark-purple"
              },
              {
                "color": "light-purple",
                "value": 10
              },
              {
                "color": "#ff44fb",
                "value": 25
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 6,
        "y": 4
      },
      "id": 62,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "value",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_pctSkipped{instance=\"${instance}\",job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Skiprate",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 0,
          "displayName": "Skiprate",
          "mappings": [],
          "noValue": "0",
          "thresholds": {
            "mode": "percentage",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 8,
        "y": 4
      },
      "id": 99,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "value",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_leaderSlots{instance=\"${instance}\",job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Leaderslots this epoch",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 0,
          "displayName": "Skiprate",
          "mappings": [],
          "noValue": "0",
          "thresholds": {
            "mode": "percentage",
            "steps": [
              {
                "color": "light-purple"
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 10,
        "y": 4
      },
      "id": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "value",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_skippedSlots{instance=\"${instance}\",job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Missed Slots",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "description": "",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "noValue": "0",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "SOL"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 12,
        "y": 4
      },
      "id": 43,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_activatedStake{instance=\"${instance}\",job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Active Stake",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 14,
        "y": 4
      },
      "id": 146,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_epochCredits{instance=\"${instance}\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "Credits {{instance}}",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Credits Current Epoch",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 16,
        "y": 4
      },
      "id": 141,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "delta(solana_validator_credits{instance=\"${instance}\" ,job=\"${job}\"}[5m])",
          "instant": false,
          "legendFormat": "Credits {{instance}}",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Credits Rate [5min]",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 18,
        "y": 4
      },
      "id": 134,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "solana_validator_lastVote{instance=\"${instance}\",job=\"${job}\"}",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Last Vote",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 20,
        "y": 4
      },
      "id": 133,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "solana_validator_rootSlot{instance=\"${instance}\",job=\"${job}\"}",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Root Slot",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 22,
        "y": 4
      },
      "id": 136,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "rate(solana_validator_tps{instance=\"$instance\",job=\"${job}\"}[5m])",
          "legendFormat": "TPS",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Solana TPS [5min]",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "description": "System load over all CPU cores together",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "dark-purple"
              },
              {
                "color": "#ff44fb",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 2,
        "x": 0,
        "y": 6
      },
      "id": 131,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "scalar(node_load1{instance=\"$instance\",job=\"${job}\"}) * 100 / count(count(node_cpu_seconds_total{instance=\"$instance\",job=\"${job}\"}) by (cpu))",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Sys Load",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 1,
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "dark-purple"
              },
              {
                "color": "light-purple",
                "value": 12
              },
              {
                "color": "#ff44fb",
                "value": 15
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 2,
        "x": 2,
        "y": 6
      },
      "id": 69,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "scalar(node_load1{instance=\"${instance}\",job=\"${job}\"})",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Server Load 1m",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "decimals": 4,
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "dark-purple"
              },
              {
                "color": "light-purple",
                "value": 1
              },
              {
                "color": "#ff44fb",
                "value": 5
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 2,
        "x": 4,
        "y": 6
      },
      "id": 67,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_pressure_io_waiting_seconds_total{instance=\"${instance}\",job=\"${job}\"}[$__rate_interval])",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "IOWait",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "dark-purple"
              },
              {
                "color": "light-purple",
                "value": 70
              },
              {
                "color": "#ff44fb",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 2,
        "x": 6,
        "y": 6
      },
      "id": 73,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "100 * (1 - avg(rate(node_cpu_seconds_total{mode=\"idle\", instance=\"${instance}\",job=\"${job}\"}[$__rate_interval])))",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "CPU usage",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "dark-purple"
              },
              {
                "color": "light-purple",
                "value": 70
              },
              {
                "color": "#ff45fc",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 2,
        "x": 8,
        "y": 6
      },
      "id": 52,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "(1 - (node_memory_MemAvailable_bytes{instance=\"$instance\",job=\"${job}\"} / node_memory_MemTotal_bytes{instance=\"$instance\",job=\"${job}\"})) * 100",
          "hide": false,
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "RAM usage",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "decimals": 0,
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              },
              {
                "color": "light-purple",
                "value": 75
              },
              {
                "color": "#ff44fb",
                "value": 85
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 2,
        "x": 10,
        "y": 6
      },
      "id": 89,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "100 - ((node_filesystem_avail_bytes{instance=\"${instance}\" ,job=\"${job}\",  mountpoint=\"${ledger}\"} * 100) / node_filesystem_size_bytes{instance=\"${instance}\" ,job=\"${job}\",  mountpoint=\"${ledger}\"})",
          "instant": false,
          "legendFormat": "",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Ledger usage",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "decimals": 0,
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              },
              {
                "color": "light-purple",
                "value": 70
              },
              {
                "color": "#ff44fb",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 2,
        "x": 12,
        "y": 6
      },
      "id": 71,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "100 - ((node_filesystem_avail_bytes{instance=\"${instance}\" ,job=\"${job}\",  mountpoint=\"${accounts}\"} * 100) / node_filesystem_size_bytes{instance=\"${instance}\" ,job=\"${job}\",  mountpoint=\"${accounts}\"})",
          "instant": false,
          "legendFormat": "",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Accounts usage",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "decimals": 0,
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "dark-purple"
              },
              {
                "color": "light-purple",
                "value": 50
              },
              {
                "color": "#ff44fb",
                "value": 70
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 2,
        "x": 14,
        "y": 6
      },
      "id": 80,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "00 - ((node_filesystem_avail_bytes{instance=\"${instance}\" ,job=\"${job}\",  mountpoint=\"${ramdisk}\"} * 100) / node_filesystem_size_bytes{instance=\"${instance}\" ,job=\"${job}\",  mountpoint=\"${ramdisk}\"})",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "RAMdisk usage",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "decimals": 0,
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              },
              {
                "color": "light-purple",
                "value": 70
              },
              {
                "color": "#ff44fb",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 2,
        "x": 16,
        "y": 6
      },
      "id": 90,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "100 - ((node_filesystem_avail_bytes{instance=\"${instance}\"  ,job=\"${job}\", mountpoint=\"/\"} * 100) / node_filesystem_size_bytes{instance=\"${instance}\" ,job=\"${job}\",mountpoint=\"/\"})",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "/ usage",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 0,
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 18,
        "y": 6
      },
      "id": 98,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_epoch{instance=\"${instance}\",job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Epoch",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "dateTimeAsIso"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 20,
        "y": 6
      },
      "id": 124,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_epochEnds{instance=\"${instance}\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Epoch Ends",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "mappings": [],
          "max": 100,
          "min": 0,
          "thresholds": {
            "mode": "percentage",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 22,
        "y": 6
      },
      "id": 97,
      "options": {
        "displayMode": "gradient",
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "maxVizHeight": 300,
        "minVizHeight": 16,
        "minVizWidth": 8,
        "namePlacement": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showUnfilled": true,
        "sizing": "auto",
        "text": {},
        "valueMode": "color"
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_pctEpochElapsed{instance=\"${instance}\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Epoch% Progress",
      "type": "bargauge"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 18,
        "y": 8
      },
      "id": 29,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_version{instance=\"${instance}\",job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Solana Version",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "decimals": 1,
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "color": "light-purple",
                  "index": 0,
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "s"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 20,
        "y": 8
      },
      "id": 92,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "node_time_seconds{instance=\"${instance}\",job=\"${job}\"} - node_boot_time_seconds{instance=\"${instance}\",job=\"${job}\"}",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Uptime",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "semi-dark-purple"
              }
            ]
          },
          "unit": "dateTimeFromNow"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 2,
        "w": 2,
        "x": 22,
        "y": 8
      },
      "id": 142,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "solana_validator_timeStamp{instance=\"${instance}\",job=\"${job}\"}",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Last update",
      "type": "stat"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 10
      },
      "id": 117,
      "panels": [],
      "title": "Validator Stats",
      "type": "row"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "description": "sometimes shows more then 100%",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "dashed"
            }
          },
          "decimals": 2,
          "mappings": [],
          "max": 100,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "purple"
              },
              {
                "color": "#d7ff00",
                "value": 100
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 11
      },
      "id": 145,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "lastNotNull"
          ],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "delta(solana_validator_credits{instance=\"${instance}\" ,job=\"${job}\"}[5m]) / (delta(solana_validator_slotIndex{instance=\"${instance}\" ,job=\"${job}\"}[5m]) * 16) * 100\r\n",
          "hide": false,
          "instant": false,
          "legendFormat": "Vote Percentage",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Momentary Vote Percentage [5m]",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "fieldMinMax": false,
          "mappings": [],
          "max": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "Slot"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 11
      },
      "id": 137,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "solana_validator_rootDistance{instance=\"${instance}\" ,job=\"${job}\"}",
          "legendFormat": "",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Root Distance",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "dashed"
            }
          },
          "decimals": 2,
          "mappings": [],
          "max": 100,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "purple"
              },
              {
                "color": "#d7ff00",
                "value": 100
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 19
      },
      "id": 126,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "lastNotNull"
          ],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_epochCredits{instance=\"${instance}\" ,job=\"${job}\"} / (solana_validator_slotIndex{instance=\"${instance}\" ,job=\"${job}\"} * 16)  * 100",
          "hide": false,
          "instant": false,
          "legendFormat": "Vote Percentage",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Vote Percentage",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 19
      },
      "id": 138,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "solana_validator_voteDistance{instance=\"${instance}\" ,job=\"${job}\"}",
          "legendFormat": "__auto",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Vote Distance",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 27
      },
      "id": 144,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "last"
          ],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_epochCredits{instance=\"${instance}\" ,job=\"${job}\"}",
          "hide": true,
          "instant": false,
          "legendFormat": "Current Credits",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_epochCredits{instance=\"${instance}\" ,job=\"${job}\"} - solana_validator_slotIndex{instance=\"${instance}\" ,job=\"${job}\"} * 16 ",
          "hide": false,
          "instant": false,
          "legendFormat": "Credits lag",
          "range": true,
          "refId": "B"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_slotIndex{instance=\"${instance}\" ,job=\"${job}\"} * 16",
          "hide": true,
          "instant": false,
          "legendFormat": "Max Possible Credits",
          "range": true,
          "refId": "C"
        }
      ],
      "title": "Credits Lag",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "dashed"
            }
          },
          "decimals": 2,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "transparent"
              },
              {
                "color": "dark-red",
                "value": 25
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "Cluster Skiprate"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "mode": "thresholds"
                }
              },
              {
                "id": "thresholds",
                "value": {
                  "mode": "absolute",
                  "steps": [
                    {
                      "color": "#3b27aa"
                    },
                    {
                      "color": "dark-orange",
                      "value": 24.9999
                    }
                  ]
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "My Skiprate"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#b765ff",
                  "mode": "fixed"
                }
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 27
      },
      "id": 56,
      "interval": "1m",
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "last"
          ],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_pctSkipped{instance=\"${instance}\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "My Skiprate",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_pctTotSkipped{instance=\"${instance}\" ,job=\"${job}\"}",
          "hide": false,
          "instant": false,
          "legendFormat": "Cluster Skiprate",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "Skiprate",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "Credits / min",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 35
      },
      "id": 61,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "lastNotNull"
          ],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "delta(solana_validator_credits{instance=\"${instance}\" ,job=\"${job}\"}[5m])",
          "instant": false,
          "legendFormat": "Credits {{instance}}",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Credits Rate [5min]",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 35
      },
      "id": 75,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "lastNotNull"
          ],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_leaderSlots{instance=\"${instance}\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "Leaderslots",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_skippedSlots{instance=\"${instance}\" ,job=\"${job}\"}",
          "hide": false,
          "instant": false,
          "legendFormat": "Skipped",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "My Leaderslots",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 43
      },
      "id": 121,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "last"
          ],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_epochCredits{instance=\"${instance}\" ,job=\"${job}\"}",
          "hide": false,
          "instant": false,
          "legendFormat": "Current Credits",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_slotIndex{instance=\"${instance}\" ,job=\"${job}\"} * 16 - solana_validator_epochCredits{instance=\"${instance}\" ,job=\"${job}\"}",
          "hide": true,
          "instant": false,
          "legendFormat": "Credits lagging",
          "range": true,
          "refId": "B"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_slotIndex{instance=\"${instance}\" ,job=\"${job}\"} * 16",
          "hide": false,
          "instant": false,
          "legendFormat": "Max Possible Credits",
          "range": true,
          "refId": "C"
        }
      ],
      "title": "Credits Current Epoch",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "description": "",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "decimals": 2,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "SOL"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 43
      },
      "id": 4,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "lastNotNull"
          ],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_validatorBalance{instance=\"${instance}\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "Balance",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Balance on Identity Acccount [SOL]",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 51
      },
      "id": 132,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "desc"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "rate(solana_validator_tps{instance=\"$instance\" ,job=\"${job}\"}[5m])",
          "legendFormat": "TPS",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        }
      ],
      "title": "Solana TPS [5m]",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "description": "",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "SOL"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 51
      },
      "id": 122,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_activatedStake{instance=\"${instance}\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "Stake",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Active Stake [SOL]",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 59
      },
      "id": 76,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_pctTotDelinquent{instance=\"${instance}\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "% Total Delinquent",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "% Cluster Total Delinquent",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "description": "",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 59
      },
      "id": 57,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "solana_validator_validatorVoteBalance{instance=\"${instance}\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "Balance",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Balance on Vote Account [SOL]",
      "type": "timeseries"
    },
    {
      "collapsed": false,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 67
      },
      "id": 113,
      "panels": [],
      "title": "System Stats",
      "type": "row"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "dashed+area"
            }
          },
          "links": [],
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#7f7af826"
              },
              {
                "color": "red",
                "value": 0.6
              }
            ]
          },
          "unit": "percentunit"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 0,
        "y": 68
      },
      "id": 104,
      "interval": "1m",
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "lastNotNull",
            "mean",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true,
          "sortBy": "Mean",
          "sortDesc": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "desc"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$instance\", mode=\"system\" ,job=\"${job}\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$instance\" ,job=\"${job}\"}) by (cpu)))",
          "instant": false,
          "legendFormat": "System - Processes executing in kernel mode",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$instance\", mode=\"user\" ,job=\"${job}\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$instance\" ,job=\"${job}\"}) by (cpu)))",
          "hide": false,
          "instant": false,
          "legendFormat": "User - Normal processes executing in user mode",
          "range": true,
          "refId": "B"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$instance\", mode=\"nice\" ,job=\"${job}\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$instance\" ,job=\"${job}\"}) by (cpu)))",
          "hide": false,
          "instant": false,
          "legendFormat": "Nice - Niced processes executing in user mode",
          "range": true,
          "refId": "C"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "sum by(instance) (irate(node_cpu_seconds_total{instance=\"$instance\", mode=\"iowait\" ,job=\"${job}\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$instance\" ,job=\"${job}\"}) by (cpu)))",
          "hide": false,
          "instant": false,
          "legendFormat": "Iowait - Waiting for I/O to complete",
          "range": true,
          "refId": "D"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$instance\", mode=\"irq\" ,job=\"${job}\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$instance\" ,job=\"${job}\"}) by (cpu)))",
          "hide": false,
          "instant": false,
          "legendFormat": "Irq - Servicing interrupts",
          "range": true,
          "refId": "E"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$instance\", mode=\"softirq\" ,job=\"${job}\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$instance\" ,job=\"${job}\"}) by (cpu)))",
          "hide": false,
          "instant": false,
          "legendFormat": "Softirq - Servicing softirqs",
          "range": true,
          "refId": "F"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$instance\", mode=\"steal\" ,job=\"${job}\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$instance\" ,job=\"${job}\"}) by (cpu)))",
          "hide": false,
          "instant": false,
          "legendFormat": "Steal - Time spent in other operating systems when running in a virtualized environment",
          "range": true,
          "refId": "G"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "sum(irate(node_cpu_seconds_total{instance=\"$instance\", mode=\"idle\" ,job=\"${job}\"}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{instance=\"$instance\" ,job=\"${job}\"}) by (cpu)))",
          "hide": false,
          "instant": false,
          "legendFormat": "Idle - Waiting for something to happen",
          "range": true,
          "refId": "H"
        }
      ],
      "title": "CPU usage",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "IO read (-) / write (+)",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "iops"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*Read.*/"
            },
            "properties": [
              {
                "id": "custom.transform",
                "value": "negative-Y"
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 12,
        "y": 68
      },
      "id": 127,
      "options": {
        "legend": {
          "calcs": [
            "lastNotNull",
            "mean",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "irate(node_disk_reads_completed_total{instance=\"$instance\" ,job=\"${job}\"}[$__rate_interval])",
          "legendFormat": "{{device}} - Reads completed",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_disk_writes_completed_total{instance=\"$instance\" ,job=\"${job}\"}[$__rate_interval])",
          "hide": false,
          "instant": false,
          "legendFormat": "{{device}} - Writes completed",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "Disk IOps Completed",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": true,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "links": [],
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "bytes"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "RAM Total"
            },
            "properties": [
              {
                "id": "custom.fillOpacity",
                "value": 5
              },
              {
                "id": "color",
                "value": {
                  "fixedColor": "#08d1a1",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "RAM Used"
            },
            "properties": [
              {
                "id": "custom.fillOpacity",
                "value": 0
              },
              {
                "id": "color",
                "value": {
                  "fixedColor": "#a325cf",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "RAM Free"
            },
            "properties": [
              {
                "id": "custom.fillOpacity",
                "value": 10
              },
              {
                "id": "color",
                "value": {
                  "fixedColor": "#1acc03",
                  "mode": "fixed"
                }
              },
              {
                "id": "custom.transform",
                "value": "negative-Y"
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "SWAP Used"
            },
            "properties": [
              {
                "id": "custom.transform"
              }
            ]
          },
          {
            "matcher": {
              "id": "byName",
              "options": "RAM Cache + Buffer"
            },
            "properties": [
              {
                "id": "custom.transform"
              },
              {
                "id": "color",
                "value": {
                  "fixedColor": "#fa00e6",
                  "mode": "fixed"
                }
              },
              {
                "id": "custom.fillOpacity",
                "value": 0
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 0,
        "y": 80
      },
      "id": 108,
      "interval": "1m",
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "lastNotNull",
            "mean",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true,
          "sortBy": "Last *",
          "sortDesc": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "node_memory_MemTotal_bytes{instance=\"$instance\" ,job=\"${job}\"}",
          "instant": false,
          "legendFormat": "RAM Total",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "node_memory_MemTotal_bytes{instance=\"$instance\" ,job=\"${job}\"} - node_memory_MemFree_bytes{instance=\"$instance\" ,job=\"${job}\"} - (node_memory_Cached_bytes{instance=\"$instance\" ,job=\"${job}\"} + node_memory_Buffers_bytes{instance=\"$instance\" ,job=\"${job}\"} + node_memory_SReclaimable_bytes{instance=\"$instance\" ,job=\"${job}\"})",
          "hide": false,
          "instant": false,
          "legendFormat": "RAM Used",
          "range": true,
          "refId": "B"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "node_memory_Cached_bytes{instance=\"$instance\" ,job=\"${job}\"} + node_memory_Buffers_bytes{instance=\"$instance\" ,job=\"${job}\"} + node_memory_SReclaimable_bytes{instance=\"$instance\" ,job=\"${job}\"}",
          "hide": false,
          "instant": false,
          "legendFormat": "RAM Cache + Buffer",
          "range": true,
          "refId": "C"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "node_memory_MemFree_bytes{instance=\"$instance\" ,job=\"${job}\"}",
          "hide": false,
          "instant": false,
          "legendFormat": "RAM Free",
          "range": true,
          "refId": "D"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "(node_memory_SwapTotal_bytes{instance=\"$instance\" ,job=\"${job}\"} - node_memory_SwapFree_bytes{instance=\"$instance\" ,job=\"${job}\"})",
          "hide": false,
          "instant": false,
          "legendFormat": "SWAP Used",
          "range": true,
          "refId": "E"
        }
      ],
      "title": "Memory usage",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "decimals": 4,
          "mappings": [
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "dark-purple"
              },
              {
                "color": "light-purple",
                "value": 1
              },
              {
                "color": "#ff44fb",
                "value": 5
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 12,
        "y": 80
      },
      "id": 150,
      "maxDataPoints": 100,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom",
          "showLegend": false
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_pressure_io_waiting_seconds_total{instance=\"${instance}\",job=\"${job}\"}[$__rate_interval])",
          "instant": false,
          "legendFormat": "__auto",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "IOWait",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "bytes",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "links": [],
          "mappings": [],
          "min": 0,
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "bytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 0,
        "y": 92
      },
      "id": 152,
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "node_memory_Writeback_bytes{instance=\"$instance\" ,job=\"${job}\"}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "Writeback - Memory which is actively being written back to disk",
          "range": true,
          "refId": "A",
          "step": 240
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "node_memory_WritebackTmp_bytes{instance=\"$instance\" ,job=\"${job}\"}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "WritebackTmp - Memory used by FUSE for temporary writeback buffers",
          "range": true,
          "refId": "B",
          "step": 240
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "node_memory_Dirty_bytes{instance=\"$instance\" ,job=\"${job}\"}",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "Dirty - Memory which is waiting to get written back to the disk",
          "range": true,
          "refId": "C",
          "step": 240
        }
      ],
      "title": "Memory Writeback and Dirty",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "Bytes read (-) / write (+)",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "Bps"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byValue",
              "options": {
                "op": "gte",
                "reducer": "allIsZero",
                "value": 0
              }
            },
            "properties": [
              {
                "id": "custom.transform"
              },
              {
                "id": "custom.hideFrom",
                "value": {
                  "legend": true,
                  "tooltip": true,
                  "viz": true
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*Read.*/"
            },
            "properties": [
              {
                "id": "custom.transform",
                "value": "negative-Y"
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 12,
        "y": 92
      },
      "id": 128,
      "options": {
        "legend": {
          "calcs": [
            "lastNotNull",
            "mean",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true,
          "sortBy": "Max",
          "sortDesc": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "irate(node_disk_read_bytes_total{instance=\"$instance\" ,job=\"${job}\"}[$__rate_interval])",
          "legendFormat": "{{device}} - Read bytes",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_disk_written_bytes_total{instance=\"$instance\" ,job=\"${job}\"}[$__rate_interval])",
          "hide": false,
          "instant": false,
          "legendFormat": "{{device}} - Written bytes",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "Disk R/W Data",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "bits out (-) / in (+)",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "links": [],
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "decbits"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*Trans.*/"
            },
            "properties": [
              {
                "id": "custom.transform",
                "value": "negative-Y"
              }
            ]
          },
          {
            "matcher": {
              "id": "byValue",
              "options": {
                "op": "gte",
                "reducer": "allIsZero",
                "value": 0
              }
            },
            "properties": [
              {
                "id": "custom.hideFrom",
                "value": {
                  "legend": true,
                  "tooltip": true,
                  "viz": true
                }
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 0,
        "y": 104
      },
      "id": 111,
      "interval": "1m",
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "lastNotNull",
            "mean",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true,
          "sortBy": "Last *",
          "sortDesc": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_network_receive_bytes_total{instance=\"$instance\" ,job=\"${job}\"}[$__rate_interval])*8",
          "instant": false,
          "legendFormat": "{{device}} - Receive",
          "range": true,
          "refId": "A"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_network_transmit_bytes_total{instance=\"$instance\" ,job=\"${job}\"}[$__rate_interval])*8",
          "hide": false,
          "instant": false,
          "legendFormat": "{{device}} - Transmit",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "Network Usage",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "links": [],
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "percent"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 12,
        "y": 104
      },
      "id": 102,
      "interval": "1",
      "maxPerRow": 4,
      "options": {
        "alertThreshold": true,
        "legend": {
          "calcs": [
            "lastNotNull",
            "mean",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true,
          "sortBy": "Mean",
          "sortDesc": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "exemplar": false,
          "expr": "100 - ((node_filesystem_avail_bytes{instance=\"$instance\",device!~'rootfs' ,job=\"${job}\"} * 100) / node_filesystem_size_bytes{instance=\"$instance\",device!~'rootfs' ,job=\"${job}\"})",
          "instant": false,
          "legendFormat": "{{mountpoint}}",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Disk usage",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": true,
            "axisColorMode": "text",
            "axisLabel": "datagrams out (-) / in (+)",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "line"
            }
          },
          "links": [],
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "short"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*Out.*/"
            },
            "properties": [
              {
                "id": "custom.transform",
                "value": "negative-Y"
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*Snd.*/"
            },
            "properties": [
              {
                "id": "custom.transform",
                "value": "negative-Y"
              },
              {
                "id": "fieldMinMax"
              },
              {
                "id": "custom.lineWidth",
                "value": 1
              }
            ]
          },
          {
            "matcher": {
              "id": "byValue",
              "options": {
                "op": "gte",
                "reducer": "allIsZero",
                "value": 0
              }
            },
            "properties": [
              {
                "id": "custom.hideFrom",
                "value": {
                  "legend": true,
                  "tooltip": true,
                  "viz": true
                }
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 0,
        "y": 116
      },
      "id": 149,
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_netstat_Udp_InDatagrams{instance=\"$instance\",job=\"$job\"}[$__rate_interval])",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "InDatagrams - Datagrams received",
          "range": true,
          "refId": "A",
          "step": 240
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_netstat_Udp_OutDatagrams{instance=\"$instance\",job=\"$job\"}[$__rate_interval])",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "OutDatagrams - Datagrams sent",
          "range": true,
          "refId": "B",
          "step": 240
        }
      ],
      "title": "UDP In / Out",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "description": "",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "time. read (-) / write (+)",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 30,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "links": [],
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "s"
        },
        "overrides": [
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*Read.*/"
            },
            "properties": [
              {
                "id": "custom.transform",
                "value": "negative-Y"
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sda_.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#7EB26D",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdb_.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#EAB839",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdc_.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#6ED0E0",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdd_.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#EF843C",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sde_.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#E24D42",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sda1.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#584477",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sda2_.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#BA43A9",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sda3_.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#F4D598",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdb1.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#0A50A1",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdb2.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#BF1B00",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdb3.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#E0752D",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdc1.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#962D82",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdc2.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#614D93",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdc3.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#9AC48A",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdd1.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#65C5DB",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdd2.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#F9934E",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdd3.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#EA6460",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sde1.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#E0F9D7",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sdd2.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#FCEACA",
                  "mode": "fixed"
                }
              }
            ]
          },
          {
            "matcher": {
              "id": "byRegexp",
              "options": "/.*sde3.*/"
            },
            "properties": [
              {
                "id": "color",
                "value": {
                  "fixedColor": "#F9E2D2",
                  "mode": "fixed"
                }
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 12,
        "y": 116
      },
      "id": 151,
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_disk_read_time_seconds_total{instance=\"$instance\",job=\"${job}\"}[$__rate_interval]) / irate(node_disk_reads_completed_total{instance=\"$instance\" ,job=\"${job}\"}[$__rate_interval])",
          "hide": false,
          "interval": "",
          "intervalFactor": 4,
          "legendFormat": "{{device}} - Read wait time avg",
          "range": true,
          "refId": "A",
          "step": 240
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_disk_write_time_seconds_total{instance=\"$instance\",job=\"${job}\"}[$__rate_interval]) / irate(node_disk_writes_completed_total{instance=\"$instance\",job=\"${job}\"}[$__rate_interval])",
          "hide": false,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "{{device}} - Write wait time avg",
          "range": true,
          "refId": "B",
          "step": 240
        }
      ],
      "title": "Disk Average Wait Time",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 0,
        "y": 128
      },
      "id": 130,
      "options": {
        "legend": {
          "calcs": [
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "single",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "editorMode": "code",
          "expr": "delta(node_network_receive_errs_total{instance=\"$instance\" ,job=\"${job}\"}[1m])",
          "legendFormat": "{{device}} - Receive errors",
          "range": true,
          "refId": "A",
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          }
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "delta(node_network_transmit_errs_total{instance=\"$instance\" ,job=\"${job}\"}[1m])",
          "hide": false,
          "instant": false,
          "legendFormat": "{{device}} - Transmit errors",
          "range": true,
          "refId": "B"
        }
      ],
      "title": "Network Errors [1m]",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "continuous-BlPu"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "datagrams",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 20,
            "gradientMode": "scheme",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "links": [],
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green"
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 12,
        "w": 12,
        "x": 12,
        "y": 128
      },
      "id": 148,
      "options": {
        "legend": {
          "calcs": [
            "mean",
            "lastNotNull",
            "max",
            "min"
          ],
          "displayMode": "table",
          "placement": "bottom",
          "showLegend": true
        },
        "tooltip": {
          "hideZeros": false,
          "mode": "multi",
          "sort": "none"
        }
      },
      "pluginVersion": "11.6.1",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_netstat_Udp_InErrors{instance=\"$instance\",job=\"$job\"}[$__rate_interval])",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "InErrors - UDP Datagrams that could not be delivered to an application",
          "range": true,
          "refId": "A",
          "step": 240
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "irate(node_netstat_Udp_NoPorts{instance=\"$instance\",job=\"$job\"}[$__rate_interval])",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "NoPorts - UDP Datagrams received on a port with no listener",
          "range": true,
          "refId": "B",
          "step": 240
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "expr": "irate(node_netstat_UdpLite_InErrors{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
          "interval": "",
          "legendFormat": "InErrors Lite - UDPLite Datagrams that could not be delivered to an application",
          "refId": "C"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "expr": "irate(node_netstat_Udp_RcvbufErrors{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "RcvbufErrors - UDP buffer errors received",
          "refId": "D",
          "step": 240
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "expr": "irate(node_netstat_Udp_SndbufErrors{instance=\"$node\",job=\"$job\"}[$__rate_interval])",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "SndbufErrors - UDP buffer errors send",
          "refId": "E",
          "step": 240
        }
      ],
      "title": "UDP Errors",
      "type": "timeseries"
    }
  ],
  "refresh": "30s",
  "schemaVersion": 41,
  "tags": [
    "Validator",
    "Solana"
  ],
  "templating": {
    "list": [
      {
        "allowCustomValue": false,
        "current": {},
        "definition": "label_values(job)",
        "label": "Job",
        "name": "job",
        "options": [],
        "query": {
          "qryType": 1,
          "query": "label_values(job)",
          "refId": "PrometheusVariableQueryEditor-VariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "type": "query"
      },
      {
        "allowCustomValue": false,
        "current": {},
        "datasource": {
          "type": "prometheus",
          "uid": "${DS_PROMETHEUS}"
        },
        "definition": "label_values({job=\"$job\"},instance)",
        "includeAll": false,
        "label": "Server",
        "name": "instance",
        "options": [],
        "query": {
          "qryType": 1,
          "query": "label_values({job=\"$job\"},instance)",
          "refId": "PrometheusVariableQueryEditor-VariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "sort": 1,
        "type": "query"
      }
    ]
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Solana Validator",
  "uid": "eel012ifils74b",
  "version": 5,
  "weekStart": ""
}
