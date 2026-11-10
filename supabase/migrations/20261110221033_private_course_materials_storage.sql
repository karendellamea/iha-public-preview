-- Private course library: only approved students for the matching course,
-- plus IHA administrators, can read objects in the private bucket.
create index if not exists iha_enrollments_reviewed_by_idx
  on public.iha_enrollments (reviewed_by);

insert into storage.buckets (id, name, public)
values ('iha-course-materials', 'iha-course-materials', false)
on conflict (id) do update set public = false;

drop policy if exists "Approved IHA students and admins can read course materials" on storage.objects;
create policy "Approved IHA students and admins can read course materials"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'iha-course-materials'
  and (
    (select private.iha_is_admin())
    or exists (
      select 1
      from public.iha_enrollments e
      where e.user_id = (select auth.uid())
        and e.payment_status = 'approved'
        and e.course_slug = (storage.foldername(name))[1]
    )
  )
);
