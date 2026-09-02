import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm'

const SUPABASE_URL = 'https://mnlolmyxvnjwycbusnky.supabase.co'
const SUPABASE_KEY = 'sb_publishable_Xf_wFAH_REGOvr8M0yjLVQ_dYmO7NOT'

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

document.addEventListener("DOMContentLoaded", () => {
  cargarSenales()
  suscripcionRealtime()
})

async function cargarSenales() {
  const tablaCuerpo = document.getElementById('signals-table-body')
  if (!tablaCuerpo) return

  const { data: signals, error } = await supabase
    .from('signals')
    .select('*')
    .order('id', { ascending: false })

  if (error) {
    console.error('Error cargando señales de Supabase:', error)
    return
  }

  renderizarTabla(signals)
}

function renderizarTabla(signals) {
  const tablaCuerpo = document.getElementById('signals-table-body')
  if (!tablaCuerpo) return
  
  tablaCuerpo.innerHTML = ''
  
  if (!signals || signals.length === 0) {
    tablaCuerpo.innerHTML = `<tr><td colspan="6" style="text-align: center; color: #888; padding: 15px;">No hay operaciones activas o registradas</td></tr>`
    return
  }

  signals.forEach(sig => {
    const fila = document.createElement('tr')
    const esCompra = sig.action === 'BUY'
    const colorAccion = esCompra ? '#22c55e' : '#ef4444'
    const colorProfit = (sig.profit >= 0) ? '#22c55e' : '#ef4444'

    fila.innerHTML = `
      <td style="padding: 10px; border-bottom: 1px solid #333;">${sig.ticket}</td>
      <td style="padding: 10px; border-bottom: 1px solid #333; font-weight: bold;">${sig.symbol}</td>
      <td style="padding: 10px; border-bottom: 1px solid #333; color: ${colorAccion}; font-weight: bold;">${sig.action}</td>
      <td style="padding: 10px; border-bottom: 1px solid #333;">${sig.volume}</td>
      <td style="padding: 10px; border-bottom: 1px solid #333;">${sig.price}</td>
      <td style="padding: 10px; border-bottom: 1px solid #333; color: ${colorProfit}; font-weight: bold;">${sig.profit !== null ? sig.profit.toFixed(2) : '0.00'}</td>
    `
    tablaCuerpo.appendChild(fila)
  })
}

function suscripcionRealtime() {
  supabase
    .channel('public:signals')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'signals' }, payload => {
      console.log('Cambio detectado en tiempo real:', payload)
      cargarSenales()
    })
    .subscribe()
  }
