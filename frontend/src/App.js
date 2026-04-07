import { Routes, Route } from 'react-router-dom';
import './App.css';
import Home from './pages/Home';
import Airlines from './pages/Airlines';
import Flights from './pages/Flights';
import Navigation from './components/Navigation';
import { getWebInstrumentations, initializeFaro } from '@grafana/faro-web-sdk';
import { TracingInstrumentation } from '@grafana/faro-web-tracing';

const faroUrl = process.env.REACT_APP_FARO_URL;

if (faroUrl) {
  initializeFaro({
    url: faroUrl,
    app: {
      name: process.env.REACT_APP_FARO_APP_NAME || 'POV-SIM',
      version: process.env.REACT_APP_FARO_APP_VERSION || '1.0.0',
      environment: process.env.REACT_APP_FARO_ENVIRONMENT || process.env.NODE_ENV || 'development',
    },

    instrumentations: [
      ...getWebInstrumentations(),
      new TracingInstrumentation(),
    ],
  });
}

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <Navigation />
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/flights" element={<Flights />} />
          <Route path="/airlines" element={<Airlines />} />
        </Routes>
      </header>
    </div>
  );
}

export default App;
