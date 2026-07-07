-- 제품 DB 확장 (상품db2.xlsx 전체 컬럼 반영) — Supabase SQL Editor에서 1회 실행
-- 실행 방법: supabase.com 로그인 → 프로젝트 → SQL Editor → 붙여넣기 → Run
-- (이미 실행했더라도 다시 실행 가능 — IF NOT EXISTS라 안전)
alter table products
  add column if not exists brand text,           -- 브랜드
  add column if not exists barcode text,         -- 바코드
  add column if not exists box_size text,        -- 박스사이즈
  add column if not exists dim_sum numeric,      -- 3면합(cm)
  add column if not exists freight_type text,    -- 운임타입
  add column if not exists name_en text,         -- 영문
  add column if not exists parcel_fee numeric,   -- (인터지스)택배+작업
  add column if not exists parcel_fee2 numeric,  -- (심비)택배비
  add column if not exists cost_krw numeric,     -- 원가(원화)
  add column if not exists sale_price numeric,   -- 사이트판매가
  add column if not exists last_buy numeric,     -- 마지막구매가
  add column if not exists cur_buy numeric,      -- 현재구매가
  add column if not exists buy_krw numeric,      -- 구매가 원화
  add column if not exists ship_cost numeric,    -- 선적비용
  add column if not exists final_cost numeric,   -- 최종원가
  add column if not exists list_price numeric,   -- 정상가
  add column if not exists guide text,           -- 제품 전달 가이드(3PL)
  add column if not exists sort_order integer;   -- 엑셀 원본 행 순서 (제품 DB 정렬 기준)
