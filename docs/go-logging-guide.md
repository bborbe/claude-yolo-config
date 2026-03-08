# Go Logging

**New projects:** `log/slog` (stdlib). **Existing with glog:** keep `glog`, don't mix.

## slog (New Projects)

```go
import "log/slog"

slog.Info("service started", "port", port, "dir", watchDir)
slog.Error("process failed", "error", err, "prompt", name)
slog.Warn("high memory", "percent", memPct)
slog.Debug("cache miss", "key", cacheKey)

// With context
slog.InfoContext(ctx, "processing", "file", path)
```

Always use key-value pairs. Never `slog.Info(fmt.Sprintf(...))`.

## glog (Existing Projects)

```go
import "github.com/golang/glog"

glog.Errorf("failed to process user %s: %v", userID, err)
glog.Warningf("deprecated endpoint: %s", endpoint)
glog.Infof("service started on port %d", port)
glog.V(1).Infof("config: addr=%s dir=%s", addr, dir)
glog.V(2).Infof("HTTP %s %s -> %d", method, path, code)
glog.V(3).Infof("internal: %+v", state)
```

## Level Mapping

| Semantic | slog | glog |
|----------|------|------|
| Error | `slog.Error` | `glog.Error` |
| Warning | `slog.Warn` | `glog.Warning` |
| Info | `slog.Info` | `glog.Info` |
| Debug | `slog.Debug` | `glog.V(1-2).Info` |
| Trace | `slog.Debug` | `glog.V(3+).Info` |

## Rules

- **Don't mix** slog and glog in the same project
- **Don't log + return error** — do one or the other
- **Lowercase messages** — `"processing prompt"` not `"Processing prompt"`
- **No sensitive data** — never log tokens, passwords, PII
- **Log at boundaries** — handlers, processors, startup — not deep internals
- **Never** `fmt.Printf` or `log.Println` for logging
