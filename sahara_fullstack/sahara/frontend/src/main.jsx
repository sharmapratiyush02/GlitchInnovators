import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import App from './App'
import './globals.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
      <Toaster
        position="top-center"
        toastOptions={{
          style: {
            background: '#FDFAF5',
            color: '#3D1F0A',
            border: '1.5px solid rgba(181,101,42,0.2)',
            fontFamily: 'Sora, sans-serif',
            fontSize: '0.83rem',
          },
        }}
      />
    </BrowserRouter>
  </React.StrictMode>
)
