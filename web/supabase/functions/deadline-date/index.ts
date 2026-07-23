// supabase/functions/send-deadline-push/index.ts

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ONESIGNAL_APP_ID = 'e4b9478a-a859-43b1-be2e-f029b38e9865';
const ONESIGNAL_REST_API_KEY = Deno.env.get('onesignal_rest_api')!;

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const CHECKPOINTS = [
  { daysBefore: 7, column: 'notified_7d', label: '7 days' },
  { daysBefore: 3,  column: 'notified_3d', label: '3 days' },
  { daysBefore: 1,  column: 'notified_1d', label: '1 day' },
];

async function sendOneSignalPush(userId: string, title: string, body: string) {
  const response = await fetch('https://onesignal.com/api/v1/notifications', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
    },
    body: JSON.stringify({
      app_id: ONESIGNAL_APP_ID,
      include_aliases: { external_id: [userId] }, // targets the specific Focus Hub user
      target_channel: 'push',
      headings: { en: title },
      contents: { en: body },
    }),
  });
  return response.json();
}

function getDateStringDaysFromNow(daysFromNow: number): string {
  const date = new Date();
  date.setDate(date.getDate() + daysFromNow);
  return date.toISOString().split('T')[0]; // e.g. "2026-07-26"
}

Deno.serve(async () => {
  const now = new Date();
  let totalSent = 0;

  for (const checkpoint of CHECKPOINTS) {
    
    const targetDateString = getDateStringDaysFromNow(checkpoint.daysBefore);
    const windowStart = `${targetDateString}T00:00:00`;
    const windowEnd = `${targetDateString}T23:59:59`;

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

    if (error || !tasks || tasks.length === 0) continue;

    for (const task of tasks) {
      try {
        await sendOneSignalPush(
          task.User_id,
          'Focus Hub',
          `"${task.Task_name}" is due in ${checkpoint.label}`
        );
        totalSent++;
      } catch (err) {
        console.error('OneSignal push failed:', err);
      }

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