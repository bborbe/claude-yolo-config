# Go Functional Composition Pattern

Turn any interface into composable functions and lists.

## Three Components

```go
// 1. Interface (single method preferred)
type Processor interface {
    Process(ctx context.Context, input Input) error
}

// 2. Function type — implements the interface directly
type ProcessorFunc func(ctx context.Context, input Input) error

func (f ProcessorFunc) Process(ctx context.Context, input Input) error {
    return f(ctx, input)
}

// 3. List type — runs all members sequentially
type ProcessorList []Processor

func (list ProcessorList) Process(ctx context.Context, input Input) error {
    for _, p := range list {
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
        }
        if err := p.Process(ctx, input); err != nil {
            return errors.Wrapf(ctx, err, "process failed")
        }
    }
    return nil
}
```

## Usage in Factory

```go
// Factory composes list
func CreateProcessor(db DB) Processor {
    return ProcessorList{
        NewValidator(db),
        NewTransformer(),
        NewPersister(db),
    }
}

// Constructor returns functional impl
func NewValidator(db DB) Processor {
    return ProcessorFunc(func(ctx context.Context, input Input) error {
        return db.Validate(ctx, input)
    })
}
```

## When to Use

- Single-method interfaces → use `XxxFunc` + `XxxList`
- Multi-method interfaces → use struct with function fields
- Prefer over struct when no mutable state needed
