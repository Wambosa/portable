.PHONY: install lint test build deploy shim sanity_check run watch prepare_zip prepare_zip_lambda prepare_zip_container register_container prepare_zip_layer find_distinct_concept terraform clean circleci

PROJECT            := etl-example
PREFIX             := etl
EXT                := py
TF_VER             := 0.12.12
BUILD_LOCAL_DIR    := .build
BUILD_LAMBDA_DIR   := ./infra/lambda/.build
BUILD_LAYER_DIR    := ./infra/layer/.build/layer/python/lib/python3.7/site-packages

# 
# Common Repositry Activities
# 

install:
	@make -s clean \
	&& make -s terraform \
	&& pip install --progress-bar off -r ./tests/requirements.txt \
	&& pip install --progress-bar off -r ./src/common/requirements.txt ;\

lint:
	@pylint --rcfile=config/pylintrc src \
	&& ${BUILD_LOCAL_DIR}/terraform fmt -recursive \
	&& ${BUILD_LOCAL_DIR}/terraform validate

test:
	@pytest --disable-pytest-warnings

build:
ifeq ($(TARGET), layer)
	@make --no-print-directory prepare_zip_layer
endif
ifeq ($(TARGET), lambda)
	@make --no-print-directory prepare_zip_lambda
endif
ifeq ($(TARGET), ecr)
	@make --no-print-directory prepare_zip_container WITH_UPLOAD=1
endif
	@cd ./infra/${TARGET} \
	&& ../../${BUILD_LOCAL_DIR}/terraform init \
	&& ../../${BUILD_LOCAL_DIR}/terraform get \
	&& ../../${BUILD_LOCAL_DIR}/terraform validate

deploy:
	@cd ./infra/${TARGET} \
	&& ../../${BUILD_LOCAL_DIR}/terraform apply ${AUTO_APPROVE} \
		-var="environment=${ENV}"

# 
# Local development
# 

# standup some fake resources to target for isolated realtime testing
# note: this particular version of the command will steal one console window
shim:
	@docker-compose -f ./tests/docker-compose.yml up --build


# highly specific to the project, will cause local environment to trigger workload
# carrying out some scenario for testing
sanity_check:
	@aws --endpoint-url=http://localhost:4572 s3 cp tests/data/sanity.csv s3://raw-data \
	&& aws --endpoint-url=http://localhost:4572 s3 cp tests/data/large.csv s3://raw-data \
	&& aws --endpoint-url=http://localhost:4576 sqs send-message \
		--queue-url http://localhost:4576/queue/pending-worker \
		--message-body '{"bucket": "raw-data", "key": "sanity.csv"}'

# execute a function with whatever parameters required
# this is an alternate and faster method, vs refreshing a docker container
run:
	@make -s --no-print-directory prepare_zip_container \
	&& cd ${BUILD_LOCAL_DIR}/${FUNC} \
	&& echo RUNNING: ${FUNC}.${EXT} $(RUN_ARGS) \
	&& python main.${EXT} $(RUN_ARGS)

# a test runner that watches files and runs the unit tests when files change
# this is a janky "test runner" for the concept rather than an actual implementation
# Note: steals a console window
watch:
	@while true; do \
		make -s test ;\
		sleep 15 ;\
	done

# 
# Helpers
# reused multiple times by other actions

prepare_zip:
	@rm -rf ${BUILD_DIR}/${NAME} \
	&& mkdir -p ${BUILD_DIR}/${NAME}/lib \
	&& cp ./src/common/requirements.txt ${BUILD_DIR}/${NAME}/requirements.txt \
	&& cp ./src/common/${WRAPPER} ${BUILD_DIR}/${NAME}/main.${EXT} \
	&& cp ./src/common/context.${EXT} ${BUILD_DIR}/${NAME}/context.${EXT} \
	&& cp ./src/lib/* ${BUILD_DIR}/${NAME}/lib/ \
	&& cp ./src/func/${NAME}.${EXT} ${BUILD_DIR}/${NAME}/func.${EXT} \
	&& test -f ./config/${NAME}.yml && cp ./config/${NAME}.yml ${BUILD_DIR}/${NAME}/const.yml || echo ;\

prepare_zip_lambda:
	@LAMBDAS="$(shell make -s find_distinct_concept CONCEPT_PATH=./infra/lambda)" \
	&& echo "zipping detected lambdas: $$LAMBDAS" ;\
	for name in $$LAMBDAS ; do \
		make -s prepare_zip NAME=$$name WRAPPER=lambda_wrapper.${EXT} BUILD_DIR=${BUILD_LAMBDA_DIR} ;\
	done

prepare_zip_container:
	@CONTAINERS="$(shell make -s find_distinct_concept CONCEPT_PATH=./src/func)" \
	&& echo "zipping detected containers: $$CONTAINERS" ;\
	for name in $$CONTAINERS ; do \
		make -s prepare_zip NAME=$$name WRAPPER=local_wrapper.${EXT} BUILD_DIR=${BUILD_LOCAL_DIR} \
		&& make -s register_container WITH_UPLOAD=${WITH_UPLOAD} ;\
	done

register_container:
ifeq ($(WITH_UPLOAD), 1)
	@AWS_ACCOUNT_ID=$$(aws sts get-caller-identity --output text --query 'Account') ;\
	docker build -f ./src/common/docker_wrapper \
		--build-arg func_build_dir=${BUILD_LOCAL_DIR}/$$name/ \
		-t $${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/${PREFIX}/$$name . ;
endif


prepare_zip_layer:
	@rm -rf ${BUILD_LAYER_DIR} \
	&& mkdir -p ${BUILD_LAYER_DIR} \
	&& pip install --progress-bar off -r ./src/common/requirements.txt -t ${BUILD_LAYER_DIR}

find_distinct_concept:
	@echo "$(shell ls -I "terraform" -I "__pycache__" -I "__init__.tf" -I "vars.tf" ${CONCEPT_PATH} -1 | sed -e 's/\..*$$//')"

terraform:
	@echo "installing terraform ${TF_VER}"
	wget https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip > /dev/null 2>&1 \
	&& unzip ./terraform_${TF_VER}_linux_amd64.zip -d . \
	&& rm -f ./terraform_${TF_VER}_linux_amd64.zip \
	&& chmod +x ./terraform \
	&& mkdir -p ${BUILD_LOCAL_DIR} \
	&& mv ./terraform ${BUILD_LOCAL_DIR}/terraform

clean:
	@rm -rf ${BUILD_LAMBDA_DIR} ;\
	rm -rf ${BUILD_LOCAL_DIR} ;\
	rm -rf ${BUILD_LAYER_DIR} ;\
	find . -name '__pycache__' -exec rm -rf "{}" \; > /dev/null 2>&1 ;


# 
# CI Only
# It is possible to create build images ahead of time that will already have permissions and dependencies preinstalled
# this practice improves build time. In our example, we will just install dependencies evertime since they are light 
# and fix any permission issues in the blank environment.

circleci:
	@sudo chmod -R 777 /usr/local/share \
	&& sudo chmod -R 777 /usr/local/bin/ \
	&& sudo chmod -R 777 /usr/local/lib/python3.7/site-packages \
	&& make install \
	&& aws --version
