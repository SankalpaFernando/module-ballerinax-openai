# Running Tests

## Prerequisites
You need an Access token from OpenAI developer account.

To do this, refer to [OpenAI API Documentation](https://platform.openai.com/docs/api-reference/introduction).

# Running Tests

There are two test environments for running the OpenAI connector tests. The default test environment is the mock server for OpenAI API. The other test environment is the actual OpenAI API. 

You can run the tests in either of these environments and each has its own compatible set of tests.

 Test Groups | Environment                                       
-------------|---------------------------------------------------
 mock_tests  | Mock server for OpenAI API (Defualt Environment) 
 live_tests  | OpenAI API                                       

## Running Tests in the Mock Server

To execute the tests on the mock server, ensure that the `IS_LIVE_SERVER` environment variable is either set to `false` or unset before initiating the tests. 

This environment variable can be configured within the `Config.toml` file located in the tests directory or specified as an environmental variable.

#### Using a Config.toml File

Create a `Config.toml` file in the tests directory and the following content:

```toml
isLiveServer = false
```

#### Using Environment Variables

Alternatively, you can set your authentication credentials as environment variables:
If you are using linux or mac, you can use following method:
```bash
   export IS_LIVE_SERVER=false
```
If you are using Windows you can use following method:
```bash
   setx IS_LIVE_SERVER false
```
Then, run the following command to run the tests:

```bash
   ./gradlew clean test
```

## Running Tests Against OpenAI Live API

#### Using a Config.toml File

Create a `Config.toml` file in the tests directory and add your authentication credentials a

```toml
   isLiveServer = true
   token = "<your-openai-access-token>"
```

#### Using Environment Variables

Alternatively, you can set your authentication credentials as environment variables:
If you are using linux or mac, you can use following method:
```bash
   export IS_LIVE_SERVER=true
   export OPENAI_TOKEN ="<your-openai-access-token>"
```

If you are using Windows you can use following method:
```bash
   setx IS_LIVE_SERVER true
   setx OPENAI_TOKEN <your-openai-access-token>
```
Then, run the following command to run the tests:

```bash
   ./gradlew clean test 
```