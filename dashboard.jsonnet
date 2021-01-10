local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local template = grafana.template;

local namedProcesses = dashboard.new('named processes grafonnet', tags=['grafonnet']);
namedProcesses.addTemplate(template.interval(query='auto,5m,10m,20m'))


{
  grafanaDashboards:: {
    named_processes_grafonnet: namedProcesses
  }
}
