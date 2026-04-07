const { createProxyMiddleware } = require("http-proxy-middleware");

function shouldProxy(pathValue) {
  return Boolean(pathValue) && pathValue.startsWith("/");
}

module.exports = function setupProxy(app) {
  const airlinesPath = process.env.REACT_APP_AIRLINES_API_URL;
  const flightsPath = process.env.REACT_APP_FLIGHTS_API_URL;

  if (shouldProxy(airlinesPath)) {
    app.use(
      airlinesPath,
      createProxyMiddleware({
        target: process.env.AIRLINES_PROXY_TARGET || "http://airlines:8080",
        changeOrigin: true,
      }),
    );
  }

  if (shouldProxy(flightsPath)) {
    app.use(
      flightsPath,
      createProxyMiddleware({
        target: process.env.FLIGHTS_PROXY_TARGET || "http://flights:5001",
        changeOrigin: true,
      }),
    );
  }
};
