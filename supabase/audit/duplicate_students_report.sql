-- Read-only duplicate candidate report. Safe to run before the identity migration.
-- Includes name + birth-date pairs (the universal unique-index key) and normalized
-- phone matches for manual review. It never changes data.
WITH normalized AS (
  SELECT
    s.id AS student_id,
    s.service_id,
    s.name,
    s.birth_date,
    NULLIF(
      btrim(lower(regexp_replace(
        regexp_replace(translate(btrim(coalesce(s.name, '')), 'أإآىة', 'ااايه'),
          '[ً-ٰٟـ]', '', 'g'),
        '[[:space:]]+', ' ', 'g'
      ))),
      ''
    ) AS normalized_name,
    CASE
      WHEN digits = '' THEN NULL
      WHEN digits ~ '^0020[0-9]{10}$' THEN '0' || substring(digits FROM 5)
      WHEN digits ~ '^20[0-9]{10}$' THEN '0' || substring(digits FROM 3)
      WHEN digits ~ '^[1-9][0-9]{8}$' THEN '0' || digits
      WHEN digits ~ '^[0-9]{10}$' THEN '0' || digits
      ELSE digits
    END AS normalized_phone
  FROM (
    SELECT s.*,
      regexp_replace(
        translate(coalesce(s.phone, ''),
          '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹',
          '01234567890123456789'),
        '[^0-9]', '', 'g'
      ) AS digits
    FROM public.students AS s
  ) AS s
),
pairs AS (
  SELECT
    a.student_id AS student_id_a,
    b.student_id AS student_id_b,
    a.name AS name_a,
    b.name AS name_b,
    a.service_id AS service_id_a,
    b.service_id AS service_id_b,
    a.birth_date,
    (a.normalized_name = b.normalized_name
      AND a.birth_date = b.birth_date
      AND a.birth_date IS NOT NULL) AS same_normalized_name_and_birth_date,
    (a.normalized_phone = b.normalized_phone
      AND a.normalized_phone IS NOT NULL) AS same_normalized_phone
  FROM normalized AS a
  JOIN normalized AS b ON a.student_id < b.student_id
  WHERE (
    a.normalized_name = b.normalized_name
    AND a.birth_date = b.birth_date
    AND a.birth_date IS NOT NULL
  ) OR (
    a.normalized_phone = b.normalized_phone
    AND a.normalized_phone IS NOT NULL
  )
)
SELECT *
FROM pairs
ORDER BY same_normalized_name_and_birth_date DESC, name_a, student_id_a, student_id_b;
