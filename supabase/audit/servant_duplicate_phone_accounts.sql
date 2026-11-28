-- Read-only audit: different auth users sharing the same normalized phone.
-- This reports possible duplicate accounts; it never merges or blocks them.
WITH normalized AS (
  SELECT
    p.auth_user_id,
    p.full_name,
    private.normalize_servant_phone(p.phone) AS normalized_phone,
    COALESCE(
      array_agg(DISTINCT s.name ORDER BY s.name) FILTER (WHERE s.id IS NOT NULL),
      ARRAY[]::text[]
    ) AS service_names
  FROM public.servant_persons AS p
  LEFT JOIN public.servant_profiles AS sp ON sp.auth_user_id = p.auth_user_id
  LEFT JOIN public.services AS s ON s.id = sp.service_id
  WHERE p.phone IS NOT NULL
  GROUP BY p.auth_user_id, p.full_name, private.normalize_servant_phone(p.phone)
)
SELECT
  normalized_phone,
  array_agg(auth_user_id ORDER BY auth_user_id) AS auth_user_ids,
  array_agg(full_name ORDER BY full_name) AS names,
  jsonb_agg(jsonb_build_object(
    'auth_user_id', auth_user_id,
    'full_name', full_name,
    'service_names', service_names
  ) ORDER BY auth_user_id) AS people
FROM normalized
WHERE normalized_phone IS NOT NULL
GROUP BY normalized_phone
HAVING count(DISTINCT auth_user_id) > 1
ORDER BY normalized_phone;
