import { Routes, Route, Navigate } from 'react-router-dom'
import { useEffect, useState } from 'react'
import LandingPage from './LandingPage'
import ChatPage from './ChatPage'
import MemoriesPage from './MemoriesPage'
import UploadPage from './UploadPage'
import AppShell from './AppShell'
export default function App() {
  const [session, setSession] = useState(() => {
    try { return JSON.parse(localStorage.getItem('sahara_session') || 'null') }
    catch { return null }
  })

  const saveSession = (s) => {
    setSession(s)
    if (s) localStorage.setItem('sahara_session', JSON.stringify(s))
    else    localStorage.removeItem('sahara_session')
  }

  const hasSession = session?.session_id && session?.person_name

  return (
    <>
      <div className="grain-overlay" />
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/upload" element={
          <UploadPage onSession={saveSession} />
        } />
        <Route path="/chat" element={
          hasSession
            ? <AppShell session={session} onClear={() => saveSession(null)}>
                <ChatPage session={session} />
              </AppShell>
            : <Navigate to="/upload" replace />
        } />
        <Route path="/memories" element={
          hasSession
            ? <AppShell session={session} onClear={() => saveSession(null)}>
                <MemoriesPage session={session} />
              </AppShell>
            : <Navigate to="/upload" replace />
        } />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </>
  )
}
