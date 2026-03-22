# Go Linting (YOLO)

## Config: golangci-lint v2

Canonical config: `go-skeleton/.golangci.yml`. All projects use the same config.

## Enabled Linters

**Critical:** `govet`, `errcheck`, `staticcheck`, `unused`, `gosec`, `depguard`, `bodyclose`
**Complexity:** `funlen` (80 lines), `gocognit` (20), `nestif` (4 levels), `maintidx` (20 min)
**Style:** `revive`, `errname`, `dupl`, `unparam`, `forcetypeassert`, `asasalint`, `prealloc`, `gocyclo`
**Formatters:** `gofmt`, `goimports` + `golines` (100 char max, separate)

## Complexity Limits

```yaml
funlen:    80 lines / 50 statements
gocognit:  20 complexity max
nestif:    4 nesting levels max
maintidx:  20 maintainability min
```

**Stay under:** Extract helpers at 40+ lines. Early returns. One concern per function.

## Banned Packages (depguard)

```go
// BANNED                              USE INSTEAD
"github.com/pkg/errors"              // github.com/bborbe/errors
"github.com/bborbe/argument"         // github.com/bborbe/argument/v2
"golang.org/x/net/context"           // context (stdlib)
"golang.org/x/lint/golint"           // revive or staticcheck
"io/ioutil"                          // io and os packages
"sigs.k8s.io/structured-merge-diff/v4" // v6
"github.com/containerd/containerd"   // v2
```

## gosec Quick Fixes

```go
// Files: 0600, Dirs: 0750 — ALWAYS
os.WriteFile(path, data, 0600)
os.MkdirAll(dir, 0750)

// Suppress with reason only
// #nosec G304 -- path from internal config, not user input
data, err := os.ReadFile(trustedPath)
```

## errcheck

Every error checked. Explicit ignore with `_ =`:
```go
_ = os.Remove(path)  // cleanup, error irrelevant
```

## Error Naming (errname)

```go
var ErrFoo = errors.New("foo")  // NOT FooError
```

## bodyclose

```go
resp, err := http.Get(url)
if err != nil { return err }
defer resp.Body.Close()
```

## forcetypeassert

```go
val, ok := x.(string)  // NOT val := x.(string)
```

## prealloc

```go
results := make([]Result, 0, len(items))  // NOT var results []Result
```

## slicescontains

```go
slices.Contains(s, v)  // NOT manual loop
```

## Test Exclusions

Relaxed in `_test.go`: `dot-imports` (revive), `dupl`, `unparam`
Still enforced: `funlen`, `errcheck`, `gosec`, `nestif`

## Checklist

- [ ] Functions <80 lines, nesting <4
- [ ] Lines <100 chars
- [ ] No banned packages
- [ ] All errors checked
- [ ] `#nosec` has reason comment
- [ ] Files `0600`, dirs `0750`
- [ ] `defer resp.Body.Close()`
- [ ] Two-value type assertions
- [ ] Slices preallocated
- [ ] `slices.Contains` not manual loops
- [ ] `ErrFoo` not `FooError`
