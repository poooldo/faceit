local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);

local k = import 'k.libsonnet';
local configMap = k.core.v1.configMap;
local namespace = k.core.v1.namespace;
local topologySpreadConstraint = k.core.v1.topologySpreadConstraint;

{
  version:: '4.5.2',
  _config:: {
    namespace: 'ingress-nginx',
    kubeVersion: error 'kubeVersion is required',
    values: {
      controller+: {
        ingressClass: 'nginx',
        config: {
          'hide-headers': 'Server',
          'server-tokens': 'false',
        },
        replicaCount: 2,
        topologySpreadConstraints: [
          topologySpreadConstraint.withMaxSkew(1) +
          topologySpreadConstraint.withTopologyKey('topology.kubernetes.io/zone') +
          topologySpreadConstraint.withWhenUnsatisfiable('DoNotSchedule') +
          topologySpreadConstraint.labelSelector.withMatchLabels({
            'app.kubernetes.io/name': 'ingress-nginx',
            'app.kubernetes.io/instance': 'ingress-nginx',
            'app.kubernetes.io/component': 'controller',
          }),
          topologySpreadConstraint.withMaxSkew(1) +
          topologySpreadConstraint.withTopologyKey('kubernetes.io/hostname') +
          topologySpreadConstraint.withWhenUnsatisfiable('DoNotSchedule') +
          topologySpreadConstraint.labelSelector.withMatchLabels({
            'app.kubernetes.io/name': 'ingress-nginx',
            'app.kubernetes.io/instance': 'ingress-nginx',
            'app.kubernetes.io/component': 'controller',
          }),
        ],
        service+: {
          externalTrafficPolicy: 'Local',  // preserve source IPs, needed for whitelist
          type: 'LoadBalancer',
        },
      },
    },
  },


  namespace:
    namespace.new($._config.namespace),

  local ingress = helm.template($._config.namespace, './charts/' + $.version, $._config),

  ingress: ingress {
    // IngressClass is cluster wide
    [if std.objectHas(ingress, 'ingress_class_nginx') then 'ingress_class_nginx']+: {
      metadata+: {
        annotations+: {
          'tanka.dev/namespaced': 'false',
        },
      },
    },
  },

}
