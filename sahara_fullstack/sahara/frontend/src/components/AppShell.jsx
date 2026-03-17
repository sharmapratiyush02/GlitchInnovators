import { NavLink, useNavigate } from 'react-router-dom'
import { MessageCircle, Flower2, Trash2, LogOut, Menu, X } from 'lucide-react'
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { deleteSession } from './api'
import toast from 'react-hot-toast'

const NAV = [
  { to: '/chat',     icon: MessageCircle, label: 'Chat'     },
  { to: '/memories', icon: Flower2,       label: 'Memories' },
]

export default function AppShell({ session, onClear, children }) {
  const { person_name, session_id } = session
  const nav = useNavigate()
  const [menuOpen, setMenuOpen] = useState(false)

  const handleClear = async () => {
    if (!confirm(`Clear all of ${person_name}'s memories? This cannot be undone.`)) return
    try {
      await deleteSession(session_id)
    } catch {}
    onClear()
    nav('/')
    toast.success('Memories cleared')
  }

  const Sidebar = ({ mobile = false }) => (
    <div className={`flex flex-col bg-cream border-r border-ember/15 ${mobile ? 'w-64 h-full p-5' : 'w-64 h-screen sticky top-0 p-5'}`}>
      {/* Logo */}
      <div className="mb-6">
        <div className="font-display text-2xl text-ember tracking-wide">🌿 Sahara</div>
        <div className="text-xs text-dim font-mono mt-0.5 tracking-widest uppercase">
          Memory Companion
        </div>
      </div>

      {/* Person chip */}
      <div className="bg-ember/8 border border-ember/20 rounded-xl p-3 mb-6">
        <div className="text-xs text-dim font-mono uppercase tracking-wider mb-1">
          Remembering
        </div>
        <div className="font-display text-xl text-ember">{person_name}</div>
      </div>

      {/* Nav */}
      <nav className="flex-1 space-y-1">
        {NAV.map(({ to, icon: Icon, label }) => (
          <NavLink key={to} to={to} onClick={() => setMenuOpen(false)}>
            {({ isActive }) => (
              <div className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm
                              font-light transition-all duration-150 cursor-pointer
                              ${isActive
                                ? 'bg-ember/10 text-ember font-medium border-l-2 border-ember ml-[-2px] pl-[14px]'
                                : 'text-mid hover:bg-sand hover:text-dark'}`}>
                <Icon size={17} />
                {label}
              </div>
            )}
          </NavLink>
        ))}
      </nav>

      {/* Bottom actions */}
      <div className="space-y-2 pt-4 border-t border-ember/10 mt-4">
        <button
          onClick={handleClear}
          className="flex items-center gap-2 w-full px-3 py-2.5 rounded-xl
                     text-sm text-red-400 hover:bg-red-50 transition-all"
        >
          <Trash2 size={15} />
          Clear Memories
        </button>
        <button
          onClick={() => { onClear(); nav('/') }}
          className="flex items-center gap-2 w-full px-3 py-2.5 rounded-xl
                     text-sm text-mid hover:bg-sand transition-all"
        >
          <LogOut size={15} />
          Back to Home
        </button>
      </div>

      {/* Safety */}
      <div className="mt-4 bg-red-50 border border-red-100 rounded-xl p-3">
        <p className="text-xs text-red-600 font-semibold mb-1">In crisis?</p>
        <p className="text-xs text-red-700">
          iCall: <a href="tel:9152987821" className="font-mono font-bold">9152987821</a>
        </p>
      </div>
    </div>
  )

  return (
    <div className="flex min-h-screen bg-sand">
      {/* Desktop sidebar */}
      <div className="hidden md:flex">
        <Sidebar />
      </div>

      {/* Mobile header */}
      <div className="md:hidden fixed top-0 left-0 right-0 z-50 bg-cream border-b border-ember/15
                      flex items-center justify-between px-4 py-3">
        <div className="font-display text-xl text-ember">🌿 {person_name}</div>
        <button onClick={() => setMenuOpen(v => !v)} className="text-mid p-1">
          {menuOpen ? <X size={22} /> : <Menu size={22} />}
        </button>
      </div>

      {/* Mobile drawer */}
      <AnimatePresence>
        {menuOpen && (
          <motion.div
            className="md:hidden fixed inset-0 z-40 flex"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="absolute inset-0 bg-dark/40" onClick={() => setMenuOpen(false)} />
            <motion.div
              className="relative z-10 h-full"
              initial={{ x: -260 }}
              animate={{ x: 0 }}
              exit={{ x: -260 }}
              transition={{ type: 'spring', damping: 25, stiffness: 200 }}
            >
              <Sidebar mobile />
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main */}
      <div className="flex-1 flex flex-col min-w-0 md:mt-0 mt-14">
        {/* Top bar */}
        <div className="hidden md:flex items-center justify-between px-6 py-3.5
                        bg-cream border-b border-ember/15 sticky top-0 z-10">
          <div className="font-display text-lg font-light text-dark">
            Talking with {person_name}
          </div>
          <div className="flex items-center gap-3">
            <span className="text-xs font-mono text-dim bg-sand px-3 py-1 rounded-full border border-ember/15">
              🔒 On-device
            </span>
          </div>
        </div>

        {children}
      </div>
    </div>
  )
}
