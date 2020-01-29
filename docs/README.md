# Portable function pattern for the scaling business

The landscape of platforms and runtimes is ever increasing. 
There are more ways of packaging and running code than are possible to keep up with. 
Engineers are now required to learn highly specific workflows in order to remain relevant.
This divides the talent pool. So when a business decides to choose a specific technology, 
they effectively also select their available talent pool(s) as well.

These specific workflows have a way of bleeding into the business logic itself, creating a highly coupled system.
These workflows can also bleed into the hiring process, limiting growth, and complicate on-boarding.

How can we architect in such a way, that when a shop needs to expand, the staff and business logic stand the test of time?
A simple universal solution may not exist, when considering all the varying shop stacks.
We at least know that it requires full-stack expertise and real collaboration between several information technology disciplines. 

As an old mentor would say, "An Infinitely complex problem takes an infinite amount of time to solve.", 
So the problem here will be narrowed down to a subset of common environments and well-known problem space.
The four environments we will focus on are 
lambdas, docker (or containerized), local cli, and within unit-tests _(yes unit-tests count as its own environment!)_.

For our problem space, 
a function is considered _"portable"_ 
if it can run WITHOUT alteration as a lambda (flavor aws/other), 
as a docker container (or other container flavor),
from your local dev machine via cli,
and within unit-tests.
In order to dramatically scope down this article, we will stick to aws lambda and docker for containerization.


## Project Organization
[This repository][repo] will be a full example of the pattern. 
There will be an explanation of most of the more complex files and how they tie together.
The directory structure is **chosen first** as a way to create the ideal location for individual concepts and their management.
Any consequences of the directory structure are handled with the "glue code" (or deployment scripts usually authored by devOps-esque talent).
The high level directory should be straight forward and easily maintainable as to discern the three major ingredients of the stack at a glance.

Really, only 4 directories are required `config infra src tests`.

high level directory structure:
```
config/
docs/
infra/
src/
  common/
  func/
  lib/
tests/
  mock/
```


## Shop Stack Choices

