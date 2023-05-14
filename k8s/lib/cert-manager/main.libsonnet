local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);

local k = import 'k.libsonnet';
local namespace = k.core.v1.namespace;

{
  version:: '1.7.2',
  _config:: {
    namespace: 'cert-manager',
    values: {
      installCRDs: true,
      },
    },

  namespace: namespace.new($._config.namespace),

  certManager: helm.template($._config.namespace, './charts/' + $.version, $._config),

}
+ (import 'letsencrypt-issuer.libsonnet')
