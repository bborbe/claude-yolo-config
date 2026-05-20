.PHONY: mac
mac:
	sed -i 's|/home/bborbe|/Users/bborbe|g' mcp*.json

.PHONY: linux
linux:
	sed -i 's|/Users/bborbe|/home/bborbe|g' mcp*.json

.PHONY: update
update:
	@for d in plugins/marketplaces/*/; do \
		if [ ! -e "$$d.git" ]; then \
			echo "=== $$d (skipping — no .git, not a git clone) ==="; \
			continue; \
		fi; \
		echo "=== $$d ==="; \
		dirty=$$(git -C "$$d" status --porcelain); \
		if [ -n "$$dirty" ]; then \
			echo "$$dirty" | sed 's/^/  /'; \
			echo "  (discarding local changes above)"; \
		fi; \
		git -C "$$d" fetch --quiet origin && \
		git -C "$$d" reset --hard '@{u}' --quiet && \
		git -C "$$d" clean -fdq || exit 1; \
	done
