local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local template = grafana.template;
local table = grafana.tablePanel;

local namedProcesses = dashboard.new('named processes grafonnet', tags=['grafonnet'], uid='named-processes-grafonnet');
local processMemoryDashboard = dashboard.new('process exporter dashboard with treemap', tags=['process'], uid='process-exporter-with-tree', editable=true);

local instanceTemplate = template.new(multi=false,refresh=1,name='instance',datasource='$PROMETHEUS_DS',query='label_values(namedprocess_namegroup_cpu_seconds_total,instance)');


/* local tpInteval = template.interval(current='10m',name='interval',query='auto,1m,5m,10m,30m,1h'); */

local resourcePanel(title="",expr="", format="short", stack=true) =
  graphPanel.new(
    title=title,
    datasource='$PROMETHEUS_DS',
    format=format,
    stack=stack
  ).addTarget(
    prometheus.target(
      expr=expr,
      legendFormat='{{groupname}}',
  )
) + {
  "tooltip": {
    "shared": true,
    "sort": 2,
    "value_type": "individual"
  }
};

local tablePanel(title="",expr="") =
{
  "type": "table",
  "title": title,
  "targets": [
    {
      "expr": expr,
      "legendFormat": "{{groupname}}",
      "interval": "",
      "exemplar": true,
      "instant": true,
      "format": "table"
    }
  ],
  "options": {
    "showHeader": true,
    "sortBy": [
      {
        "displayName": "uptime",
        "desc": true
      }
    ],
    "frameIndex": 0
  },
  "fieldConfig": {
    "defaults": {
      "unit": "s"
    }
  },
  "transformations": [
    {
      "id": "renameByRegex",
      "options": {
        "regex": "Value.*",
        "renamePattern": "uptime"
      }
    }
  ],
  "datasource": null
}
  ;

local gridPos={'x':0, 'y':0, 'w':12, 'h': 10};
local gridPosHalf={'x':0, 'y':0, 'w':6, 'h': 5};

local baseHight = 10;
local baseWidth = 8;
local baseWidthWide = 12;
local basePos = {"h":baseHight,"w":baseWidth,"x":0,"y":0};


local namedProcessesRet = namedProcesses
.addTemplate(
    template.new(multi=true,includeAll=true,allValues='.+',current='all',refresh=1,name='processes',datasource='$PROMETHEUS_DS',query='label_values(namedprocess_namegroup_cpu_seconds_total,groupname)')
)
.addTemplate(
    instanceTemplate
)
.addRow(grafana.row.new(repeat="instance", title="$instance")
.addPanel(
    grafana.pieChartPanel.new(title="num processes(topk)",datasource='prometheus',legendType='On graph').addTarget(
        prometheus.target(
          expr='topk(5, namedprocess_namegroup_num_procs{instance=~"$instance",groupname=~"$processes"})',
          legendFormat='{{groupname}}'
        )
    )
)
.addPanel(
    grafana.pieChartPanel.new(title="cpu(topk)",datasource='prometheus',legendType='On graph').addTarget(
        prometheus.target(
          expr='topk(5, sum (rate(namedprocess_namegroup_cpu_seconds_total{instance=~"$instance",groupname=~"$processes"}[$__rate_interval]) )without (mode))',
          legendFormat='{{groupname}}'
        )
    )
)
.addPanel(
    grafana.pieChartPanel.new(title="resident memory(topk)",datasource='prometheus',legendType='On graph').addTarget(
        prometheus.target(
          expr='topk(5, namedprocess_namegroup_memory_bytes{instance=~"$instance",groupname=~"$processes", memtype="resident"} > 0)',
          legendFormat='{{groupname}}'
        )
    )
)
.addPanel(
    resourcePanel(title="num processes",expr='namedprocess_namegroup_num_procs{instance=~"$instance",groupname=~"$processes"}'),
    gridPos
).addPanel(
    resourcePanel(title="cpu",expr='sum (rate(namedprocess_namegroup_cpu_seconds_total{instance=~"$instance",groupname=~"$processes"}[$__rate_interval]) )without (mode)'),
    gridPos + {'x': gridPos.w}
).addPanel(
    resourcePanel(title="resident memory",expr='namedprocess_namegroup_memory_bytes{instance=~"$instance",groupname=~"$processes", memtype="resident"} > 0'),
    gridPos
).addPanel(
    resourcePanel(title="virtual memory",expr='namedprocess_namegroup_memory_bytes{instance=~"$instance",groupname=~"$processes", memtype="virtual"}'),
    gridPos + {'x': gridPos.w}
).addPanel(
    resourcePanel(title="read byte",expr='rate(namedprocess_namegroup_read_bytes_total{instance=~"$instance",groupname=~"$processes"}[$__rate_interval])'),
    gridPosHalf + {'x': gridPos.w + gridPosHalf.w}
).addPanel(
    resourcePanel(title="write byte",expr='rate(namedprocess_namegroup_write_bytes_total{instance=~"$instance",groupname=~"$processes"}[$__rate_interval])'),
    gridPos + {'x': gridPos.w}
));

