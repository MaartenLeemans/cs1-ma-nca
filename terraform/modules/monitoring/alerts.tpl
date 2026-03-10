groups:
  - name: instance-alerts
    rules:
      - alert: HighCpuUsage
        expr: avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage above 80% for 5 minutes."