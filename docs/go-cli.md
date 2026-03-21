# Go CLI Applications

## Flag Parsing: cobra + slog

**NEVER use stdlib `flag` package** — transitive dependencies like `github.com/golang/glog` register flags via `init()`, polluting `--help` output with unwanted flags (`-alsologtostderr`, `-log_dir`, `-v`, etc.).

**Always use `github.com/spf13/cobra`** for CLI flag parsing, even for single-command binaries.

### Single-command binary pattern

```go
// main.go
package main

import "github.com/bborbe/my-tool/pkg/cli"

func main() {
	cli.Execute()
}
```

```go
// pkg/cli/cli.go
package cli

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/spf13/cobra"
)

func Execute() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGTERM, syscall.SIGINT)
	go func() {
		<-sigCh
		cancel()
	}()

	if err := Run(ctx, os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func Run(ctx context.Context, args []string) error {
	var configPath string
	var verbose bool

	rootCmd := &cobra.Command{
		Use:          "my-tool",
		Short:        "One-line description",
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			// setup logging
			level := slog.LevelWarn
			if verbose {
				level = slog.LevelDebug
			}
			slog.SetDefault(slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: level})))

			// load config, build deps, run...
			return nil
		},
	}

	rootCmd.Flags().StringVar(&configPath, "config", "", "Path to config YAML file")
	rootCmd.Flags().BoolVar(&verbose, "verbose", false, "Enable verbose logging")
	_ = rootCmd.MarkFlagRequired("config")

	rootCmd.SetArgs(args)
	return rootCmd.ExecuteContext(ctx)
}
```

### Key rules

- `context.Background()` created exactly once in `Execute()`
- Signal handling in `Execute()`, not in `RunE`
- `SilenceUsage: true` — cobra doesn't print usage on errors
- `MarkFlagRequired` for mandatory flags — cobra handles missing flag errors
- Logging: `log/slog` to stderr, never glog
- `Run(ctx, args)` is testable (accepts args, returns error)

### Logging

Use `log/slog` (stdlib Go 1.21+). Never use `github.com/golang/glog` in new projects — it pollutes the global `flag` namespace.