local treePanel(expr="", title="",format="short", pos={"h":0,"w":0,"x":0,"y":0}) = {
      "datasource": "$PROMETHEUS_DS",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "unit": format,
          "color": {
            "mode": "continuous-RdYlGr"
          }
        },
        "overrides": []
      },
      "gridPos": pos,
      "options": {
        "colorByField": "Value",
        "colorField": "groupname",
        "sizeField": "Value",
        "textField": "groupname",
        "tiling": "treemapSquarify"
      },
      "targets": [
        {
          "expr": expr,
          "format": "table",
          "instant": true,
          "interval": "",
          "legendFormat": "{{groupname}}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": title,
      "transformations": [],
      "transparent": false,
      "type": "marcusolsson-treemap-panel"
  };

local processMemoryDashboardRet = processMemoryDashboard
.addTemplate(
  grafana.template.datasource(
    'PROMETHEUS_DS',
    'prometheus',
    'Prometheus',
    hide='label',
  )
)
.addTemplate(instanceTemplate)
.addRequired('datasource', 'Prometheus', 'prometheus', '1.0.0')
.addRequired('panel', 'Treemap', 'marcusolsson-treemap-panel', '0.5.0')
.addPanels([
    treePanel(expr='sum(namedprocess_namegroup_memory_bytes{instance=~"$instance", memtype="proportionalResident"} > 0) by (groupname)', title="proportional resident memory map", format="bytes", pos=basePos + {"w": baseWidthWide}),
    treePanel(expr='sum(rate(namedprocess_namegroup_cpu_seconds_total{instance=~"$instance"}[$__rate_interval] ))  by (groupname)', title="cpu map", format="s", pos=basePos + {"x": baseWidthWide, "w": baseWidthWide})
])
.addPanel(
    resourcePanel(title="proportional resident memory",expr='namedprocess_namegroup_memory_bytes{instance=~"$instance", memtype="proportionalResident"} > 0', format="bytes"),
    basePos + {"y": baseHight * 1, "w": baseWidthWide, "x":baseWidthWide * 0}
).addPanel(
    resourcePanel(title="cpu",expr='sum (rate(namedprocess_namegroup_cpu_seconds_total{instance=~"$instance"}[$__rate_interval]) )without (mode) > 0', format="s"),
    basePos + {"y": baseHight * 1, "w": baseWidthWide, "x":baseWidthWide * 1}
).addPanel(
    resourcePanel(title="resident memory (average)",expr='namedprocess_namegroup_memory_bytes{instance=~"$instance", memtype="resident"} / ignoring(memtype) namedprocess_namegroup_num_procs > 0', format="bytes", stack=false),
    basePos + {"y": baseHight * 2, "w": baseWidth, "x":baseWidth * 0}
).addPanel(
    resourcePanel(title="num processes",expr='namedprocess_namegroup_num_procs{instance=~"$instance"}'),
    basePos + {"y": baseHight * 2, "w": baseWidth, "x": baseWidth * 1}
).addPanel(
    resourcePanel(title="virtual memory",expr='namedprocess_namegroup_memory_bytes{instance=~"$instance", memtype="virtual"}', format="bytes"),
    basePos + {"y": baseHight * 2, "w": baseWidth, "x": baseWidth * 2}
).addPanel(
    resourcePanel(title="read byte",expr='rate(namedprocess_namegroup_read_bytes_total{instance=~"$instance"}[$__rate_interval])', format="Bps", stack=false),
    basePos + {"y": baseHight * 3, "w": baseWidthWide, "x": baseWidthWide * 0}
).addPanel(
    resourcePanel(title="write byte",expr='rate(namedprocess_namegroup_write_bytes_total{instance=~"$instance"}[$__rate_interval])', format="Bps", stack=false),
    basePos + {"y": baseHight * 3, "w": baseWidthWide, "x": baseWidthWide * 1}
).addPanel(
    resourcePanel(title="voluntary context switch",expr='rate(namedprocess_namegroup_context_switches_total{instance=~"$instance", ctxswitchtype="voluntary"}[$__rate_interval])'),
    basePos + {"y": baseHight * 4, "w": baseWidth, "x": 0}
).addPanel(
    resourcePanel(title="nonvoluntary context switch",expr='rate(namedprocess_namegroup_context_switches_total{instance=~"$instance", ctxswitchtype="nonvoluntary"}[$__rate_interval])'),
    basePos + {"y": baseHight * 4, "w": baseWidth, "x": baseWidth * 1}
).addPanel(
    resourcePanel(title="open file desc",expr='namedprocess_namegroup_open_filedesc{instance=~"$instance"}'),
    basePos + {"y": baseHight * 4, "w": baseWidth, "x": baseWidth * 2}
).addPanel(
    resourcePanel(title="major page faults",expr='rate(namedprocess_namegroup_major_page_faults_total{instance=~"$instance"}[$__rate_interval])', format="short", stack=false),
    basePos + {"y": baseHight * 5, "w": baseWidthWide, "x": baseWidthWide * 0}
).addPanel(
    resourcePanel(title="minor page faults",expr='rate(namedprocess_namegroup_minor_page_faults_total{instance=~"$instance"}[$__rate_interval])', format="short", stack=false),
    basePos + {"y": baseHight * 5, "w": baseWidthWide, "x": baseWidthWide * 1}
).addPanel(
    tablePanel(title="uptime", expr='time() - (avg by (groupname) (namedprocess_namegroup_oldest_start_time_seconds{instance=~"$instance"} > 0))'),
    basePos + {"y": baseHight * 6, "w": 24, "x": baseWidthWide * 0}
)
;

{
  grafanaDashboards:: {
    named_processes_grafonnet: namedProcessesRet,
    process_exporter_with_tree: processMemoryDashboardRet
  }
}
