import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const MEDIACLIP_AUTH_HEADER = Deno.env.get('MEDIACLIP_AUTH_HEADER') ??
  'HubApi bWVsbG9zbmFwOjEubVM3c2dJZ253WkJSK2kraEFnZHg2anJuYUZ0WXFKMXZoRSszNXUwNC92VUVoQT09'
const MEDIACLIP_REGION = Deno.env.get('MEDIACLIP_REGION') ?? 'eastus'

Deno.serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SERVICE_ROLE_KEY')!,
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
      })
    }
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      token,
    )
    if (!user || authError) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
      })
    }

    const { hubOrderId, orderId } = await req.json()

    const releaseRes = await fetch(
      `https://api.${MEDIACLIP_REGION}.mediacliphub.com/orders/${hubOrderId}/status`,
      {
        method: 'PUT',
        headers: {
          'Authorization': MEDIACLIP_AUTH_HEADER,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ value: 'Released' }),
      },
    )

    if (!releaseRes.ok) {
      const err = await releaseRes.text()
      throw new Error(`Failed to release order: ${err}`)
    }

    await supabase
      .from('orders')
      .update({ status: 'printing' })
      .eq('id', orderId)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Order released — printing started',
      }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
