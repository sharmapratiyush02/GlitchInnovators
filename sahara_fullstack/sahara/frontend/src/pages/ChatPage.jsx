import { useState, useRef, useEffect, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Send, Mic, MicOff, AlertTriangle, Info } from 'lucide-react'
import toast from 'react-hot-toast'
import { sendMessage } from './api'

const HELPLINES = [
  { name: 'iCall',       number: '9152987821' },
  { name: 'AASRA',       number: '9820466726' },
  { name: 'Vandrevala',  number: '9999666555' },
]

const WELCOME = (name) => `${name ? name + ' is here.' : 'I\'m here.'}

Tell me what\'s on your heart. I\'m listening.`

export default function ChatPage({ session }) {
  const { session_id, person_name } = session

  const [messages,  setMessages]  = useState([
    { id: 0, role: 'ai', text: WELCOME(person_name), time: new Date() }
  ])
  const [input,     setInput]     = useState('')
  const [loading,   setLoading]   = useState(false)
  const [recording, setRecording] = useState(false)
  const [crisis,    setCrisis]    = useState(false)

  const bottomRef   = useRef(null)
  const inputRef    = useRef(null)
  const mediaRef    = useRef(null)
  const chunksRef   = useRef([])
  const waveRef     = useRef(null)
  const analyserRef = useRef(null)
  const rafRef      = useRef(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, loading])

  const addMsg = (role, text) => {
    setMessages(prev => [...prev, { id: Date.now(), role, text, time: new Date() }])
  }

  const send = async (text) => {
    const t = (text || input).trim()
    if (!t || loading) return
    setInput('')
    inputRef.current && (inputRef.current.style.height = 'auto')
    addMsg('user', t)
    setLoading(true)

    try {
      const res = await sendMessage(t, session_id)
      if (res.is_crisis) setCrisis(true)
      addMsg('ai', res.reply)
    } catch (e) {
      addMsg('ai', `Something went gently wrong. Please try again.\n\n— ${person_name}`)
      toast.error('Connection issue. Is the backend running?')
    } finally {
      setLoading(false)
    }
  }

  const handleKey = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send() }
  }

  const autoResize = (e) => {
    e.target.style.height = 'auto'
    e.target.style.height = Math.min(e.target.scrollHeight, 130) + 'px'
  }

  // ── Voice recording ──────────────────────────────────────
  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      chunksRef.current = []
      const mr = new MediaRecorder(stream)
      mediaRef.current = mr
      mr.ondataavailable = (e) => chunksRef.current.push(e.data)
      mr.onstop = () => {
        stream.getTracks().forEach(t => t.stop())
        cancelAnimationFrame(rafRef.current)
        // Simulate transcription in demo (in prod: send to Whisper/Vosk)
        const demos = [
          'I miss you so much today',
          'I was thinking about you this morning',
          'I wish you were here',
          'I feel very low today',
        ]
        const t = demos[Math.floor(Math.random() * demos.length)]
        setInput(t)
        inputRef.current?.focus()
      }
      mr.start()
      setRecording(true)

      // Waveform
      const ac = new AudioContext()
      const src = ac.createMediaStreamSource(stream)
      const an = ac.createAnalyser(); an.fftSize = 64
      src.connect(an)
      analyserRef.current = an
      const data = new Uint8Array(an.frequencyBinCount)
      const canvas = waveRef.current
      if (canvas) {
        const ctx = canvas.getContext('2d')
        canvas.width = canvas.offsetWidth * 2
        canvas.height = canvas.offsetHeight * 2
        const draw = () => {
          rafRef.current = requestAnimationFrame(draw)
          an.getByteFrequencyData(data)
          ctx.clearRect(0, 0, canvas.width, canvas.height)
          const bw = canvas.width / data.length
          data.forEach((v, i) => {
            const h = (v / 255) * canvas.height
            ctx.fillStyle = `hsla(${24 + i * 2}, 60%, 54%, 0.75)`
            ctx.fillRect(i * bw, canvas.height - h, Math.max(bw - 2, 1), h)
          })
        }
        draw()
      }
    } catch (e) {
      toast.error('Microphone access denied')
    }
  }

  const stopRecording = () => {
    mediaRef.current?.stop()
    setRecording(false)
  }

  const formatTime = (d) => {
    const h = d.getHours() % 12 || 12
    const m = String(d.getMinutes()).padStart(2, '0')
    return `${h}:${m} ${d.getHours() >= 12 ? 'PM' : 'AM'}`
  }

  return (
    <div className="flex flex-col h-[calc(100vh-64px)]">

      {/* Crisis Banner */}
      <AnimatePresence>
        {crisis && (
          <motion.div
            className="bg-red-50 border-b border-red-200 px-5 py-3 flex gap-3"
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
          >
            <AlertTriangle size={16} className="text-red-600 flex-shrink-0 mt-0.5" />
            <div className="text-xs text-red-800 leading-relaxed">
              <strong>We're concerned about you.</strong>{' '}
              {HELPLINES.map(h => `${h.name}: ${h.number}`).join(' · ')}
            </div>
            <button onClick={() => setCrisis(false)} className="ml-auto text-red-400 text-xs">✕</button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 md:px-6 py-5 space-y-4">
        <AnimatePresence initial={false}>
          {messages.map((msg) => (
            <motion.div
              key={msg.id}
              className={`flex gap-3 ${msg.role === 'user' ? 'flex-row-reverse' : ''}`}
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3 }}
            >
              {/* Avatar */}
              <div className={`w-9 h-9 rounded-full flex-shrink-0 flex items-center justify-center
                              text-sm font-semibold
                              ${msg.role === 'ai'
                                ? 'bg-ember text-white'
                                : 'bg-ember/15 text-ember border border-ember/25'}`}>
                {msg.role === 'ai' ? person_name?.[0] || 'S' : 'Y'}
              </div>

              <div className={`max-w-[75%] ${msg.role === 'user' ? 'items-end' : 'items-start'} flex flex-col`}>
                <div className={`rounded-2xl px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap
                                ${msg.role === 'ai'
                                  ? 'bg-sand-2 text-dark rounded-tl-sm'
                                  : 'bg-ember text-white rounded-tr-sm'}`}
                     dangerouslySetInnerHTML={{
                       __html: msg.text
                         .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
                         .replace(/\*([^*]+)\*/g,'<em>$1</em>')
                         .replace(/— \*(.*?)\*/g,'<span style="font-size:0.72rem;opacity:0.6">— $1</span>')
                     }}
                />
                <span className="text-xs text-dim mt-1 font-mono">{formatTime(msg.time)}</span>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>

        {/* Typing indicator */}
        {loading && (
          <motion.div
            className="flex gap-3"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <div className="w-9 h-9 rounded-full bg-ember flex items-center justify-center
                            text-sm font-semibold text-white flex-shrink-0">
              {person_name?.[0] || 'S'}
            </div>
            <div className="bg-sand-2 rounded-2xl rounded-tl-sm px-4 py-3.5 flex gap-1.5 items-center">
              {[0,1,2].map(i => (
                <div key={i} className="typing-dot w-2 h-2 bg-ember/50 rounded-full" />
              ))}
            </div>
          </motion.div>
        )}

        <div ref={bottomRef} />
      </div>

      {/* Input area */}
      <div className="border-t border-ember/15 bg-cream px-4 md:px-6 py-4">
        {/* Waveform */}
        <canvas
          ref={waveRef}
          className={`w-full h-10 rounded-lg bg-sand mb-3 transition-opacity duration-300
                      ${recording ? 'opacity-100' : 'opacity-0 h-0 mb-0'}`}
        />

        <div className="flex gap-3 items-end">
          {/* Voice btn */}
          <button
            onClick={recording ? stopRecording : startRecording}
            className={`w-11 h-11 rounded-full flex-shrink-0 flex items-center justify-center
                        transition-all duration-200
                        ${recording
                          ? 'bg-red-500 text-white animate-pulse-glow'
                          : 'bg-ember/15 text-ember hover:bg-ember/25'}`}
          >
            {recording ? <MicOff size={18} /> : <Mic size={18} />}
          </button>

          {/* Text input */}
          <div className="flex-1 bg-sand border border-ember/20 rounded-2xl px-4 py-3
                          focus-within:border-ember focus-within:shadow-[0_0_0_3px_rgba(181,101,42,0.1)]
                          transition-all duration-200 flex items-end gap-2">
            <textarea
              ref={inputRef}
              value={input}
              onChange={(e) => { setInput(e.target.value); autoResize(e) }}
              onKeyDown={handleKey}
              rows={1}
              placeholder={`Talk to ${person_name || 'them'}…`}
              className="flex-1 bg-transparent outline-none text-dark text-sm font-light
                         resize-none max-h-32 leading-relaxed placeholder:text-dim"
            />
          </div>

          {/* Send btn */}
          <button
            onClick={() => send()}
            disabled={!input.trim() || loading}
            className={`w-11 h-11 rounded-full flex-shrink-0 flex items-center justify-center
                        transition-all duration-200
                        ${input.trim() && !loading
                          ? 'bg-ember text-white hover:bg-ember-3 hover:-translate-y-0.5'
                          : 'bg-ember/20 text-dim cursor-not-allowed'}`}
          >
            <Send size={17} />
          </button>
        </div>

        <p className="text-center mt-3 text-xs text-dim">
          Sahara is recalling {person_name}'s words · Not a therapist · In crisis:{' '}
          <a href="tel:9152987821" className="underline">iCall 9152987821</a>
        </p>
      </div>
    </div>
  )
}
