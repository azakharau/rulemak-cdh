.PHONY: validate install uninstall dmg

validate:
	./scripts/validate.sh

dmg:
	./scripts/build-dmg.sh

install:
	./scripts/install.sh

uninstall:
	./scripts/uninstall.sh