![shop soup](https://s3.amazonaws.com/shondiaz.com/img/shop-soup.png)

There are many IaC solutions out there, and even more programming/scripting languages.
We have chosen Terraform, Makefile, and python here. 
These choices **do not** prescribe the only way to accomplish the pattern, 
rather express a clear example of how the three choices interact with one another.
Here are a few features to consider when making stack choices for a shop. 

#### Infrastructure as Code
- first class cli support
- idempotent runs
  - diff detection
- strong active community
- allows for clean folder organization
  - no infrastructure 1000 line+ megafile
- understands dependencies
- easy to install

#### Glue Code
- well-known
- no dependencies
  - bonus if preinstalled _(like bash or makefile)_
- can be run locally (doesn't depend on interpreter in the cloud)
- supported by major CI solutions

#### Language of Choice
- well-known
  - easier to find affordable talent
  - _hint: don't choose COBOL_


## Non-Testable Code
As an example, we will use a simple worker script that takes data from one place and puts it in another.
We won't call it an ETL job, because we are all just sick of seeing those. 
We are also sick of seeing non-testable functions. 
What is meant by "non-testable", are blocks of code that require an impractical amount of mocking to emulate i/o (network disk) activity.
Below is such an example; in order to test, we would need to hijack the `boto3 + pymysql` libraries or create an entire environment for testing.
This function is not _portable_, because it will not run within the unit-test setting _(using libs like rewire do not count, even though they are a nice workaround)_.

ibm-mainframe-worker.py
_(just pretend python works on IBM mainframes)_
```
  import json
  import boto3
  import pymysql.cursors

  records = []

  s3 = boto3.client('s3')
  obj = s3.get_object(Bucket='in-bucket', Key='new-file.txt')
  raw = obj['Body'].read()

  for line in raw.split('\n'):
    records.append(tuple(line.split(',')))

  insert_statement = 'insert into `clicks` values(%s, %s, %s);'

  conn = pymysql.connect(
    host=os.environ.get('DB_HOST'),
    db=os.environ.get('DB_NAME'),
    user=os.environ.get('DB_USER'),
    password=os.environ.get('DB_PASS'),
    charset='utf8',
    cursorclass=pymysql.cursors.DictCursor
  )

  with conn.cursor() as cursor:
    cursor.executemany(insert_statement, records)
  conn.commit()
```


## Legacy ETL Process Rant
The `ibm-mainframe-worker.py` code above is inspired from some IBM mainframe code encountered last year where severe limitations prevented modern practices.
Many integrations with legacy ETL processes usually mean read/write from a ftp/sftp server. 
More "sophisticated" processes can handle multiple files at a time since some sort of dynamic naming scheme is utilized.
Less sophisticated processes use the same exact filename (because why not).
Fast forward to the modern day, and we have ourselves entire companies that compete to produce near-mindless WYSIWYG ETL job processors.
We could put a pin in ETLs and jump to the conclusion that it is a "solved problem", since it is certainly a well-known problem at the very least. 
Despite the well-known nature of the problem, shops often still need this kind of work done regularly.


## So what kind of problem is best suited for this pattern?
Although this specific example is using a well known problem space, the pattern is not limited to just ETL, rather is best suited for [pub-sub models][pub sub].
Any kind of **function that can work independently** on a unit of work concurrently alongside another process without clashing.
It also doesn't hurt if the function is idempotent as well. 
Idempotency is _especially_ important if the message broker might duplicate messages _(AWS SQS can duplicate messages on occasion)_.

![c4 container](https://s3.amazonaws.com/shondiaz.com/img/c4/example-pub-sub-etl-container.png)

Taking a look at the diagram, we see that vendor(s) produce data that the shop needs. 
When the raw data appears in the system _(via s3)_, a message is created and sent to any subscribers _(sqs in this setup)_. 
Sqs will be the location that houses any pending work acting as a message broker. 
If there is work, any number of workers can take aim at the queue, pop off a unit of work and be on their problem solving way.
As a bonus, AWS actually offers a simple integration between lambda and sqs so that polling logic for the lambda context can be handled in the infrastructure; neat.


### Feedback loops
A feedback loop are all the events that take place between changing a line of code and experiencing that change.
The loop is measured in time and complexity. Ideally the loop is as short and simple.
Feedback from unit test runs, local instance runs, and deployed runs should be near effortless and FAST.
It is fair that deployed runs take much longer than unit tests, given that they are more complex. 
Still, if your unit tests are too slow, then that may very well cause deploys to lag as well.


#### The `test/local` feedback loop
The above legacy ETL `ibm-mainframe-worker.py` is difficult to test, so it naturally has a poor feedback loop. 
It could take some time to coordinate with other engineers via chat or email; "is the file in bucket xyz okay to be overwritten for my 'local' test?".
Additionally, opening business logic files and editing the code in order to test it is not ideal. Changes like that could end up in source control accidentally.
Workflows like this damage the test feedback loop. 
Even though the actual execution time of the code is fast, the prep beforehand is manual, repetitive, and risky.

For anyone that is familiar with VR _(virtual reality)_ headsets; the local development for compatible apps are quite cumbersome out of the gate.
Code changes and runs are mixed with physically putting on a helmet. 
The time it takes to do this is immense when compared to other types of projects. 
Most shops do not require a device as complex as a VR headset, 
so the local feedback loop for altering a line of code in business logic should at least be faster than a VR workflow.

#### The `deploy` feedback loop
The experience an engineer has while maintaining and extending an app is crucial to keep a solid morale. 
If a deploy feedback loop takes more than a few minutes, then engineers are likely to waste a larger amount of time on process.
An engineer should experience the fastest loop time of a few seconds locally,
a tester ought to wait no more than a few minutes on deploy changes.
Finally a stakeholder should be able to experience a change within the hour.
Not saying that all changes need to be completely rolled out within an hour, just that it needs to be within the realm of possibility.


## A workflow that meets high standards
The feedback loop for business logic development will be totally contained on the engineers machine with a few commands.
Engineer's will also have total control over every element within the application lifecycle _(every component shown on the product diagram within the demarcation point)_.

terminal map
```
1 | 2 
--|--
3 | 4 
```

![engineer feedback loops](https://s3.amazonaws.com/shondiaz.com/img/portable-feedback-loop.gif)


#### Terminal 1
_the worker (or whatever program that needs testing)_
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

The app code runs in terminal 1 with log output. 
It can be fully parameterized to redirect any i/o that occur within the app.


#### Terminal 2
_cli playground_
```
aws --endpoint-url=http://localhost:4572 s3 cp tests/data/large.csv s3://raw-data

...

aws --endpoint-url=http://localhost:4576 sqs send-message \
--queue-url http://localhost:4576/queue/pending-worker \
--message-body '{"bucket": "raw-data", "key": "large.csv"}'

...

mysql -u root -h 127.0.0.1 -P 13306 -ppassword
```

The second terminal is the cli playground which allows a window into the system. 
This can be used for both viewing results and simulating events. 
In the above gif example, we have a simulated s3->sqs event, 
then a database is connected to in order to validate the results of the local app code.


#### Terminal 3
_(mock infrastructure s3/sqs/mysql)_
```
make shim
```

This command creates a docker network containing a fake aws environment configured with relevant components.
It also creates an actual mysql database that our app will point to.
These resources are isolated and will not overlap with other developers working at the same time 
_(may seem like a silly thing to point out, but many shops do not have this luxury)_.
Even if the shop does not use aws or mysql, this command is responsible for knowing what needs to be shimmed and does so.
Any stack choices ought to be considered in light of how complex it is to mock. 
Who ever selects the stack ought to be able to additionally write a `make shim` command as a part of a spike or other investigation.


#### Terminal 4
_test runner_
```
make watch
```

A test runner watches changes made to `src/` files and reruns unit tests as an engineer works.
We are using a thin homebrew runner that simply runs on 15 second intervals.
The test runner here is quite rudimentary, yet captures the essence of the test runner for the article. 
If a language does not have a test runner, it isn't a deal breaker. 
Typing out `make test` on demand is a feasible low-cost step in the development workflow, or even better, a pre-commit hook.


## Refactored Legacy ETL
Here is an altered version of the legacy ibm-mainframe-worker that does the exact same thing.
The differences are how injectable the function is. 
One might say, "hey! `import json` seems like a dependency that cannot be easily mocked!"
That would be correct. 
The difference between libs `json` and `pymysql` or `boto3` is input/output activity.
Libraries that use `i/o` in form of disk or network must be injected into the function as an argument so that they can be easily controlled.

`src/func/worker.py`
```
import json

def run(event, context):
  work = json.loads(event)
  bucket = work['bucket']
  key = work['key']
  records = []

  obj = context.s3.get_object(Bucket=bucket, Key=key)
  raw = obj['Body'].read()

  for line in raw.split(context.var.newline):
    records.append(tuple(line.split(context.var.delimiter)))

  insert_statement = context.var.sql.insert_statement

  context.rds.executemany(insert_statement, records)
```


## Why is "context" everywhere?
The runtime context is your one stop shop for injectable values. 
Configuration values, database connections, disk reads/writes, service broker, and other network operations. 
The context will be the object that gets manipulated by the various runtimes so that your function can run happily no matter where it is.


## Context Configuration Priorities
In order to handle the various runtime configuration requirements, 
the context has to have a way of prioritizing conflicting configurations from multiple sources.
The following priority has been safe for many shops; `configuration file < environment variables < cli arguments`.
Configuration files house the "sane-defaults", ideally no secrets are here, 
but things like "what kind of delimiter", 
or "how long to wait for the database before timing out"; are good sane-default values. 
Sure you can hardcode em too, but why not parameterize instead? 
You too could be a hero if parameterize configuration values. 
Finally cli arguments supercede whatever else may have been set by any other configuration. 
When running locally, there should be ZERO magic. 
Every adjustable parameter should be controllable on execution from the entry point. 
Developers cursed with maintaining your repo should feel like Magneto on the Golden Gate Bridge. 
Totally unfettered and powerful.

`src/common/context.py`
```
class CustomContext:

  def __init__(self, aws_ctx=None, args=None):
    const_path = args.get('const_path') if args else './const.yml'
    const = load_const(const_path)
    env = load_env()
    var = dict()
    var.update(const)
    var.update(env)
    if args:
      var.update(args)
    self.var = Box(var)

    self.aws_context = aws_ctx

    self.s3 = boto3.client(
      's3',
      endpoint_url=self.var.get('s3_endpoint')
    )

    self.rds = None

  def __enter__(self):
    self.rds = Aurora(
      host=self.var.db_host,
      port=self.var.db_port,
      db=self.var.db_name,
      user=self.var.db_user,
      password=self.var.db_pass
    ).__enter__()
    return self

  def __exit__(self, _type, _value, _traceback):
    return self.rds.conn.close()
```


## Context is injectable too
`parent`, `args`, `s3_endpoint`, and `Aurora` are some injectable values that allow one to control a context.
While the injection in the example is limited, it is sufficient to grant enough control to meet the needs of this article.
In an even more flexible context, we would be able to pass in any library itself as a parameter, 
making for even easier control over things like s3, database access, parsing, etc.
For example: `def __init__(self, boto, rds, parent=None, args=None):`.


## The importance of CustomContext's `parent`
`parent` is the context provided by the runtime. AWS Lambda provides a context that has very limited use in python. 
It is more useful in nodejs runtime, however, even with python, there are some useful methods that may be needed.
`aws_context.get_remaining_time_in_millis()` will let the runtime know if being cut off by lambda's strict time limit is near; 
allowing one to stop a long running download mid flight and safely exit. 
If this sort of function is needed, a CustomContext can have an abstracted call to the `parent` which requests for the time remaining. 
In a unit-test environment, one could easily mock the function call to return a time that would trigger the desireable code path.


## What is an "event"
An event is defined by the architect of the application, 
and represents a unit of work achievable by the function.
It can be whatever shape required to do the job. 
The application will understand this event shape as a trustworthy fact.
Note: A function is idempotent if it produces the _same end result_ when being passed the _same event_ over and over.

event
```
{
 "bucket": "upload-test",
 "key": "dynamic-file-name-123.txt"
}
```

Note that the above event is a simplification of the `s3->sns->sqs` pipeline.
The real world s3 notification event looks like this:
```
{
  "Records": [
    {
      "eventVersion": "2.0",
      "eventSource": "aws:s3",
      "awsRegion": "us-west-2",
      "eventTime": "1970-01-01T00:00:00.000Z",
      "eventName": "ObjectCreated:Put",
      "userIdentity": {
        "principalId": "EXAMPLE"
      },
      "requestParameters": {
        "sourceIPAddress": "127.0.0.1"
      },
      "responseElements": {
        "x-amz-request-id": "EXAMPLE123456789",
        "x-amz-id-2": "EXAMPLE123/5678abcdefghijklambdaisawesome/mnopqrstuvwxyzABCDEFGH"
      },
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "testConfigRule",
        "bucket": {
          "name": "example-bucket",
          "ownerIdentity": {
            "principalId": "EXAMPLE"
          },
          "arn": "arn:aws:s3:::example-bucket"
        },
        "object": {
          "key": "test/key",
          "size": 1024,
          "eTag": "0123456789abcdef0123456789abcdef",
          "sequencer": "0A1B2C3D4E5F678901"
        }
      }
    }
  ]
}
```


## The Wrappers
The wrapper will surround the CustomContext and function, marrying the two in perfect harmony.
The wrapper knows where it is meant to be run. 
It knows if it is being run in lambda, docker, tests, or from the cli.
It is possible to create a single wrapper file that contains all this knowledge and knows how to swap behavior based on the runtime.
Even though it is possible to create a single wrapper, it tends to be more self-explanitory, straight forward, and maintainable to have one wrapper for each diverse environment.
In the case of tests, one might actually create multiple wrappers in order to manipulate the conditions for one's nefarious purposes. 
Ironically, the wrapper itself is often not unit testable because of its enviromental awareness. 
It is meant to be extremely thin and "dumb". The most complex wrapper ought to be the local/container variant because it is a no-magic zone.


### Wrapper relies on the build step
The wrapper does NOT know what function it is calling. 
It generically loads the same path and calls the function with a known signature `run(event, context)`.
Not knowing what function it is calling allows the wrapper to be reused for many functions with the same dependencies.
This places the burden of knowing which function to run on the build step (`make build`). 
The build step will treat both wrapper and CustomContext as build dependencies since both wrapper and CustomContext are shared with all functions.


### Lambda Wrapper
Lambda has some good default behavior, and then, it has some bad default behavior. 
Automatic unaccounted retries are a big fat no-no for pub-sub models. 
In general, automatic retries are just undesirable _(especially for non-idempotent designs)_. 
AWS has finally exposed a configurable value "retry attempts", which is default set to "2". 
Before this value was exposed, 
one had to use the following global cache space to store all `aws.context.request_id` and short circut the function manually.

Some other points to note are the assignment of `parent`. Allowing the context access to AWS lambda's default context.
Finallly the `with CustomContext` invokes an `__enter__` and `__exit__` function when scope is entered and exited. 
Allowing for connection setup and cleanup respectively.

`src/common/lambda_wrapper.py`
```
from func import run
from context import CustomContext

RETRY = []

def handler(event, aws_ctx):
  print(event)
  if aws_ctx.aws_request_id in RETRY:
    return None
  RETRY.append(aws_ctx.aws_request_id)

  with CustomContext(parent=aws_ctx) as custom_context:
    return run(event, custom_context)
```


### Local Wrapper
Local should be simpler, and it is, even though there are more lines of code.
The process is still much simpler because the script has the same behavior as sqs-lambda integration with ZERO magic. 
All of the features of the sqs-lambda integration are called out explicitely and are directly manipulatable.

Sadly in some ways, this script is more stable than the sqs-lambda integration 
due to [AWS's internal polling bug][sqs overpull] which causes some messages to be unintentionally 
deadlettered when implementing a low number of `reserved_concurrent_executions`.

`src/common/local_wrapper.py`
```
import time
import boto3
import traceback
from box import Box
import configargparse

from func import run
from context import CustomContext

def main(args):
  sqs = boto3.client(
    'sqs',
    endpoint_url=args.sqs_endpoint
  )
  read_url = sqs.get_queue_url(QueueName=args.read_queue)['QueueUrl']
  res = sqs.receive_message(
    QueueUrl=read_url,
    MaxNumberOfMessages=args.poll_batch_size,
  )

  for message in res.get('Messages', []):
    event = message['Body']

    with CustomContext(None, args) as custom_context:
      try:
        run(event, custom_context)
        sqs.delete_message(QueueUrl=read_url, ReceiptHandle=message['ReceiptHandle'])
      except Exception as e:
        print({
          'exception_type': type(e).__name__,
          'error_reason': e.args,
          'traceback': traceback.format_exc()
        })

    time.sleep(args.poll_interval)

##########################
if __name__ == '__main__':
  P = configargparse.ArgumentParser()

  P.add_argument('--read_queue', env_var='READ_QUEUE', type=str)
  P.add_argument('--poll_batch_size', type=int, default=1)
  P.add_argument('--poll_interval', type=int, default=15)

  P.add_argument('--region', type=str, env_var='AWS_DEFAULT_REGION', default='us-east-1')
  P.add_argument('--const_path', type=str, default='./const.yml')

  P.add_argument('--s3_endpoint', env_var='S3_ENDPOINT', type=str, default='http://localhost:4572')
  P.add_argument('--sqs_endpoint', env_var='SQS_ENDPOINT', type=str, default='http://localhost:4576')

  P.add_argument('--db_host', env_var='DB_HOST', type=str, default='localhost')
  P.add_argument('--db_port', env_var='DB_PORT', type=int, default=3306)
  P.add_argument('--db_name', env_var='DB_NAME', type=str, default='activity')
  P.add_argument('--db_user', env_var='DB_USER', type=str, default='root')
  P.add_argument('--db_pass', env_var='DB_PASS', type=str, default='password')

  P.add_argument('--newline', type=str)
  P.add_argument('--delimiter', type=str)
  P.add_argument('--insert_statement', type=str)

  main(P.parse_args(namespace=Box()))
```

Here we implement our own poller. 
This is the equilvalent sqs-to-lambda integration AWS does under the hood, save for the aforementioned lambda scaling bugs.
The sqs.delete_message must also be explicitely called here 
since AWS lambda handles that bit for us automagically when a function reaches the end without failing.
The same is true for this script. If the `run()` completes, then the message is cleared from the queue.
On the otherhand, if there is some unhandled error, we detect it, but just move onto the next message in the queue.
We rely on the deadletter redrive policy to move failed messages of the queue into another location for later review.

Finally the arguments at the bottom of the file allow us to modify any connection value. 
We can change the queue that is being read, the database, aws endpoints, 
some of the values within the config file, or even the entire configuration file.
The powerful `configargparse` has similar libraries in other languages which allow for straightforward config defaults with environment variable support.

Engineers familiar with localstack, may recognize the default sqs and s3 endpoints. 
With a prebuilt localstack docker image, one can mock simple aws services like sqs, s3, and more.
Similarly with mysql, prebuilt docker images would allow for easy bootstrapping of a fully local environment.
This does NOT replace unit testing, rather it allows for swift debugging of the function code without interrupting a nonprod environment's resources, 
or colliding with other realtime debugging from other deveopers.

`tests/docker-compose.yml`
```
version: '3'
services:
  db:
    build:
      context: ../
      dockerfile: ./tests/.docker/db/Dockerfile
    image: example-db
    ports:
      - 13306:3306
    networks:
      - backend
    environment:
      MYSQL_DATABASE: activity
      MYSQL_ROOT_PASSWORD: password
  localstack:
    image: localstack/localstack
    hostname: localhost
    ports:
      - 4572:4572
      - 4576:4576
    networks:
      - backend
    environment:
      SERVICES: s3,sqs
      AWS_ACCESS_KEY_ID: fake
      AWS_SECRET_ACCESS_KEY: fake
      AWS_DEFAULT_REGION: us-east-1
    volumes:
      - ../tests/.docker/localstack:/docker-entrypoint-initaws.d
networks: 
  backend:
    driver: bridge
```


`./tests/.docker/db/Dockerfile`
```
FROM mysql:5.7
ENV MYSQL_ALLOW_EMPTY_PASSWORD true
COPY tests/.docker/db/schema/*.sql /docker-entrypoint-initdb.d/
```

`tests/.docker/localstack/bootstrap.sh`
```
awslocal s3 mb s3://raw-data
awslocal sqs create-queue --queue-name pending-worker
```


### Docker Wrapper?
Incidentally, the local wrapper IS the docker wrapper.
The key to glueing it together is having a sufficiently generic dockerfile that works for any function/container that one would ever need to build.
Again the build step will have already placed contents into `$FUNC_BUILD_DIR` before the Dockerfile is ever run.

`src/common/docker_wrapper`
```
FROM python:3.7
ARG FUNC_BUILD_DIR
RUN mkdir /app
WORKDIR /app
COPY $FUNC_BUILD_DIR ./
RUN pip install -r requirements.txt
CMD ["python3", "-u", "./main.py" ]
```


### Unit Wrapper
This is arguably the most valuable wrapper level, it informs developers in an instant if something is broken.
It tells us subsecond, and over and over again, dozens of time a day if our function is behaving as expected.
A continuous integration environment will also run these checks everytime the codebase changes.
The trouble with the unit wrapper is how subtle it is. It doesn't take the same obvious form as the other wrappers.
It is defined within the unit test files, 
and there are usually many of them defined in specific ways in order to scaffold static scenarios. 


`tests/context/void_context.py`
```
from mock.rds import Rds
from mock.s3 import VoidS3

class VoidContext:

  def __init__(self):
    self.var = Box({
      'insert_statement': '...',
      'delimiter': ',',
      'newline': '\n'
    })

    self.aws_context = None

    self.s3 = VoidS3()

    self.rds = Rds()
```

`tests/context/diff_delimiter_context.py`
```
from mock.rds import Rds
from mock.s3 import DiffDelimiterS3

class DiffDelimiterContext:

  def __init__(self):
    self.var = Box({
      'insert_statement': '...',
      'delimiter': '!',
      'newline': '\n'
    })

    self.aws_context = None

    self.s3 = DiffDelimiterS3()

    self.rds = Rds()
```


## The build/deploy flow
In this example, terraform will be used as the IaC flavor _(infrastructure as code)_. 
The same can be implemented in cloudformation or other IaC solutions. 
All IaC flavors vary in integration level, bugs, syntax, quirks, and maintainability.
Ultimately the choice will likely be whatever is most familiar to the shop's dev ops. 
Some key non negotiable features are:

- idempotent deploys
  - rerunning deploys should produce the same end result
- awareness of new and preexisting resources
  - queues, storage locations, service endpoints, etc
- supports command line interface as first class
  - we want errors to be exposed in both CI automation and local CLI commands

Aside from the IaC, 
the thing that will glue the code together with real live resources are the deployment scripts.
The deployment scripts are captured in two clearly named steps; `build` and `deploy`.

Makefile
```
build:
ifeq ($(TARGET), lambda)
	@make zip_lambda
endif
ifeq ($(TARGET), layer)
	@make zip_layer
endif
	@cd ./infra/${TARGET} \
	&& terraform init \
	&& terraform get

deploy:
	@cd ./infra/${TARGET} \
	&& . ../../config/secrets-${ENV}.env \
	&& terraform apply ${AUTO_APPROVE} \
		-var="environment=${ENV}"
```

Terraform in particular has some nasty race conditions, 
so we ensure that files to be uploaded are prepared before the deploy step in order to totally sidestep the issue.
Terraform is also highly directory specific, so one must be in a specific directory in order to scan the appropriate IaC code.

The `build` step has some conditions.
If we are building the lambda layer, then prepare the lambda layer files.
If we are building the N lambda(s), then prepare the N lambda(s) files.
Terraform additionally has to acquire any provider lib dependencies _(such as aws)_ it may need in order to manage resources.

Finally the `deploy` step can be run after everything is "built" and ready to roll out. 


example deploy flow for lambda
```
make build TARGET=layer ENV=lab
make build TARGET=queue ENV=lab
make build TARGET=lambda ENV=lab
make deploy TARGET=layer ENV=lab
make deploy TARGET=queue ENV=lab
make deploy TARGET=lambda ENV=lab
```


## The Ugly
Every decision has consequences. 
The poison choosen in this universal directory structure is that the file names on imports (for example `from func import run`), 
do not actually exist since there is no file named "func".
Similarly, the `from lib.rds import Aurora` also fail when calling any of the `src/func/*.py` functions directly.
By now, this repository has completely bought into unit tests and isolated local development environments, 
so that the way to execute code is not the language specific method anymore. 
Rather, we now test our code via `make test`, and run local development setups with `make run FUNC=...`.
These abstractions handle the directory mishaps that would otherwise be encountered by directly calling the scripts.
The glue code `make build` will also know where files are in order to move them from maintenance locations to the appropriate location by runtime.
The theory is that a majority of work in the repository will be spent reading the code and searching for where _something_ is. 
So the repository is **catered to the HUMAN** experience, and not the language-of-choice's quirks.



## How it becomes powerful
Fiscal cost and time cost are large factors in architectural decisions _(or at least they should be)_. 
There are costs in maintainability, cost in talent _(or personnel)_, and the more direct infrastructure costs for resource consumption.
The latter infrastructure costs are easily remedied if code can be run on the cheapest resources possible.
Lambda happens to be one of the cheapest, yet maintainable ways of running business logic for more affordable talent. 
As a matter of fact, if a shop is small enough, you can run a business nearly for free with AWS's generous "free until 400k GB seconds" boundary.
Still, there are times when lambda is no longer sufficient. 
I've seen shops data sizes that have gotten so large that lambda fleets start timing out.
Maybe the code used to work, but now the infrastructure needs to scale beyond what lambda can handle. 
If a problem doesn't scale well horizontally, one might be in trouble using lambda as a solution to begin with.
Even with these constraints, ideally any shop could still benefit from a pay-as-you-grow model. 

Since shop requirements can change over time because of scaling needs, 
a common solution would be to use a stack that can handle the future desired "volume of tomorrow" instead of the actual volume today 
_(at the cost of tomorrow as well)_.

This pattern becomes powerful when shops can make a migration to/from lambda/containers with minimal effort and with minimal talent.
Finally, the portable function pattern allows for simple maintenance, averting costs incurred by confusing ad-hoc project layouts, 
or complex deploy pipelines _(destroy all aws resources daily anyone?)_. 


### In closing
By keeping a thin glue layer written in a common well-known language, 
we ensure that just about anyone can come in and manage it if changes are required.
When all resources/assets/infrastructure as code are within a repo as plain text, 
a clear accountability during the development lifecycle and billing period are created.
Saving costs _(both time and fiscally)_ in all three of the aforementioned areas _(maintenance, talent, infrastructure)_ is a feasible and tangible goal.
An example repository will be provided that lays out the pattern with live ecs and lambda code.
The technology choices are minimal, requiring less training, and great flexibility.
It becomes possible to swap out technologies such as the IaC terraform, or business logic language python, or even dev-ops glue makefile.
Plug in your choice of CI/CD solution and monitoring technologies to take this pattern to enterprise grade.
The key is to focus on the engineer's feedback loops _(feeding the morale)_, 
and work from there to create that world with more productive engineers and lower expenses.



----------

[repo]: https://github.com/Wambosa/portable
[pub sub]: https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern
[sqs overpull]: https://medium.com/@zaccharles/lambda-concurrency-limits-and-sqs-triggers-dont-mix-well-sometimes-eb23d90122e0
