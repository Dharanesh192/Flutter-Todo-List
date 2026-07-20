// supabase/functions/send-deadline-push/index.ts
// Job: Runs on schedule (cron). Checks tasks at 3 checkpoints:
// 7 days, 3 days, 1 day before deadline. Sends push if not already notified.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import webpush from 'https://esm.sh/web-push@3.6.7';

const VAPID_PUBLIC_KEY = Deno.env.get('VAPID_PUBLIC_KEY')!;
const VAPID_PRIVATE_KEY = Deno.env.get('VAPID_PRIVATE_KEY')!;

webpush.setVapidDetails(
  'mailto:you@example.com', // change to your email
  VAPID_PUBLIC_KEY,
  VAPID_PRIVATE_KEY
);

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, // service role — full DB access, needed for cron jobs
);

// Each checkpoint: how many hours before deadline, the flag column, and label
const CHECKPOINTS = [
  { hoursBefore: 168, column: 'notified_7d', label: '7 days' }, // 7 * 24
  { hoursBefore: 72,  column: 'notified_3d', label: '3 days' }, // 3 * 24
  { hoursBefore: 24,  column: 'notified_1d', label: '1 day' },
];

Deno.serve(async () => {
  const now = new Date();
  let totalSent = 0;

  for (const checkpoint of CHECKPOINTS) {
    // Define the window: deadline falls between (hoursBefore) and (hoursBefore - 1) from now
    // Example for 24h checkpoint: catches tasks due between 23h and 24h from now
    const windowStart = new Date(now.getTime() + (checkpoint.hoursBefore - 1) * 60 * 60 * 1000);
    const windowEnd = new Date(now.getTime() + checkpoint.hoursBefore * 60 * 60 * 1000);

    // 1. Find tasks matching this checkpoint's window
    const { data: tasks, error } = await supabase
      .from('focus_hub')
      .select('Task_id, Task_name, User_id, Deadline')
      .eq('is_complete', false)
      .eq(checkpoint.column, false)
      .gte('Deadline', windowStart.toISOString())
      .lt('Deadline', windowEnd.toISOString());

    if (error) {
      console.error(`Error fetching tasks for ${checkpoint.label}:`, error);
      continue;
    }

    if (!tasks || tasks.length === 0) continue;

    // 2. For each matching task, send push to that user
    for (const task of tasks) {
      const { data: subscriptions } = await supabase
        .from('push_subscriptions')
        .select('*')
        .eq('user_id', task.User_id);

      if (!subscriptions || subscriptions.length === 0) continue;

      const payload = JSON.stringify({
        title: 'Focus Hub',
        body: `"${task.Task_name}" is due in ${checkpoint.label}`,
        url: '/',
      });

      // A user might have multiple devices subscribed — send to all
      for (const sub of subscriptions) {
        try {
          await webpush.sendNotification(
            {
              endpoint: sub.endpoint,
              keys: { p256dh: sub.p256dh, auth: sub.auth_key },
            },
            payload
          );
          totalSent++;
        } catch (pushErr) {
          console.error('Push failed for subscription:', sub.id, pushErr);
          // If subscription is expired/invalid, remove it from DB
          if (pushErr.statusCode === 410) {
            await supabase.from('push_subscriptions').delete().eq('id', sub.id);
          }
        }
      }

      // 3. Mark this checkpoint as notified so it doesn't repeat
      await supabase
        .from('focus_hub')
        .update({ [checkpoint.column]: true })
        .eq('Task_id', task.Task_id);
    }
  }

  return new Response(JSON.stringify({ success: true, notificationsSent: totalSent }), {
    headers: { 'Content-Type': 'application/json' },
  });
});