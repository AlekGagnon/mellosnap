import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
  Deno.env.get('SERVICE_ROLE_KEY')

Deno.serve(async (req) => {
  try {
    if (!stripeSecretKey) {
      throw new Error('Missing STRIPE_SECRET_KEY')
    }
    if (!serviceRoleKey) {
      throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY')
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      serviceRoleKey,
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(
      token,
    )
    if (!user || authError) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { orderId } = await req.json()
    if (!orderId || typeof orderId !== 'string') {
      return new Response(JSON.stringify({ error: 'orderId is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('id, user_id, roll_id, amount, status, stripe_payment_intent_id')
      .eq('id', orderId)
      .maybeSingle()

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: 'Order not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    if (order.user_id !== user.id) {
      return new Response(JSON.stringify({ error: 'Forbidden' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    if (order.status === 'paid' || order.status === 'printing') {
      return new Response(
        JSON.stringify({ error: 'Order is already paid' }),
        { status: 409, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const amountCad = Number(order.amount)
    if (!Number.isFinite(amountCad) || amountCad <= 0) {
      throw new Error('Invalid order amount')
    }

    const amountCents = Math.round(amountCad * 100)

    // Reuse an existing open PaymentIntent when possible.
    if (order.stripe_payment_intent_id) {
      const existingRes = await fetch(
        `https://api.stripe.com/v1/payment_intents/${order.stripe_payment_intent_id}`,
        {
          headers: { Authorization: `Bearer ${stripeSecretKey}` },
        },
      )
      if (existingRes.ok) {
        const existing = await existingRes.json()
        if (
          existing.status === 'requires_payment_method' ||
          existing.status === 'requires_confirmation' ||
          existing.status === 'requires_action'
        ) {
          return new Response(
            JSON.stringify({
              clientSecret: existing.client_secret,
              paymentIntentId: existing.id,
            }),
            { headers: { 'Content-Type': 'application/json' } },
          )
        }
      }
    }

    const params = new URLSearchParams({
      amount: String(amountCents),
      currency: 'cad',
      'automatic_payment_methods[enabled]': 'true',
      'metadata[orderId]': orderId,
      'metadata[userId]': user.id,
      'metadata[rollId]': String(order.roll_id),
    })

    const intentRes = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeSecretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    })

    const intent = await intentRes.json()
    if (!intentRes.ok) {
      throw new Error(intent.error?.message ?? 'Stripe PaymentIntent failed')
    }

    await supabase
      .from('orders')
      .update({ stripe_payment_intent_id: intent.id })
      .eq('id', orderId)

    return new Response(
      JSON.stringify({
        clientSecret: intent.client_secret,
        paymentIntentId: intent.id,
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
