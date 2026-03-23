// Supabase Edge Function: send-push
// Deploy: supabase functions deploy send-push
// Requires FCM_SERVER_KEY secret: supabase secrets set FCM_SERVER_KEY=<key>

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  try {
    const { user_id, title, body } = await req.json();

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Get FCM token of the user
    const { data: user, error } = await supabaseAdmin
      .from("users")
      .select("fcm_token")
      .eq("id", user_id)
      .single();

    if (error || !user?.fcm_token) {
      return new Response(JSON.stringify({ error: "FCM token not found" }), {
        status: 404,
      });
    }

    const fcmKey = Deno.env.get("FCM_SERVER_KEY")!;

    const payload = {
      to: user.fcm_token,
      notification: {
        title,
        body,
        sound: "default",
      },
      data: { user_id },
    };

    const fcmRes = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        Authorization: `key=${fcmKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const fcmData = await fcmRes.json();
    return new Response(JSON.stringify(fcmData), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
    });
  }
});
