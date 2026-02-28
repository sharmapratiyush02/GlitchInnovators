import { useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { useDropzone } from 'react-dropzone'
import { motion, AnimatePresence } from 'framer-motion'
import { Upload, FileText, CheckCircle, AlertCircle, Lock, ChevronRight } from 'lucide-react'
import toast from 'react-hot-toast'
import { uploadChat } from '../utils/api'

const STEPS = [
  'Reading file…',
  'Parsing messages…',
  'Building style profile…',
  'Generating embeddings…',
  'Storing in memory index…',
  'Ready!',
]

export default function UploadPage({ onSession }) {
  const nav = useNavigate()
  const [file,     setFile]     = useState(null)
  const [status,   setStatus]   = useState('idle') // idle | uploading | done | error
  const [step,     setStep]     = useState(0)
  const [progress, setProgress] = useState(0)
  const [result,   setResult]   = useState(null)
  const [error,    setError]    = useState('')

  const onDrop = useCallback((accepted) => {
    if (accepted[0]) { setFile(accepted[0]); setStatus('idle'); setError('') }
  }, [])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { 'text/plain': ['.txt'] },
    maxFiles: 1,
  })

  const simulateProgress = (start, end, duration, cb) => {
    let cur = start
    const inc = (end - start) / (duration / 80)
    const iv = setInterval(() => {
      cur = Math.min(cur + inc, end)
      setProgress(Math.round(cur))
      if (cur >= end) { clearInterval(iv); cb?.() }
    }, 80)
    return iv
  }

  const handleUpload = async () => {
    if (!file) return
    setStatus('uploading')
    setStep(0); setProgress(0)

    // Animate through steps while uploading
    const stepDurations = [300, 400, 600, 1200, 800, 400]
    let cumulative = 0
    stepDurations.forEach((d, i) => {
      setTimeout(() => setStep(i), cumulative)
      cumulative += d
    })

    // Real progress bar
    simulateProgress(0, 90, 3200)

    try {
      const data = await uploadChat(file)
      setProgress(100)
      setStep(5)
      setResult(data)
      setStatus('done')
      onSession(data)
      toast.success(`Loaded ${data.memory_count} memories from ${data.person_name}`)
    } catch (e) {
      setStatus('error')
      setError(e.response?.data?.detail || e.message || 'Upload failed')
      toast.error('Upload failed. Check your file and try again.')
    }
  }

  const enterApp = () => nav('/chat')

  return (
    <div className="min-h-screen bg-sand flex flex-col items-center justify-center px-4 py-12">
      {/* Header */}
      <motion.div
        className="text-center mb-10"
        initial={{ opacity: 0, y: -16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <div className="font-display text-3xl text-ember mb-1 tracking-wide">🌿 Sahara</div>
        <h1 className="font-display text-4xl md:text-5xl font-light text-dark mb-3">
          Import Memories
        </h1>
        <p className="text-mid text-sm font-light max-w-sm">
          Export your WhatsApp chat with your loved one and upload it here.
        </p>
      </motion.div>

      <motion.div
        className="w-full max-w-lg"
        initial={{ opacity: 0, y: 24 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.15 }}
      >
        {/* Privacy badge */}
        <div className="flex items-start gap-3 bg-green-50 border border-green-200
                        rounded-xl p-4 mb-5">
          <Lock size={15} className="text-green-700 mt-0.5 flex-shrink-0" />
          <p className="text-xs text-green-800 leading-relaxed">
            100% on-device processing. Your conversations are parsed locally
            and never uploaded to any cloud server.
          </p>
        </div>

        {/* How to export */}
        <div className="bg-sand-2 border border-ember/15 rounded-xl p-4 mb-5">
          <p className="text-xs font-semibold text-dark mb-1">How to export from WhatsApp:</p>
          <p className="text-xs text-mid font-mono leading-relaxed">
            Open chat → ⋮ Menu → More → Export Chat → Without Media
          </p>
        </div>

        {/* Drop zone */}
        <AnimatePresence mode="wait">
          {status === 'idle' || status === 'error' ? (
            <motion.div key="drop" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
              <div
                {...getRootProps()}
                className={`border-2 border-dashed rounded-2xl p-10 text-center cursor-pointer
                            transition-all duration-200 mb-4
                            ${isDragActive
                              ? 'border-ember bg-ember/5'
                              : file
                              ? 'border-ember/60 bg-cream'
                              : 'border-ember/25 bg-white/60 hover:border-ember/50 hover:bg-ember/3'
                            }`}
              >
                <input {...getInputProps()} />
                {file ? (
                  <div className="flex flex-col items-center gap-2">
                    <FileText size={36} className="text-ember" />
                    <p className="font-body font-semibold text-dark text-sm">{file.name}</p>
                    <p className="text-dim text-xs font-mono">{(file.size/1024).toFixed(1)} KB · ready</p>
                    <p className="text-mid text-xs mt-1 underline cursor-pointer">
                      Choose a different file
                    </p>
                  </div>
                ) : (
                  <div className="flex flex-col items-center gap-2">
                    <Upload size={36} className="text-dim" />
                    <p className="text-mid text-sm font-medium">Drop your _chat.txt here</p>
                    <p className="text-dim text-xs">or tap to browse</p>
                  </div>
                )}
              </div>

              {status === 'error' && (
                <div className="flex gap-2 bg-red-50 border border-red-200 rounded-xl p-3 mb-4">
                  <AlertCircle size={15} className="text-red-600 flex-shrink-0 mt-0.5" />
                  <p className="text-xs text-red-700">{error}</p>
                </div>
              )}

              <button
                onClick={handleUpload}
                disabled={!file}
                className={`btn-ember w-full py-4 text-base ${!file ? 'opacity-40 cursor-not-allowed' : ''}`}
              >
                Parse & Build Memory Index
              </button>
            </motion.div>
          ) : status === 'uploading' ? (
            <motion.div
              key="progress"
              className="card p-6"
              initial={{ opacity: 0, scale: 0.97 }}
              animate={{ opacity: 1, scale: 1 }}
            >
              <p className="text-sm font-semibold text-dark mb-4">{STEPS[step]}</p>
              {/* Progress bar */}
              <div className="h-1.5 bg-sand-2 rounded-full overflow-hidden mb-5">
                <motion.div
                  className="h-full bg-gradient-to-r from-ember-2 to-ember rounded-full"
                  initial={{ width: '0%' }}
                  animate={{ width: `${progress}%` }}
                  transition={{ duration: 0.3 }}
                />
              </div>
              {/* Steps */}
              <div className="space-y-2.5">
                {STEPS.slice(0, 5).map((s, i) => (
                  <div key={s} className="flex items-center gap-2.5">
                    <div className={`w-5 h-5 rounded-full flex items-center justify-center text-xs flex-shrink-0
                                    ${i < step ? 'bg-green-100 text-green-700' :
                                      i === step ? 'bg-ember/15 text-ember animate-pulse' :
                                      'bg-sand-2 text-dim'}`}>
                      {i < step ? '✓' : i === step ? '⚙' : '○'}
                    </div>
                    <span className={`text-xs ${
                      i < step ? 'text-green-700' :
                      i === step ? 'text-ember font-medium' : 'text-dim'
                    }`}>{s}</span>
                  </div>
                ))}
              </div>
            </motion.div>
          ) : (
            <motion.div
              key="done"
              className="card p-6 text-center"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
            >
              <CheckCircle size={44} className="text-ember mx-auto mb-3" />
              <h2 className="font-display text-2xl font-light text-dark mb-1">
                {result?.person_name}'s memories are ready
              </h2>
              <p className="text-mid text-sm mb-1">
                {result?.memory_count} messages indexed
              </p>
              <p className="text-dim text-xs font-mono mb-6">
                {result?.message}
              </p>
              <button onClick={enterApp} className="btn-ember w-full py-4 flex items-center justify-center gap-2">
                Begin Conversation
                <ChevronRight size={18} />
              </button>
            </motion.div>
          )}
        </AnimatePresence>

        <p className="text-center mt-6 text-xs text-dim">
          No account needed · No data stored on servers
        </p>
      </motion.div>
    </div>
  )
}
