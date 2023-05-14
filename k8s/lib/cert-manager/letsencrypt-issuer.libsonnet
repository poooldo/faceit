local certManager = import 'github.com/jsonnet-libs/cert-manager-libsonnet/1.3/main.libsonnet';
local clusterIssuer = certManager.nogroup.v1.clusterIssuer;

{
  letsencryptEmail:: 'nicolas@akira.fr',
  letsencryptSolvers:: [
    {
      http01: {
        ingress: {
          class: 'nginx',
        },
      },
    },
  ],

  labels:: {
    'app.kubernetes.io/name': 'cert-manager',
    'app.kubernetes.io/part-of': 'cert-manager',
    name:: null,
  },

  letsencryptIssuer:
    clusterIssuer.new('letsencrypt-prod') +
    clusterIssuer.metadata.withLabels($.labels) +
    clusterIssuer.metadata.withAnnotations({
      'tanka.dev/namespaced': 'false',
    }) +
    clusterIssuer.spec.acme.withEmail($.letsencryptEmail) +
    clusterIssuer.spec.acme.withServer('https://acme-v02.api.letsencrypt.org/directory') +
    clusterIssuer.spec.acme.privateKeySecretRef.withName('letsencrypt-prod-private-key') +
    clusterIssuer.spec.acme.withSolvers($.letsencryptSolvers),
}
