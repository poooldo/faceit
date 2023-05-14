local k = import 'k.libsonnet';
local namespace = k.core.v1.namespace;

{
  namespace+:
    namespace.metadata.withAnnotationsMixin({
      'scheduler.alpha.kubernetes.io/defaultTolerations': '[{"operator": "Exists", "effect": "NoSchedule", "key": "kubernetes.azure.com/scalesetpriority"}]',
    }),

  local webhooks = super.certManager.validating_webhook_configuration_cert_manager_webhook.webhooks,

  // This is a mixin which adds a namespaceSelector to exclude control-plane namespaces.
  // Ref: https://docs.microsoft.com/en-us/azure/aks/faq#can-i-use-admission-controller-webhooks-on-aks
  // This selector gets added automatically by AKS after applying, by using this mixin, we can prevent a diff.
  certManager+: {
    validating_webhook_configuration_cert_manager_webhook+: {
      webhooks: std.map(function(x) x {
        namespaceSelector+: {
          matchExpressions+: [{
            key: 'control-plane',
            operator: 'DoesNotExist',
          }],
        },
      }, webhooks),
    },
  },
}
