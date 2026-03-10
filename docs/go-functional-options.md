# Functional Options Pattern

Variadic options for optional constructor configuration.

## Core Pattern

```go
// Options struct (plural) — holds config values
type ConsumerOptions struct {
    TargetLag int64
    Delay     libtime.Duration
}

// Option type (singular) — modifies config
type ConsumerOption func(*ConsumerOptions)

// Option functions — With* prefix
func WithTargetLag(lag int64) ConsumerOption {
    return func(opts *ConsumerOptions) { opts.TargetLag = lag }
}

func WithDelay(delay libtime.Duration) ConsumerOption {
    return func(opts *ConsumerOptions) { opts.Delay = delay }
}

// Constructor — required params first, options last
func NewOffsetConsumer(
    client sarama.Client,
    topic Topic,
    handler MessageHandler,
    options ...ConsumerOption,
) Consumer {
    opts := ConsumerOptions{
        TargetLag: 0,    // explicit defaults
        Delay:     0,
    }
    for _, option := range options {
        option(&opts)
    }
    return &offsetConsumer{consumerOptions: opts}
}
```

## Rules

1. **Custom type** for option func: `type XxxOption func(*XxxOptions)` — never inline `func(*Options)`
2. **Singular** for func type: `ConsumerOption` (one option)
3. **Plural** for struct: `ConsumerOptions` (many values)
4. **Exported** options struct — external packages can create options
5. **`With*` prefix** for option functions
6. **Explicit defaults** before applying options
7. **No errors** in option functions — validate and correct silently
8. Pass through layers with `options...`

## Bad

```go
// Inline func type — hard to document
func New(client Client, options ...func(*Options)) {}

// Config struct — requires all fields
func New(client Client, config Config) {}

// Private options struct — external can't create options
type consumerOptions struct {}

// Error return — overcomplicates pattern
func WithTimeout(t time.Duration) func(*Options) error {}
```

## Usage

```go
// Defaults only
consumer := kafka.NewOffsetConsumer(client, topic, handler)

// With options
consumer := kafka.NewOffsetConsumer(client, topic, handler,
    kafka.WithTargetLag(1000),
    kafka.WithDelay(libtime.Duration(5 * time.Second)),
)
```

## Checklist

- [ ] Custom named option type (not inline func)
- [ ] Singular option type, plural options struct
- [ ] Options struct exported
- [ ] With* prefix on all option functions
- [ ] Defaults set before applying options
- [ ] Required params before variadic options
