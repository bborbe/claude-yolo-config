.PHONY: update

update:
	@for d in plugins/marketplaces/*/; do \
		echo "=== $$d ==="; \
		git -C "$$d" pull --ff-only || exit 1; \
	done
