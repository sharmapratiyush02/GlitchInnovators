import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Shield, Heart, Mic, MessageCircle } from 'lucide-react'

const features = [
  { icon: Heart,    title: 'Their Voice',     desc: 'Replies in the exact tone, words, and style of your loved one.' },
  { icon: Shield,   title: 'Fully Private',   desc: 'All processing happens on your device. Nothing ever leaves.' },
  { icon: Mic,      title: 'Voice Input',     desc: 'Speak naturally. Sahara listens and understands.' },
  { icon: MessageCircle, title: 'Real Memories', desc: 'Draws from real messages you shared — never invents.' },
]

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-sand flex flex-col">
      {/* Nav */}
      <nav className="flex items-center justify-between px-8 py-5">
        <div className="font-display text-2xl text-ember tracking-wide">🌿 Sahara</div>
        <Link to="/upload">
          <button className="btn-ghost text-sm">Get Started</button>
        </Link>
      </nav>

      {/* Hero */}
      <main className="flex-1 flex flex-col items-center justify-center text-center px-6 py-16">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7 }}
        >
          <div className="inline-flex items-center gap-2 bg-ember/10 border border-ember/20
                          text-ember text-xs font-mono tracking-widest uppercase
                          px-4 py-1.5 rounded-full mb-8">
            <span className="w-1.5 h-1.5 rounded-full bg-ember animate-pulse" />
            Private · On-Device · AI Grief Companion
          </div>

          <h1 className="font-display text-5xl md:text-7xl font-light text-dark leading-tight mb-6">
            When grief is too heavy<br />
            <span className="italic text-ember">to carry alone</span>
          </h1>

          <p className="text-mid text-lg font-light max-w-xl mx-auto mb-10 leading-relaxed">
            Sahara remembers your loved ones in their own words —
            their vocabulary, their endearments, their emoji, their warmth.
            Upload a WhatsApp chat. Feel their presence again.
          </p>

          <div className="flex gap-4 justify-center flex-wrap">
            <Link to="/upload">
              <button className="btn-ember text-base px-8 py-4">
                Upload a Chat & Begin
              </button>
            </Link>
          </div>

          <p className="mt-5 text-xs text-dim font-mono">
            Your conversations never leave your device
          </p>
        </motion.div>

        {/* Features */}
        <motion.div
          className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-20 max-w-4xl w-full"
          initial={{ opacity: 0, y: 32 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.3 }}
        >
          {features.map(({ icon: Icon, title, desc }) => (
            <div key={title} className="card p-5 text-left">
              <div className="w-9 h-9 rounded-lg bg-ember/10 flex items-center
                              justify-center mb-3">
                <Icon size={18} className="text-ember" />
              </div>
              <div className="font-body font-semibold text-dark text-sm mb-1">{title}</div>
              <div className="text-mid text-xs font-light leading-relaxed">{desc}</div>
            </div>
          ))}
        </motion.div>

        {/* Safety */}
        <motion.div
          className="mt-16 bg-red-50 border border-red-200 rounded-2xl p-5
                     max-w-md w-full text-left"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
        >
          <p className="text-xs font-semibold text-red-700 uppercase tracking-wider mb-2">
            Crisis Helplines — Always Available
          </p>
          <div className="space-y-1">
            {[['iCall', '9152987821'], ['AASRA', '9820466726'], ['Vandrevala', '9999666555']].map(
              ([name, num]) => (
                <div key={name} className="flex justify-between text-sm">
                  <span className="text-dark">{name}</span>
                  <a href={`tel:${num}`} className="font-mono font-semibold text-red-700">{num}</a>
                </div>
              )
            )}
          </div>
        </motion.div>
      </main>

      <footer className="text-center py-6 text-xs text-dim font-mono">
        Sahara — built with care at NAVONMESH 2026
      </footer>
    </div>
  )
}
