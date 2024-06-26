local utils = import 'mixin-utils/utils.libsonnet';
local filename = 'mimir-scaling.json';

(import 'dashboard-utils.libsonnet') {
  [filename]:
    assert std.md5(filename) == '64bbad83507b7289b514725658e10352' : 'UID of the dashboard has changed, please update references to dashboard.';
    ($.dashboard('Scaling') + { uid: std.md5(filename) })
    .addClusterSelectorTemplates()
    .addRow(
      ($.row('Service scaling') + { height: '200px' })
      .addPanel({
        type: 'text',
        title: '',
        options: {
          content: |||
            This dashboard identifies scaling-related issues by suggesting services that you might want to scale up.
            The table that follows contains a suggested number of replicas and the reason why.
            If the system is failing and depending on the reason, try scaling up to the specified number.
            The specified numbers are intended as helpful guidelines when things go wrong, rather than prescriptive guidelines.

            Reasons:
            - **sample_rate**: There are not enough replicas to handle the
              sample rate.  Applies to distributor and ingesters.
            - **active_series**: There are not enough replicas
              to handle the number of active series.  Applies to ingesters.
            - **cpu_usage**: There are not enough replicas
              based on the CPU usage of the jobs vs the resource requests.
              Applies to all jobs.
            - **memory_usage**: There are not enough replicas based on the memory
              usage vs the resource requests.  Applies to all jobs.
            - **active_series_limits**: There are not enough replicas to hold 60% of the
              sum of all the per tenant series limits.
            - **sample_rate_limits**: There are not enough replicas to handle 60% of the
              sum of all the per tenant rate limits.
          |||,
          mode: 'markdown',
        },
      })
    )
    .addRow(
      ($.row('Scaling') + { height: '400px' })
      .addPanel(
        $.panel('Workload-based scaling') + { sort: { col: 0, desc: false } } +
        $.tablePanel([
          |||
            sort_desc(
              %s_deployment_reason:required_replicas:count{%s}
                > ignoring(reason) group_left
              %s_deployment:actual_replicas:count{%s}
            )
          ||| % [$._config.alert_aggregation_rule_prefix, $.namespaceMatcher(), $._config.alert_aggregation_rule_prefix, $.namespaceMatcher()],
        ], {
          __name__: { type: 'hidden' },
          cluster: { alias: 'Cluster' },
          namespace: { alias: 'Namespace' },
          deployment: { alias: 'Service' },
          reason: { alias: 'Reason' },
          Value: { alias: 'Required Replicas', decimals: 0 },
        })
      )
    ),
}
