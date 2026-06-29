import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@17.7.0?target=deno'

const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')
const stripeWebhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
  Deno.env.get('SERVICE_ROLE_KEY')

Deno.serve(async (req) => {
  try {
    if (!stripeSecretKey) {
      throw new Error('Missing STRIPE_SECRET_KEY')
    }
    if (!stripeWebhookSecret) {
      throw new Error('Missing STRIPE_WEBHOOK_SECRET')
    }
    if (!serviceRoleKey) {
      throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY')
    }

    const signature = req.headers.get('stripe-signature')
    if (!signature) {
      return new Response('Missing stripe-signature', { status: 400 })
    }

    const body = await req.text()
    const stripe = new Stripe(stripeSecretKey, {
      apiVersion: '2024-12-18.acacia',
    })

    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      stripeWebhookSecret,
    )

    if (event.type === 'payment_intent.succeeded') {
      const paymentIntent = event.data.object as Stripe.PaymentIntent
      const orderId = paymentIntent.metadata?.orderId

      if (orderId) {
        const supabase = createClient(
          Deno.env.get('SUPABASE_URL')!,
          serviceRoleKey,
        )

        await supabase
          .from('orders')
          .update({
            status: 'paid',
            stripe_payment_intent_id: paymentIntent.id,
          })
          .eq('id', orderId)
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
