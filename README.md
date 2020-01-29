# Portable function pattern for the scaling business
_example repository_

# Table of Contents

* [C4 Diagrams](#c4-diagrams)
* [System Requirements](#system-requirements)
* [Running Local](#running-local)
* [Test Overview](#test-overview)
* [Deploy Overview](#deploy-overview)
* [Contributing](#contributing)
* [Adding a new Lambda](#adding-a-new-lambda)

-----

## C4 Diagrams
![c4 container](https://s3.amazonaws.com/shondiaz.com/img/c4/example-pub-sub-etl-container.png)


## System Requirements
- Ubuntu 18.x
- python 3.7
  - `python` not `python3`
- docker
- docker-compose
- awscli

## Running Local
Before running locally, ensure that the proper system requirements are met.
Then,
```
make install
make shim
```
These will establish all dependencies for local runs.

Calling `make run` will rebuild the target script in the `.build/` direectory, 
and execute the `main.py` with any provided run arguments.

```
make run FUNC=worker RUN_ARGS=' \
--read_queue=pending-worker \
--sqs_endpoint=http://localhost:4576 \
--db_host=127.0.0.1 \
--db_port=13306 \
--db_name=activity \
--db_user=root \
--db_pass=password \
'
```

## Test Overview
Before running tests, ensure that the proper system requirements are met. 
Then, `make install`.

Unit tests can be called with `make test`.
Additionally linting is available for both the business logic language and IaC (terraform) with `make lint`.
Both commands should be wired up in any CI/CD solution.

```
make test
make lint
```


## Deploy Overview
Manual deploys is possible directly from the command line if the appropriate permissions are configured.

```
export AWS_ACCESS_KEY_ID=AAAAAAAABBBBBBBCCCCCC
export AWS_SECRET_ACCESS_KEY=******************************
export AWS_DEFAULT_REGION=us-west-2

export TF_VAR_rds_user=bot
export TF_VAR_rds_pass=password
```

```
make build TARGET=role ENV=lab
make build TARGET=network ENV=lab
make build TARGET=queue ENV=lab
make build TARGET=aurora ENV=lab
make build TARGET=layer ENV=lab
make build TARGET=lambda ENV=lab

make deploy TARGET=role ENV=lab
make deploy TARGET=network ENV=lab
make deploy TARGET=queue ENV=lab
make deploy TARGET=aurora ENV=lab
make deploy TARGET=layer ENV=lab
make deploy TARGET=lambda ENV=lab
```

These commands can be easily [wired up to a CI/CD pipeline](./.circleci/config.yml).
The builds and deploys can be triggered by events specified by the team _(on push, on merge to master, on tag, etc)_.

##### what happens in a deploy?

1. Scripts `./src/lambda`, const `./config/{scriptFileName}.yml`, and wrapper `./src/common/lambda_wrapper.py` are copied into a build directory for zip archiving.
2. Terraform does a unique hash on the resulting lambda(s) zip that serves as a way to diff changes.
3. Terraform will create/update the lambda function.
4. Other `./infra/*` folders are examined by terrraform and compared against the running aws environment
5. When there are differences in the `.tf` files from the live environment, then terraform will create/update/destroy live aws resources


### Contributing
_Changing the system, adding a new method or updating an existing method._

1. Tests should be invoked with `make test` after changes.
2. A test runner can be activated with `make watch`.
3. Run `make lint` before push and fix any hangups.


#### Adding a new lambda
_There are a few places that need to be touched in order to create a new function._

1. `src/func/func_name.py`
2. `tests/func_name.py`
3. `infra/queue/func_name.tf`
4. `infra/lambda/func_name.tf`

_Once development is satisfactory;_  
5. `make deploy TARGET=lambda ENV=lab`
  - _or use CI/CD triggers_


-----


### Optional Dependency install tips

pyenv+awscli
```
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

...(configure your shell)...

pyenv virtualenv 3.7.0 example
pyenv activate example
make install
```

docker-compose
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)"  -o /usr/local/bin/docker-compose \
&& sudo mv /usr/local/bin/docker-compose /usr/bin/docker-compose \
&& sudo chmod +x /usr/bin/docker-compose
```


-----


### future
  - need to complete the ECR/ECS terraform example
  - spellcheck
  - show how to connect to the rds behind vpc
    - likely jump host
  - potentially show global state in example instead of local terraform state

-----
