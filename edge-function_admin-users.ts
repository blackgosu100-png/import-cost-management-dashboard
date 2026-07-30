// ════════════════════════════════════════════════════════════════
// 직원 계정 관리 Edge Function — Supabase 대시보드에서 1회 배포
// 배포 방법: supabase.com → 프로젝트 → Edge Functions → Deploy a new function
//   → "Via Editor" 선택 → 함수 이름: admin-users → 이 파일 내용 전체 붙여넣기 → Deploy
// 하는 일: 관리자(admin) 권한 확인 후 계정 생성/권한 변경/비밀번호 재설정/삭제
// ════════════════════════════════════════════════════════════════
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...cors, "Content-Type": "application/json" },
    });

  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // 호출한 사람이 관리자인지 확인
    const token = (req.headers.get("Authorization") || "").replace("Bearer ", "");
    const { data: { user }, error: uErr } = await admin.auth.getUser(token);
    if (uErr || !user) return json({ error: "로그인이 필요합니다" }, 401);
    const { data: me } = await admin.from("profiles").select("role").eq("id", user.id).single();
    if (!me || me.role !== "admin") return json({ error: "관리자만 사용할 수 있습니다" }, 403);

    const body = await req.json();

    if (body.action === "list") {
      const { data: profiles, error } = await admin.from("profiles").select("*").order("created_at");
      if (error) return json({ error: error.message }, 400);
      const { data: page } = await admin.auth.admin.listUsers({ page: 1, perPage: 200 });
      const lastSeen = new Map((page?.users || []).map((u) => [u.id, u.last_sign_in_at]));
      return json({
        users: (profiles || []).map((p) => ({ ...p, last_sign_in_at: lastSeen.get(p.id) || null })),
      });
    }

    if (body.action === "create") {
      const { email, password, name, role } = body;
      if (!email || !password || password.length < 6) {
        return json({ error: "이메일과 6자 이상 비밀번호가 필요합니다" }, 400);
      }
      const validRole = ["admin", "staff", "viewer"].includes(role) ? role : "staff";
      const { data: created, error } = await admin.auth.admin.createUser({
        email, password, email_confirm: true,
      });
      if (error) return json({ error: error.message }, 400);
      await admin.from("profiles").upsert({
        id: created.user.id, email, name: name || null, role: validRole,
      });
      return json({ ok: true });
    }

    if (body.action === "setRole") {
      const { id, role } = body;
      if (!["admin", "staff", "viewer"].includes(role)) return json({ error: "잘못된 권한" }, 400);
      if (id === user.id && role !== "admin") {
        return json({ error: "자기 자신의 관리자 권한은 해제할 수 없습니다" }, 400);
      }
      const { error } = await admin.from("profiles").update({ role }).eq("id", id);
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    if (body.action === "resetPassword") {
      const { id, password } = body;
      if (!password || password.length < 6) return json({ error: "6자 이상 비밀번호가 필요합니다" }, 400);
      const { error } = await admin.auth.admin.updateUserById(id, { password });
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    if (body.action === "delete") {
      if (body.id === user.id) return json({ error: "자기 자신은 삭제할 수 없습니다" }, 400);
      const { error } = await admin.auth.admin.deleteUser(body.id);
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    return json({ error: "알 수 없는 요청" }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
