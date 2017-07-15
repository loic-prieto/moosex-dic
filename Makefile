PERL_VERSION := 5.24

PHONY += build-docker
build-docker:
	docker build -t perl_carton:$(PERL_VERSION) .

PHONY += fetch-dependencies
fetch-dependencies:
	docker run --rm -ti -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) carton install

PHONY += unit-test
unit-test:
	docker run --rm -ti -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) prove t/unit

# Log into the perl environment to test manually the library
PHONY += manual-test
manual-test:
	docker run --rm -ti -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) /bin/bash

tidy-codebase:
	@echo "Tidying lib files"
	docker run --rm -ti -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) find lib -type f -name *.pm -exec perltidy -b -bext='/' {} \;
	@echo "Tidying test files"
	docker run --rm -ti -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) find lib -type f -name *.t -exec perltidy -b -bext='/' {} \;
	@echo "Codebase tidied"

PHONY: $(PHONY)
