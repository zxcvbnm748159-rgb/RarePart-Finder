-- รันใน Supabase > SQL Editor (รันซ้ำได้)
alter table products add column if not exists seller_id uuid references auth.users(id) default auth.uid();

create table if not exists orders (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id),
  items jsonb not null,
  total numeric not null check (total >= 0),
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

alter table products enable row level security;
alter table orders   enable row level security;

drop policy if exists "products_read"   on products;
drop policy if exists "products_insert" on products;
drop policy if exists "products_update" on products;
drop policy if exists "products_delete" on products;
create policy "products_read"   on products for select using (true);
create policy "products_insert" on products for insert to authenticated with check (seller_id = auth.uid());
create policy "products_update" on products for update to authenticated using (seller_id = auth.uid());
create policy "products_delete" on products for delete to authenticated using (seller_id = auth.uid());

drop policy if exists "orders_read"   on orders;
drop policy if exists "orders_insert" on orders;
create policy "orders_read"   on orders for select to authenticated using (user_id = auth.uid());
create policy "orders_insert" on orders for insert to authenticated with check (user_id = auth.uid());

-- Storage: bucket 'product-images' (Public) ให้เฉพาะผู้ล็อกอินอัปโหลดได้
drop policy if exists "img_upload" on storage.objects;
create policy "img_upload" on storage.objects for insert to authenticated with check (bucket_id = 'product-images');
