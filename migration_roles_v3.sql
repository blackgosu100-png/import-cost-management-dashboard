-- ════════════════════════════════════════════════════════════════
-- 직원 권한 시스템 (관리자/직원/조회자) — Supabase SQL Editor에서 1회 실행
-- 실행 방법: supabase.com 로그인 → 프로젝트 → SQL Editor → 전체 붙여넣기 → Run
-- (다시 실행해도 안전하게 만들어져 있음)
-- ════════════════════════════════════════════════════════════════

-- ── 1. 사용자 프로필(권한) 테이블 ─────────────────────────────
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  role text not null default 'staff' check (role in ('admin','staff','viewer')),
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;

-- 내 권한 조회 함수 (security definer — RLS 재귀 방지)
create or replace function public.my_role()
returns text language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

-- profiles 정책: 본인 것은 누구나 조회, 관리자는 전체 조회/수정
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles for select to authenticated
  using (id = auth.uid() or public.my_role() = 'admin');
drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin" on public.profiles for update to authenticated
  using (public.my_role() = 'admin');
-- insert/delete 정책 없음 → 일반 사용자는 불가 (서버(service role)만 가능)

-- ── 2. 새 계정 생성 시 프로필 자동 생성 ──────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'staff')
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── 3. 기존 계정 프로필 채우기 + 관리자 지정 ─────────────────
insert into public.profiles (id, email, role)
select id, email, 'staff' from auth.users
on conflict (id) do nothing;

update public.profiles set role = 'admin' where email = 'noahpark12@naver.com';

-- ── 4. 데이터 테이블 권한 재설정 ─────────────────────────────
-- 기존 정책 전부 제거 후: 조회=로그인한 누구나 / 입력·수정·삭제=관리자+직원만
do $$
declare r record;
begin
  for r in
    select policyname, tablename from pg_policies
    where schemaname = 'public'
      and tablename in ('products','orders','ship_groups','activity_logs')
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

do $$
declare t text;
begin
  foreach t in array array['products','orders','ship_groups','activity_logs']
  loop
    execute format('create policy %I on public.%I for select to authenticated using (true)', t || '_read', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.my_role() in (''admin'',''staff''))', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (public.my_role() in (''admin'',''staff''))', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.my_role() in (''admin'',''staff''))', t || '_delete', t);
  end loop;
end $$;

-- ── 5. 파일 저장소(이미지·정산서) 업로드 권한 재설정 ─────────
-- 조회자(viewer)는 파일 업로드/삭제 불가
do $$
declare r record;
begin
  for r in
    select policyname from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
  loop
    execute format('drop policy %I on storage.objects', r.policyname);
  end loop;
end $$;

create policy "storage_read" on storage.objects for select to authenticated
  using (bucket_id in ('product-images','invoices'));
create policy "storage_insert" on storage.objects for insert to authenticated
  with check (bucket_id in ('product-images','invoices') and public.my_role() in ('admin','staff'));
create policy "storage_update" on storage.objects for update to authenticated
  using (bucket_id in ('product-images','invoices') and public.my_role() in ('admin','staff'));
create policy "storage_delete" on storage.objects for delete to authenticated
  using (bucket_id in ('product-images','invoices') and public.my_role() in ('admin','staff'));

-- 확인용: 실행 후 아래 결과에 본인 이메일이 admin으로 나오면 성공
select email, role from public.profiles order by created_at;
