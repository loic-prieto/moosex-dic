PERL_VERSION := 5.24
UID := `id -u`
GID := `id -g`
USER_IDENTIFIER := "$(UID):$(GID)"

PHONY += build-docker
build-docker:
	docker build -t perl_carton:$(PERL_VERSION) .

README.md:
	docker run --rm -ti -u $(USER_IDENTIFIER) -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) carton exec perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/MooseX/DIC.pm > README.md

PHONY += fetch-dependencies
fetch-dependencies:
	docker run --rm -ti -u $(USER_IDENTIFIER) -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -e "HOME=/mnt/moosex-dic" -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) carton install

PHONY += unit-test
unit-test:
	docker run --rm -ti -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) prove t/unit

# Log into the perl environment to test manually the library
PHONY += manual-test
manual-test:
	docker run --rm -ti -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) /bin/bash

tidy-codebase:
	@echo "Tidying lib files"
	@docker run --rm -ti -u $(USER_IDENTIFIER) -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) find lib -type f -name *.pm -exec perltidy -b -bext='/' {} \;
	@echo "Tidying test files"
	@docker run --rm -ti -u $(USER_IDENTIFIER) -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) find lib -type f -name *.t -exec perltidy -b -bext='/' {} \;
	@echo "Codebase tidied"

dist: README.md
	docker run --rm -ti -u $(USER_IDENTIFIER) -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) carton exec dzil smoke
	docker run --rm -ti -u $(USER_IDENTIFIER) -v $(CURDIR):/mnt/moosex-dic perl_carton:$(PERL_VERSION) carton exec dzil build

PHONY += build-doc
build-doc: 
	docker run --rm -ti --user $(USER_IDENTIFIER) -v $(CURDIR)/doc:/documents -v $(CURDIR):/tmp moird/mkdocs mkdocs build --site-dir /tmp/doc-site 

PHONY += serve-doc
serve-doc: 
	docker run -d -p 8000:8000 -v $(CURDIR)/doc:/documents --name moosex-dic-doc moird/mkdocs

PHONY += stop-serve-doc
stop-serve-doc:
	docker stop moosex-dic-doc
	docker rm moosex-dic-doc

PHONY: $(PHONY)
