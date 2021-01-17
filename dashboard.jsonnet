local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local template = grafana.template;

local namedProcesses = dashboard.new('named processes grafonnet', tags=['grafonnet'], uid='named-processes-grafonnet');
local processMemoryDashboard = dashboard.new('process memory dashboard grafonnet', tags=['grafonnet'], uid='process-memory-grafonnet');

local instanceTemplate = template.new(hide=true,multi=true,includeAll=true,allValues='.+',current='all',refresh=1,name='instance',datasource='prometheus',query='label_values(namedprocess_namegroup_cpu_seconds_total,instance)');


/* local tpInteval = template.interval(current='10m',name='interval',query='auto,1m,5m,10m,30m,1h'); */

local resourcePanel(title="",expr="") =
  graphPanel.new(
    title=title,
    datasource='prometheus',
  ).addTarget(
    prometheus.target(
      expr=expr,
      legendFormat='{{groupname}}',
    )
  );

local gridPos={'x':0, 'y':0, 'w':12, 'h': 10};
local gridPosHalf={'x':0, 'y':0, 'w':6, 'h': 5};

local namedProcessesRet = namedProcesses
.addTemplate(
    template.new(multi=true,includeAll=true,allValues='.+',current='all',refresh=1,name='processes',datasource='prometheus',query='label_values(namedprocess_namegroup_cpu_seconds_total,groupname)')
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
    gridPosHalf + {'x': gridPos.w}
).addPanel(
    resourcePanel(title="read byte",expr='rate(namedprocess_namegroup_read_bytes_total{instance=~"$instance",groupname=~"$processes"}[$__rate_interval])'),
    gridPosHalf + {'x': gridPos.w + gridPosHalf.w}
).addPanel(
    resourcePanel(title="write byte",expr='rate(namedprocess_namegroup_write_bytes_total{instance=~"$instance",groupname=~"$processes"}[$__rate_interval])'),
    gridPosHalf + {'x': gridPos.w}
));

local treePanel = {
      "datasource": "prometheus",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "unit": "bytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 15,
        "w": 24,
        "x": 0,
        "y": 1
      },
      "options": {
        "colorField": "groupname",
        "sizeField": "Value",
        "textField": "groupname",
        "tiling": "treemapSquarify"
      },
      "pluginVersion": "7.2.0",
      "targets": [
        {
          "expr": "sum(namedprocess_namegroup_memory_bytes{instance=~\"$instance\",groupname=~\".+\", memtype=\"resident\"} > 0) by (groupname)",
          "format": "table",
          "instant": true,
          "interval": "",
          "legendFormat": "{{groupname}}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "process resident memory map",
      "transformations": [],
      "transparent": true,
      "type": "marcusolsson-treemap-panel"
  };

local processMemoryDashboardRet = processMemoryDashboard
.addTemplate(instanceTemplate)
.addRow(grafana.row.new(repeat="instance", title="$instance"))
.addPanels([treePanel])
;

{
  grafanaDashboards:: {
    named_processes_grafonnet: namedProcessesRet,
    process_memory_grafonnet: processMemoryDashboardRet
  }
}
