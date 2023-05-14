local k = import 'k.libsonnet';

local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local deployment = k.apps.v1.deployment;
local envVar = k.core.v1.envVar;
local httpIngressPath = k.networking.v1.httpIngressPath;
local ingress = k.networking.v1.ingress;
local ingressRule = k.networking.v1.ingressRule;
local ingressTLS = k.networking.v1.ingressTLS;
local pdb = k.policy.v1.podDisruptionBudget;
local service = k.core.v1.service;
local topologySpreadConstraint = k.core.v1.topologySpreadConstraint;

local name = 'app';

{
  _config:: {
    namespace: name,
    version: 'latest',
    hostname: 'app.faceit.akira.fr',
    env: {
      port: '8080',
      pg_host: 'pg-postgresql.pg.svc',
      pg_port: '5432',
      pg_user: 'postgres',
      pg_dbname: 'postgres',
    },
    existingSecret: {
      name: 'postgresql-admin',
      key: 'postgresql-password',
    },
    replicas: 2,
  },

  labels:: {
    'app.kubernetes.io/name': name,
    name:: null,
  },

  secret: import 'secret.json',

  container::
    container.new(name, 'nalabrun/faceit:' + $._config.version) +
    container.withImagePullPolicy('Always') +
    container.withPorts([
      containerPort.newNamed(8080, 'http') + containerPort.withProtocol('TCP'),
    ]) +
    container.withEnv([
      envVar.new('PORT', $._config.env.port),
      envVar.new('POSTGRESQL_HOST', $._config.env.pg_host),
      envVar.new('POSTGRESQL_PORT', $._config.env.pg_port),
      envVar.new('POSTGRESQL_USER', $._config.env.pg_user),
      envVar.fromSecretRef('POSTGRESQL_PASSWORD', $._config.existingSecret.name, $._config.existingSecret.key),
      envVar.new('POSTGRESQL_DBNAME', $._config.env.pg_dbname),
    ]),
  
  deployment:
    deployment.new(name, $._config.replicas, [$.container], $.labels) +
    deployment.metadata.withNamespace($._config.namespace) +
    deployment.metadata.withLabels($.labels),

  pdb:
    pdb.new(name) +
    pdb.metadata.withNamespace($._config.namespace) +
    pdb.metadata.withLabels($.labels) +
    pdb.spec.withMinAvailable(1) +
    pdb.spec.selector.withMatchLabels($.labels),

  service:
    service.new(name, $.labels, [{ name: 'http', port: 8080, protocol: 'TCP' }]) +
    service.metadata.withLabels($.labels) +
    service.metadata.withNamespace($._config.namespace),

  ingresses:
        ingress.new(name) +
        ingress.metadata.withNamespace($._config.namespace) +
        ingress.metadata.withLabels($.labels) +
        ingress.metadata.withAnnotations({
          'cert-manager.io/cluster-issuer': 'letsencrypt-prod',
          'kubernetes.io/ingress.class': 'nginx',
        }) +
        ingress.spec.withRules(
          [
            ingressRule.withHost($._config.hostname) +
            ingressRule.http.withPaths([
              httpIngressPath.withPath('/') +
              httpIngressPath.withPathType('ImplementationSpecific') +
              httpIngressPath.backend.service.withName($.service.metadata.name) +
              httpIngressPath.backend.service.port.withName('http'),
            ])
          ]
        ) +
        ingress.spec.withTls(
          ingressTLS.withHosts($._config.hostname) +
          ingressTLS.withSecretName('tls-%s' % name)
        )
}
