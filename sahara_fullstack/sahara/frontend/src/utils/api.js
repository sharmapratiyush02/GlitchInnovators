import axios from 'axios'

const BASE = import.meta.env.VITE_API_URL || '/api'

const api = axios.create({
  baseURL: BASE,
  timeout: 30000,
})

export const uploadChat = async (file) => {
  const form = new FormData()
  form.append('file', file)
  const { data } = await api.post('/upload', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
  return data
}

export const sendMessage = async (message, sessionId) => {
  const { data } = await api.post('/chat', {
    message,
    session_id: sessionId,
  })
  return data
}

export const getSession = async (sessionId) => {
  const { data } = await api.get(`/session/${sessionId}`)
  return data
}

export const getMemories = async (sessionId, search = '') => {
  const { data } = await api.get(`/memories/${sessionId}`, {
    params: search ? { search } : {},
  })
  return data.memories || []
}

export const deleteSession = async (sessionId) => {
  await api.delete(`/session/${sessionId}`)
}

export const checkHealth = async () => {
  const { data } = await api.get('/health')
  return data
}
