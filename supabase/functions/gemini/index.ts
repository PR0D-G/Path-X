import { serve } from "https://deno.land/std/http/server.ts"

const headers = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, x-client-info, apikey",
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers })
  }

  try {
    const { prompt, contents } = await req.json()
    const apiKey = Deno.env.get("GEMINI_API_KEY")

    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY is not set on the server" }),
        { status: 500, headers }
      )
    }

    // Use provided contents if available (for complex multi-part requests),
    // otherwise build from prompt.
    const body = contents ? { contents } : {
      contents: [
        {
          parts: [{ text: prompt }]
        }
      ]
    }

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(body)
      }
    )

    const data = await response.json()
    
    if (data.error) {
      return new Response(JSON.stringify(data), { status: response.status, headers })
    }

    // If it was a simple prompt request, return the text directly (as in the user's example)
    // Otherwise return the full Gemini response.
    if (prompt && !contents) {
      return new Response(
        JSON.stringify({
          response: data.candidates?.[0]?.content?.parts?.[0]?.text || "No response content"
        }),
        { headers }
      )
    }

    return new Response(JSON.stringify(data), { headers })

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers }
    )
  }
})
