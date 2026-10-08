-- รันใน Supabase > SQL Editor (หลังรัน schema.sql แล้ว รันซ้ำได้)
alter table products add column if not exists stock int not null default 1;
alter table products drop constraint if exists stock_nonneg;
alter table products add constraint stock_nonneg check (stock >= 0);

-- สั่งซื้อผ่านฟังก์ชันนี้เท่านั้น: คิดราคาและตัดสต็อกฝั่งเซิร์ฟเวอร์ ป้องกันการแก้ราคา/ซื้อเกินสต็อก
create or replace function place_order(p_items jsonb) returns bigint
language plpgsql security definer set search_path = public as $$
declare it jsonb; r record; q int; v_total numeric := 0; v_items jsonb := '[]'; v_id bigint;
begin
  if auth.uid() is null then raise exception 'กรุณาเข้าสู่ระบบ'; end if;
  for it in select value from jsonb_array_elements(p_items) loop
    q := greatest(coalesce((it->>'quantity')::int, 1), 1);
    select id, name, price, stock into r from products where id = (it->>'id')::bigint for update;
    if not found then raise exception 'ไม่พบสินค้าในระบบ'; end if;
    if r.stock < q then raise exception 'สินค้า "%" เหลือไม่พอ (เหลือ % ชิ้น)', r.name, r.stock; end if;
    update products set stock = stock - q where id = r.id;
    v_total := v_total + r.price * q;
    v_items := v_items || jsonb_build_object('id', r.id, 'name', r.name, 'price', r.price, 'quantity', q);
  end loop;
  insert into orders(user_id, items, total) values (auth.uid(), v_items, v_total) returning id into v_id;
  return v_id;
end $$;
revoke all on function place_order(jsonb) from public;
grant execute on function place_order(jsonb) to authenticated;

drop policy if exists "orders_insert" on orders;  -- ห้าม insert ตรง ต้องผ่าน place_order
drop policy if exists "orders_seller_read" on orders;
create policy "orders_seller_read" on orders for select to authenticated using (
  exists (select 1 from jsonb_array_elements(items) i join products p on p.id = (i->>'id')::bigint
          where p.seller_id = auth.uid()));
