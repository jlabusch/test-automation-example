IMAGE=paysauce-tests
SHELL:=/bin/bash

build:
	docker build -t $(IMAGE) .

test:
	@for i in ./sites/*; do ./bin/run_tests.sh $$i; done

clean:
	docker rmi $(IMAGE)
