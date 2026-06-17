import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const MEDIACLIP_AUTH_HEADER = Deno.env.get('MEDIACLIP_AUTH_HEADER') ??
  'HubApi bWVsbG9zbmFwOjEubVM3c2dJZ253WkJSK2kraEFnZHg2anJuYUZ0WXFKMXZoRSszNXUwNC92VUVoQT09'
const MEDIACLIP_STORE_ID = Deno.env.get('MEDIACLIP_STORE_ID') ?? 'mellosnap'
const MEDIACLIP_REGION = Deno.env.get('MEDIACLIP_REGION') ?? 'eastus'
const BASE_API = `https://api.${MEDIACLIP_REGION}.mediacliphub.com`
const BASE_UPLOADS = `https://uploads.${MEDIACLIP_REGION}.mediacliphub.com`
const BASE_PHOTOS = `https://photos.${MEDIACLIP_REGION}.mediacliphub.com`
const BASE_ECB = `https://ecb.mediacliphub.com`

const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
  Deno.env.get('SERVICE_ROLE_KEY')

const log = (step: string, message: string, extra?: unknown) => {
  const suffix = extra !== undefined ? ` ${JSON.stringify(extra)}` : ''
  console.log(`[MelloSnap][${step}] ${message}${suffix}`)
}

function productIdForFormat(format: string): string {
  switch (format) {
    case 'standard':
      return '$(package:mediaclip/print)/products/print-4x6-matte'
    case 'polaroid':
      return '$(package:mediaclip/print)/products/print-5x7-metallic'
    case 'strip':
      return '$(package:mediaclip/print)/products/print-8x10-metallic'
    default:
      return '$(package:mediaclip/print)/products/print-4x6-matte'
  }
}

