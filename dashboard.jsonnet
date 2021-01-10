local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local template = grafana.template;

local namedProcesses = dashboard.new('named processes grafonnet', tags=['grafonnet'], uid='named-processes-grafonnet');
local tpInteval = template.interval(current='10m',name='interval',query='auto,5m,10m,20m');
/* local tpInteval = template.interval(300, '10s', '10m', '', null, 'interval', 'auto,5m,10m,20m'); */
local namedProcessesRet = namedProcesses.addTemplate(tpInteval)
.addTemplate(
    template.new(multi=true,includeAll=true,allValues='.+',current='all',refresh=1,name='processes',datasource='prometheus',query='label_values(namedprocess_namegroup_cpu_seconds_total,groupname)')
);

{
  grafanaDashboards:: {
    named_processes_grafonnet: namedProcessesRet
  }
}
