-- this file was manually created
INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Sasi', 'sasi' ,'sasi@gmail.com','527ed5e5-2618-47c7-a7a7-950f6cb3535b'),
  ('sasi thv', 'thv','sasithv@sk.com' ,'dfb9195b-ba2b-48ac-8c10-30cbe9f4fc1b'),
  ('Londo Mollari','londo' ,'lmollari@centari.com' ,'MOCK');
  

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'sasi' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )