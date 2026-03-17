import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Search, Heart, Calendar } from 'lucide-react'
import { getMemories } from './api'

export default function MemoriesPage({ session }) {
  const { session_id, person_name } = session
  const [memories, setMemories] = useState([])
  const [search,   setSearch]   = useState('')
  const [loading,  setLoading]  = useState(true)

  const load = async (q = '') => {
    setLoading(true)
    try {
      const mems = await getMemories(session_id, q)
      setMemories(mems)
    } catch(e) {
      setMemories([])
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  const handleSearch = (e) => {
    const v = e.target.value
    setSearch(v)
    const t = setTimeout(() => load(v), 400)
    return () => clearTimeout(t)
  }

  return (
    <div className="flex-1 overflow-y-auto p-5 md:p-7">
      <div className="mb-6">
        <h2 className="font-display text-3xl font-light text-dark mb-1">
          {person_name}'s Memories
        </h2>
        <p className="text-mid text-sm font-light">
          {memories.length} messages semantically indexed
        </p>
      </div>

      {/* Search */}
      <div className="flex items-center gap-2 bg-white border border-ember/20 rounded-xl
                      px-4 py-3 mb-6 focus-within:border-ember transition-all">
        <Search size={16} className="text-dim flex-shrink-0" />
        <input
          type="text"
          value={search}
          onChange={handleSearch}
          placeholder="Search memories…"
          className="flex-1 bg-transparent outline-none text-dark text-sm font-light
                     placeholder:text-dim"
        />
      </div>

      {/* Grid */}
      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="card p-4 animate-pulse h-32" />
          ))}
        </div>
      ) : memories.length === 0 ? (
        <div className="text-center py-16 text-dim">
          <Heart size={32} className="mx-auto mb-3 opacity-30" />
          <p className="text-sm">
            {search ? 'No memories match your search.' : 'No memories yet.'}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {memories.map((m, i) => (
            <motion.div
              key={i}
              className="card p-4 cursor-pointer hover:-translate-y-1 hover:shadow-md
                         transition-all duration-200 border-l-[3px] border-l-ember/40"
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.04 }}
            >
              <div className="flex items-center gap-2 mb-2">
                <span className="text-xs font-mono text-ember">{m.sender}</span>
                {m.date && (
                  <span className="flex items-center gap-1 text-xs text-dim font-mono ml-auto">
                    <Calendar size={10} />
                    {m.date}
                  </span>
                )}
              </div>
              <p className="text-sm text-dark font-light leading-relaxed line-clamp-3">
                {m.text}
              </p>
              {m.score > 0 && (
                <div className="mt-3 flex items-center gap-2">
                  <div className="flex-1 h-1 bg-sand-2 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-ember/40 to-ember rounded-full"
                      style={{ width: `${Math.round(m.score * 100)}%` }}
                    />
                  </div>
                  <span className="text-xs text-dim font-mono">{m.score.toFixed(2)}</span>
                </div>
              )}
            </motion.div>
          ))}
        </div>
      )}
    </div>
  )
}
