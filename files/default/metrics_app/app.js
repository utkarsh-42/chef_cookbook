const express = require('express');
const client = require('prom-client');

const app = express();
const register = new client.Registry();

// Add default metrics
client.collectDefaultMetrics({
  register,
  prefix: 'node_'
});

app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.send(metrics);
  } catch (error) {
    res.status(500).send(error.message);
  }
});

app.listen(9100, () => {
  console.log('Metrics application listening on port 9100');
});