Deno.serve(async (req) => {
  let projectId: string | undefined

  try {
    if (!serviceRoleKey) {
      throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY or SERVICE_ROLE_KEY')
    }

    log('START', 'process-mediaclip-order invoked')

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      serviceRoleKey,
    )

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      log('AUTH', 'Missing Authorization header')
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
      log('AUTH', 'Supabase user invalid', { authError: authError?.message })
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }
    log('AUTH', 'Supabase user OK', { userId: user.id })

    const { rollId, format, amount, orderId } = await req.json()
    log('INPUT', 'Request body', { rollId, format, amount, orderId })

    // STEP 1 — Mediaclip user token (JWT)
    log('STEP-1', 'Requesting Mediaclip JWT')
    const tokenRes = await fetch(`${BASE_API}/auth/jwt`, {
      method: 'POST',
      headers: {
        'Authorization': MEDIACLIP_AUTH_HEADER,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        storeData: { userId: user.id },
      }),
    })
    if (!tokenRes.ok) {
      const err = await tokenRes.text()
      log('STEP-1', 'JWT failed', { status: tokenRes.status, err })
      throw new Error(`User token failed: ${err}`)
    }
    const tokenData = await tokenRes.json()
    const userToken = tokenData.token as string
    const hubUserId = tokenData.userId as string
    log('STEP-1', 'JWT OK', { hubUserId })

    // STEP 2 — Upload photos from Supabase Storage to Mediaclip
    log('STEP-2', 'Uploading photos from Storage')
    const photoUrns: string[] = []

    for (let i = 1; i <= 24; i++) {
      const path = `${user.id}/${rollId}/${i}.jpg`
      const { data: photoBlob, error: downloadError } = await supabase.storage
        .from('rolls')
        .download(path)

      if (downloadError || !photoBlob) {
        log('STEP-2', `Photo ${i} missing in Storage`, {
          path,
          downloadError: downloadError?.message,
        })
        continue
      }

      const photoBytes = await photoBlob.arrayBuffer()
      log('STEP-2', `Uploading photo ${i}`, {
        path,
        bytes: photoBytes.byteLength,
      })

      const uploadRes = await fetch(
        `${BASE_UPLOADS}/stores/${MEDIACLIP_STORE_ID}/users/${hubUserId}/sources/uploads/photos?async=true&originalFilename=${i}.jpg`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${userToken}`,
            'Content-Type': 'image/jpeg',
          },
          body: photoBytes,
        },
      )
      if (!uploadRes.ok) {
        const err = await uploadRes.text()
        log('STEP-2', `Upload photo ${i} failed`, {
          status: uploadRes.status,
          err,
        })
        throw new Error(`Upload photo ${i} failed: ${err}`)
      }
      const uploadData = await uploadRes.json()
      photoUrns.push(uploadData.photoId)
      log('STEP-2', `Photo ${i} uploaded`, { photoId: uploadData.photoId })
    }

    if (photoUrns.length === 0) {
      log('STEP-2', 'No photos uploaded')
      throw new Error(
        'No photos found in storage. Upload your roll photos before checkout.',
      )
    }
    log('STEP-2', 'Upload complete', { count: photoUrns.length })

    // STEP 3 — Wait for all photos to be Done
    log('STEP-3', 'Waiting for photo processing')
    for (let idx = 0; idx < photoUrns.length; idx++) {
      const urn = photoUrns[idx]
      let ready = false
      let attempt = 1

      while (!ready) {
        const statusRes = await fetch(
          `${BASE_PHOTOS}/photos/${
            encodeURIComponent(urn)
          }/pendingStatus?attempt=${attempt}`,
          { headers: { 'Authorization': `Bearer ${userToken}` } },
        )

        if (statusRes.status === 404) {
          log('STEP-3', `Photo ${idx + 1} status 404`, { urn })
          throw new Error(`Photo status check failed for ${urn}`)
        }
        if (!statusRes.ok) {
          const err = await statusRes.text()
          log('STEP-3', `Photo ${idx + 1} status error`, {
            status: statusRes.status,
            err,
            urn,
          })
          throw new Error(`Photo status check failed: ${err}`)
        }

        const statusData = await statusRes.json()
        log('STEP-3', `Photo ${idx + 1} status`, {
          urn,
          status: statusData.status,
          attempt,
          remaining: statusData.remaining,
        })

        if (statusData.status === 'Done') {
          ready = true
        } else if (statusData.status === 'Error') {
          throw new Error(`Photo processing error for ${urn}`)
        } else {
          const waitMs = statusData.remaining || 1000
          await new Promise((r) => setTimeout(r, waitMs))
          attempt++
        }
      }
    }
    log('STEP-3', 'All photos Done')

    // STEP 4 — Create Mediaclip project (autofill with photo URNs)
    const productId = productIdForFormat(format)
    log('STEP-4', 'Creating project', { productId, photoCount: photoUrns.length })

    const projectRes = await fetch(`${BASE_API}/projects`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${userToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        designerData: {
          module: 'Print',
          productId,
          photos: photoUrns,
        },
      }),
    })
    if (!projectRes.ok) {
      const err = await projectRes.text()
      log('STEP-4', 'Create project failed', { status: projectRes.status, err })
      throw new Error(`Failed to create project: ${err}`)
    }
    const projectJson = await projectRes.json()
    projectId = projectJson.id as string
    log('STEP-4', 'Project created', { projectId })

    // STEP 5 — Add to cart (skip designer)
    log('STEP-5', 'Adding project to cart', { projectId })
    const addToCartRes = await fetch(
      `${BASE_ECB}/addtocart?data-storeId=${MEDIACLIP_STORE_ID}&data-projectId=${projectId}&module=Print`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${userToken}`,
          'Content-Type': 'application/json',
        },
      },
    )
    if (!addToCartRes.ok) {
      const err = await addToCartRes.text()
      log('STEP-5', 'Add to cart failed', { status: addToCartRes.status, err })
      throw new Error(`Failed to add to cart: ${err}`)
    }
    log('STEP-5', 'Add to cart OK')

    // STEP 6 — Load profile for shipping
    log('STEP-6', 'Loading profile')
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()

    if (profileError) {
      log('STEP-6', 'Profile load warning', {
        profileError: profileError.message,
      })
    } else {
      log('STEP-6', 'Profile loaded', {
        name: profile?.name,
        city: profile?.city,
        province: profile?.province,
      })
    }

    // STEP 7 — Create Mediaclip order with release=false
    log('STEP-7', 'Creating Mediaclip order', { orderId, projectId, amount })
    const createOrderRes = await fetch(
      `${BASE_API}/stores/${MEDIACLIP_STORE_ID}/orders?release=false`,
      {
        method: 'POST',
        headers: {
          'Authorization': MEDIACLIP_AUTH_HEADER,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          orderRequestHeader: {
            orderID: orderId,
            orderDate: new Date().toISOString(),
            shipTo: {
              address: {
                postalAddress: {
                  deliverTo: profile?.name || user.email,
                  street: profile?.address || '',
                  city: profile?.city || '',
                  state: profile?.province || 'Québec',
                  postalCode: profile?.postal_code || '',
                  country: {
                    isoCountryCode: 'CA',
                    value: 'Canada',
                  },
                },
                email: { value: user.email },
              },
            },
            contacts: [
              {
                role: 'buyer',
                idReference: [
                  {
                    identifier: user.id,
                    domain: 'storeUserId',
                  },
                ],
              },
            ],
            shipping: {
              money: {
                currency: 'CAD',
                value: 0,
              },
              description: {
                value: 'Standard shipping',
              },
            },
          },
          itemOut: [
            {
              lineNumber: 1,
              lineId: `${orderId}-1`,
              itemId: {
                buyerPartId: format,
                supplierPartAuxiliaryId: projectId,
              },
              quantity: 1,
              itemDetail: {
                price: {
                  currency: 'CAD',
                  originalLinePrice: amount,
                  finalLinePrice: amount,
                },
                description: {
                  value: `MelloSnap ${format} prints`,
                },
              },
            },
          ],
        }),
      },
    )

    if (!createOrderRes.ok) {
      const err = await createOrderRes.text()
      log('STEP-7', 'Create order failed', {
        status: createOrderRes.status,
        err,
        projectId,
      })
      throw new Error(`Failed to create order: ${err}`)
    }

    const orderData = await createOrderRes.json()
    const hubOrderId = orderData.id as string
    log('STEP-7', 'Hub order created', { hubOrderId })

    // STEP 8 — Save to Supabase (projectId server-side only)
    log('STEP-8', 'Updating Supabase order')
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        mediaclip_order_id: hubOrderId,
        mediaclip_project_id: projectId,
        status: 'waiting_payment',
      })
      .eq('id', orderId)

    if (updateError) {
      log('STEP-8', 'Supabase update failed', {
        updateError: updateError.message,
      })
      throw new Error(`Supabase update failed: ${updateError.message}`)
    }
    log('STEP-8', 'Supabase order updated', {
      orderId,
      hubOrderId,
      projectId,
    })

    log('DONE', 'Success')
    return new Response(
      JSON.stringify({
        success: true,
        hubOrderId,
        message: 'Order created and waiting for payment release',
      }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    log('ERROR', message, { projectId: projectId ?? null })
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
