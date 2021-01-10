local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local template = grafana.template;

local namedProcesses = dashboard.new('named processes grafonnet', tags=['grafonnet'], uid='named-processes-grafonnet');
local tpInteval = template.interval(current='10m',name='interval',query='auto,1m,5m,10m,30m,1h');
/* local tpInteval = template.interval(300, '10s', '10m', '', null, 'interval', 'auto,5m,10m,20m'); */


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


local namedProcessesRet = namedProcesses.addTemplate(tpInteval)
.addTemplate(
    template.new(multi=true,includeAll=true,allValues='.+',current='all',refresh=1,name='processes',datasource='prometheus',query='label_values(namedprocess_namegroup_cpu_seconds_total,groupname)')
).addPanel(
    resourcePanel(title="num processes",expr="namedprocess_namegroup_num_procs{groupname=~\"$processes\"}"),
    gridPos
).addPanel(
    resourcePanel(title="cpu",expr="sum (rate(namedprocess_namegroup_cpu_seconds_total{groupname=~\"$processes\"}[$interval]) )without (mode)"),
    gridPos + {'x': gridPos.w}
).addPanel(
    resourcePanel(title="resident memory",expr='namedprocess_namegroup_memory_bytes{groupname=~"$processes", memtype="resident"} > 0'),
    gridPos
).addPanel(
    resourcePanel(title="virtual memory",expr='namedprocess_namegroup_memory_bytes{groupname=~"$processes", memtype="virtual"}'),
    gridPos + {'x': gridPos.w}
).addPanel(
    resourcePanel(title="read byte",expr='rate(namedprocess_namegroup_read_bytes_total{groupname=~"$processes"}[$interval])'),
    gridPos
).addPanel(
    resourcePanel(title="write byte",expr='rate(namedprocess_namegroup_write_bytes_total{groupname=~"$processes"}[$interval])'),
    gridPos + {'x': gridPos.w}
)

;

{
  grafanaDashboards:: {
    named_processes_grafonnet: namedProcessesRet
  }
}
