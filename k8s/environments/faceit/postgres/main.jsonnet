local postgres = import 'postgresql/main.libsonnet';

postgres {
  _config+:: {
    values+: {
      existingSecret: 'postgresql-admin',
      postgresqlDatabase: 'faceit',
    },
  },
} + {
  secret: import 'secret.json',
}
