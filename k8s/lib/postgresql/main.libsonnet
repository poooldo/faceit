local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);

{
  version:: '10.4.7',
  _config:: {
    namespace: 'pg',
    values: {
    },
  },

  postgres: helm.template($._config.namespace, './charts/' + $.version, $._config),
}
