const http = require('http')
const aws = require('aws-sdk')
const codedeploy = new aws.CodeDeploy()

exports.handler = async function (event, context, callback) {
  console.log('Entering PreTraffic Hook!')
  console.log(event)

  // Sleep to ensure the test traffic is fully attached to the new Target Group and Test Listener in time before health check
  console.log('Waiting 20 seconds')
  await new Promise((resolve) => setTimeout(resolve, 20 * 1000))

  const { DeploymentId, LifecycleEventHookExecutionId } = event
  let status = 'Succeeded'
  try {
    const {
      deploymentInfo: { applicationName },
    } = await new Promise((resolve, reject) => {
      codedeploy.getDeployment({ deploymentId: DeploymentId }, (err, data) => (err ? reject(err) : resolve(data)))
    })

    const { AWS_ACCOUNT_ID } = process.env
    const healthCheckRequest = {
      // Use HTTP, so that load balancer will forward the request to HTTP test Lister on port 80
      host: `${applicationName}.${AWS_ACCOUNT_ID}.internal.monsanto.net`,
      path: '/ping',
    }
    console.log(healthCheckRequest)
    const response = await new Promise((resolve, reject) => {
      const req = http.request(healthCheckRequest, (res) => {
        const chunks = []
        res.on('data', (data) => chunks.push(data))
        res.on('end', () => {
          let data = Buffer.concat(chunks)
          resolve({ data: data.toString('utf8'), statusCode: res.statusCode })
        })
      })
      req.on('error', reject)
      req.end()
    })
    console.log('Health check response:')
    console.log(response)
    if (response.statusCode != 200) status = 'Failed'
  } catch (err) {
    console.error(err)
    status = 'Failed'
  }

  const params = { deploymentId: DeploymentId, lifecycleEventHookExecutionId: LifecycleEventHookExecutionId, status }
  console.log(params)

  try {
    // Report the health check Pass/Fail to deployment
    await codedeploy.putLifecycleEventHookExecutionStatus(params).promise()
    console.log('Successfully reported hook results')
  } catch (err) {
    console.error('Failed to report hook results')
    console.error(err)
  }
}
