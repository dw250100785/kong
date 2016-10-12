local helpers = require "spec.helpers"
local cjson = require "cjson"
local cache = require "kong.tools.database_cache"

describe("Plugin: AWS Lambda (access)", function()
  local client, api_client
  setup(function()
    assert(helpers.start_kong())

    local api = assert(helpers.dao.apis:insert {
      request_host = "lambda.com",
      upstream_url = "http://httpbin.org"
    })
    
    assert(helpers.dao.plugins:insert {
      name = "aws-lambda",
      api_id = api.id,
      config = {
        aws_key = "AKIAIDPNYYGMJOXN26SQ",
        aws_secret = "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",
        aws_region = "us-east-1",
        function_name = "kongLambdaTest"
      }
    })
  end)
  before_each(function()
    client = helpers.proxy_client()
    api_client = helpers.admin_client()
  end)
  after_each(function ()
    client:close()
    api_client:close()
  end)
  teardown(function()
    helpers.stop_kong()
  end)

  it("invokes a Lambda function with GET", function()
    local res = assert(client:send {
      method = "GET",
      path = "/get",
      headers = {
        ["Host"] = "lambda.com"
      }
    })
    local body = assert.res_status(200, res)
    assert.is_string(res.headers["x-amzn-RequestId"])
    assert.equal([["some_value1"]], body)
  end)

end)
