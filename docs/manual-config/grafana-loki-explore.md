# Grafana Loki Explore App - Manual Configuration

## Why Manual Configuration is Needed

The Grafana Loki Explore app (now called "Grafana Logs Drilldown") cannot have its default datasource configured
declaratively via NixOS. The app may default to the Prometheus datasource (marked as `isDefault = true`) instead of
Loki, causing 404 errors when accessing log volume endpoints.

## When to Perform Setup

After deploying Grafana with the Loki datasource provisioned, or when you see 404 errors accessing:

```text
/api/datasources/uid/prometheus/resources/index/volume
```

## Symptoms

- 404 errors in Grafana logs when using Loki Explore
- URL parameter `var-ds=` is empty in the explore URL
- Drilldown features (volume histogram, detected fields/labels) not working

## Configuration Steps

### Option 1: Select Loki Datasource in Explore UI

1. Navigate to Grafana Loki Explore: `http://your-grafana:3000/a/grafana-lokiexplore-app/explore`
2. Look for datasource selector dropdown (usually top-left or in settings)
3. Select "Loki" datasource from dropdown
4. Verify URL now shows: `var-ds=loki` or `var-ds={loki-uid}`
5. Test log volume features (histogram should appear)

### Option 2: Access via Standard Explore (Recommended)

1. Navigate to standard Grafana Explore: `http://your-grafana:3000/explore`
2. Select "Loki" from datasource dropdown
3. Run a log query (e.g., `{job="systemd"}`)
4. Click "Logs" volume histogram to access drilldown features
5. Bookmark this URL for future use

## Verification Steps

1. Run log query in Loki Explore
2. Check for log volume histogram (should show bars)
3. Check for detected fields/labels panels
4. Verify no 404 errors in browser console or Grafana logs
5. Confirm service names are detected (not "unknown_service")

## Troubleshooting

### Still Getting 404 Errors

- Check Loki service is running: `systemctl status loki`
- Verify Loki config has `volume_enabled: true` and `discover_log_levels: true`
- Check Loki logs for errors: `journalctl -u loki -f`
- Test Loki API directly: `curl http://localhost:3100/loki/api/v1/labels`

### "Unknown_service" Displayed

- Verify logs have `job` or `service` label in Promtail config
- Check Loki discovered service names: Look for `service_name` in log labels
- Ensure `discover_service_name` uses labels that exist in your logs

### No Log Volume Histogram

- Verify `volume_enabled: true` in Loki `limits_config`
- Loki version 3.1+ has this enabled by default
- Check Loki API: `curl http://localhost:3100/loki/api/v1/index/volume?query={job="systemd"}&start=...&end=...`

## Related Documentation

- [Grafana Logs Drilldown Troubleshooting](https://grafana.com/docs/grafana/latest/explore/simplified-exploration/logs/troubleshooting/)
- [Loki Volume API](https://grafana.com/docs/loki/latest/reference/loki-http-api/#query-log-volume)
- [Configure Loki Data Source](https://grafana.com/docs/grafana/latest/datasources/loki/)

## Alternative: Disable Loki Explore App

If you prefer standard Grafana Explore:

1. Navigate to Configuration → Plugins
2. Find "Grafana Logs Drilldown" (grafana-lokiexplore-app)
3. Disable the plugin
4. Use standard Explore with Loki datasource instead

This avoids datasource selection issues but loses specialized drilldown UI features.
