# Prometheus Metrics

Interface-based metrics with proper registration, naming, and push/pull patterns.

## Core Pattern

```go
//counterfeiter:generate -o ../mocks/metrics.go --fake-name Metrics . Metrics
type Metrics interface {
    UserCreated(userType string)
    RequestDuration(endpoint string, duration time.Duration)
}

type metrics struct{}

func NewMetrics() Metrics { return &metrics{} }

func (m *metrics) UserCreated(userType string) {
    userCreatedCounter.With(prometheus.Labels{"type": userType}).Inc()
}

func (m *metrics) RequestDuration(endpoint string, duration time.Duration) {
    requestDurationHistogram.With(prometheus.Labels{"endpoint": endpoint}).Observe(duration.Seconds())
}
```

## Registration

```go
var (
    userCreatedCounter = prometheus.NewCounterVec(prometheus.CounterOpts{
        Namespace: "app",
        Subsystem: "user",
        Name:      "created_total",
        Help:      "Total users created",
    }, []string{"type"})

    requestDurationHistogram = prometheus.NewHistogramVec(prometheus.HistogramOpts{
        Namespace: "app",
        Subsystem: "http",
        Name:      "request_duration_seconds",
        Help:      "HTTP request duration",
        Buckets:   prometheus.DefBuckets,
    }, []string{"endpoint"})
)

func init() {
    prometheus.MustRegister(userCreatedCounter, requestDurationHistogram)
}
```

## Rules

1. **Interface + private impl** — enables mocking with Counterfeiter
2. **Register in `init()`** — metrics registered once at startup
3. **Naming**: `namespace_subsystem_name_unit` (e.g., `app_http_request_duration_seconds`)
4. **Units in name**: `_seconds`, `_bytes`, `_total` (counters always `_total`)
5. **Low cardinality labels** — never user IDs, request IDs, or unbounded values
6. **Metric types**: Counter (monotonic), Gauge (up/down), Histogram (distributions), Summary (quantiles)
7. **Push gateway** for batch jobs: use custom registry for isolation

## Push Gateway (Jobs)

```go
registry := prometheus.NewRegistry()
counter := prometheus.NewCounter(prometheus.CounterOpts{Name: "job_items_total"})
registry.MustRegister(counter)

// After work
push.New("http://pushgateway:9091", "job-name").Gatherer(registry).Push()
```

## Bad

```go
// Public struct — can't mock
type Metrics struct { counter prometheus.Counter }

// High cardinality label
counter.With(prometheus.Labels{"user_id": userID}).Inc()

// Missing unit in name
Name: "request_duration" // should be request_duration_seconds

// Register in function — panics on second call
func NewMetrics() { prometheus.MustRegister(counter) }
```

## Checklist

- [ ] Metrics behind interface with Counterfeiter mock
- [ ] Registered in `init()`, not in constructors
- [ ] Naming follows `namespace_subsystem_name_unit`
- [ ] Labels are low cardinality
- [ ] Counters end with `_total`
- [ ] Durations in seconds, sizes in bytes
